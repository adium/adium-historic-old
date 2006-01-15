//
//  SUUpdater.m
//  Sparkle
//
//  Created by Andy Matuschak on 1/4/06.
//  Copyright 2006 Andy Matuschak. All rights reserved.
//

#import "SUUpdater.h"
#import "RSS.h"
#import <stdio.h>

NSString *SUCheckAtStartupKey = @"SUCheckAtStartup";
NSString *SUFeedURLKey = @"SUFeedURL";
NSString *SUShowReleaseNotesKey = @"SUShowReleaseNotes";

NSString *SUHostAppName()
{
	return [[NSFileManager defaultManager] displayNameAtPath:[[NSBundle mainBundle] bundlePath]];
}

@implementation SUUpdater

- (void)scheduleCheckWithInterval:(NSTimeInterval)interval
{
	if (checkTimer)
		[checkTimer release];
	
	checkInterval = interval;
	if (interval)
		checkTimer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(checkForUpdatesAndNotify:) userInfo:[NSNumber numberWithBool:NO] repeats:YES];
}

- (BOOL)promptUserForStartupPreference
{
	// The SHOULD_CHECK_FOR_UPDATES_ON_STARTUP_BODY should have a %@ where the application name will be inserted.
	// If you don't want that, just delete it and then delete the last argument to this NSRunAlertPanel call.
/*	NSString *appName = SUHostAppName();
	return (NSRunAlertPanel(NSLocalizedStringFromTable(@"Check for updates on startup?", @"Sparkle", nil), 
							NSLocalizedStringFromTable(@"Would you like %@ to check for updates on startup? If not, you can initiate the check manually from the application menu.", @"Sparkle", nil),
							NSLocalizedString(@"Yes", nil), NSLocalizedString(@"No", nil), nil, appName)) == NSAlertDefaultReturn ? YES : NO;
	// ^ most convoluted return line evar*/
	
	//we can stick this pref in the startup wizard, if we need it at all.
	return YES;
}

- (void)awakeFromNib
{
//#warning TODO: Only check on startup once every n days (to ease server loads).
	NSNumber *shouldCheckAtStartup = [[NSUserDefaults standardUserDefaults] objectForKey:SUCheckAtStartupKey];
	if (!shouldCheckAtStartup) // hasn't been set yet
	{
		// Let's see if there's a key in Info.plist for a default, though.
		NSNumber *infoStartupValue = [[[NSBundle mainBundle] infoDictionary] objectForKey:SUCheckAtStartupKey];
		if (infoStartupValue)
		{
			shouldCheckAtStartup = infoStartupValue;
		}
		else
		{
			// Ask the user
			shouldCheckAtStartup = [NSNumber numberWithBool:[self promptUserForStartupPreference]];
		}
		[[NSUserDefaults standardUserDefaults] setObject:shouldCheckAtStartup forKey:SUCheckAtStartupKey];
	}
	
	if ([shouldCheckAtStartup boolValue])
		[self checkForUpdatesAndNotify:NO];
}

- (void)dealloc
{
	[downloadPath release];
	if (checkTimer)
		[checkTimer invalidate];
	[super dealloc];
}

// If the notify flag is YES, Sparkle will say when it can't reach the server and when there's no new update.
// This is generally useful for a menu item--when the check is explicitly invoked.
- (void)checkForUpdatesAndNotify:(BOOL)verbosity
{
	// Make sure one isn't already going...
	if ([statusWindow isVisible])
	{
		[statusWindow makeKeyAndOrderFront:self];
		return;
	}
	
	if ([NSApp modalWindow])
	{
		return;
	}
	
	verbose = verbosity;
	// This method name is a little misleading; we're going to split the actual task at hand off into another thread to avoid blocking.
	[NSThread detachNewThreadSelector:@selector(fetchFeed) toTarget:self withObject:nil];
}

- (IBAction)checkForUpdates:sender
{
	// If we're coming from IB, then we want to be more verbose.
	[self checkForUpdatesAndNotify:YES];
}

- (NSString *)newestRemoteVersionStringInFeed:(RSS *)feed
{
	NSDictionary *enclosure = [[feed newestItem] objectForKey:@"enclosure"];
	
	// Finding the new version number from the RSS feed is a little bit hacky. There are two ways:
	// 1. A "version" attribute on the enclosure tag, which I made up just for this purpose. It's not part of the RSS2 spec.
	// 2. If there isn't a version attribute, Sparkle will parse the path in the enclosure, expecting
	//    that it will look like this: http://something.com/YourApp_0.5.zip It'll read whatever's between the last
	//    underscore and the last period as the version number. So name your packages like this: APPNAME_VERSION.extension.
	//    The big caveat with this is that you can't have underscores in your version strings, as that'll confused Sparkle.
	//    Feel free to change the separator string to a hyphen or something more suited to your needs if you like.
	NSString *newVersion = [enclosure objectForKey:@"version"];
	if (!newVersion) // no version attribute
	{
		// Separate the url by underscores and take the last component, as that'll be closest to the end.
		NSString *versionAndExtension = [[[enclosure objectForKey:@"url"] componentsSeparatedByString:@"_"] lastObject];
		// Now we remove the extension. Hopefully, this will be the version.
		newVersion = [versionAndExtension stringByDeletingPathExtension];
	}
	if (!newVersion) // don't really know what to do!
	{
		NSRunAlertPanel(NSLocalizedStringFromTable(@"Update Error!", @"Sparkle", nil), NSLocalizedStringFromTable(@"Can't extract a version string from the appcast feed. The filenames should look like YourApp_1.5.tgz, where 1.5 is the version number. The underscore is crucial.\n\nIf you're a user reading this, try again later and the developer may have fixed it.", @"Sparkle", nil), NSLocalizedString(@"OK", nil), nil, nil);
		//[NSException raise:@"RSSParseFailed" format:@"Couldn't read a version string from the appcast feed at %@", SUFeedURL];
	}
	
	return newVersion;
}

- (NSString *)currentVersionString
{
	return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
}

- (void)fetchFeed
{
//#warning TODO: Handle caching / HTTP headers to see if the request is really necessary.
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	RSS *feed;
	BOOL shouldContinue = YES;
	NS_DURING
		NSString *path = [[[NSBundle mainBundle] infoDictionary] objectForKey:SUFeedURLKey];
		if (!path) { [NSException raise:@"SUNoFeedURL" format:@"No feed URL is specified in the Info.plist!"]; }
		feed = [[RSS alloc] initWithURL:[NSURL URLWithString:path] normalize:YES];
	NS_HANDLER
		shouldContinue = NO;
		if ([[localException name] isEqualToString:@"RSSDownloadFailed"] || [[localException name] isEqualToString:@"RSSNoData"])
		{
			// We only run a panel on these if the notify flag is YES. 
			if (!verbose)
				NS_VOIDRETURN;
		}
		// We have to make the main thread do this instead of doing it ourselves because secondary
		// threads can't do GUI stuff (like popping alert dialogs).
		[self performSelectorOnMainThread:@selector(feedFetchDidFailWithException:) withObject:localException waitUntilDone:NO];
	NS_ENDHANDLER
	
	if (shouldContinue)
		[self performSelectorOnMainThread:@selector(didFetchFeed:) withObject:feed waitUntilDone:NO];
	[pool release];
}

- (void)feedFetchDidFailWithException:(NSException *)exception
{
	NSRunAlertPanel(NSLocalizedStringFromTable(@"Update Error!", @"Sparkle", nil), NSLocalizedStringFromTable(@"An error occurred while fetching or parsing the appcast:\n\n%@", @"Sparkle", nil), NSLocalizedString(@"OK", nil), nil, nil, [exception reason]);
}

- (void)setStatusText:(NSString *)statusText
{
	[statusField setAttributedStringValue:[[[NSAttributedString alloc] initWithString:statusText attributes:[NSDictionary dictionaryWithObject:[NSFont boldSystemFontOfSize:[NSFont systemFontSizeForControlSize:NSRegularControlSize]] forKey:NSFontAttributeName]] autorelease]];
}

- (void)setActionButtonTitle:(NSString *)title
{
	[actionButton setTitle:title];
	[actionButton sizeToFit];
	// Except we're going to add 15 px for padding.
	[actionButton setFrameSize:NSMakeSize([actionButton frame].size.width + 15, [actionButton frame].size.height)];
	// Now we have to move it over so that it's always 15px from the side of the window.
	[actionButton setFrameOrigin:NSMakePoint([[statusWindow contentView] bounds].size.width - 15 - [actionButton frame].size.width, [actionButton frame].origin.y)];
}

- (void)createStatusWindow
{
	// Yeah, it's really hacky that we're programmatically making this window,
	// but this project is made so that you can just drop it in any project, and
	// adding .nibs would complicate things. You'd better appreciate it.
	
	// Numeric literals abound! Run for the hills! But they're mostly taken from the HIG dialog reference layout.
	
	statusWindow = [[NSPanel alloc] initWithContentRect:NSMakeRect(0, 0, 384, 106) styleMask:NSTitledWindowMask | NSMiniaturizableWindowMask backing:NSBackingStoreBuffered defer:NO];
	[statusWindow setHidesOnDeactivate:NO];
	[statusWindow center];
	[statusWindow setTitle:[NSString stringWithFormat:NSLocalizedStringFromTable(@"Updating %@", @"Sparkle", nil), SUHostAppName()]];
	
	id contentView = [statusWindow contentView];
	NSSize windowSize = [contentView bounds].size;
	
	// Place the app icon.
	NSImageView *appIconView = [[[NSImageView alloc] initWithFrame:NSMakeRect(24, windowSize.height - 15 - 64, 64, 64)] autorelease];
	[appIconView setImageFrameStyle:NSImageFrameNone];
	[appIconView setImage:[NSApp applicationIconImage]];
	[contentView addSubview:appIconView];
	
	// Place the status field.
	statusField = [[[NSTextField alloc] initWithFrame:NSMakeRect(24 + 64 + 15, windowSize.height - 15 - 17, 260, 17)] autorelease];
	[self setStatusText:NSLocalizedStringFromTable(@"Download New Version", @"Sparkle", nil)];
	[statusField setBezeled:NO];
	[statusField setEditable:NO];
	[statusField setDrawsBackground:NO];
	[contentView addSubview:statusField];
	
	// Place the download completion field.
	downloadProgressField = [[[NSTextField alloc] initWithFrame:NSMakeRect(24 + 64 + 15, 22, 150, 17)] autorelease];
	[downloadProgressField setBezeled:NO];
	[downloadProgressField setEditable:NO];
	[downloadProgressField setDrawsBackground:NO];
	[contentView addSubview:downloadProgressField];
	
	// Place the progress bar.
	progressBar = [[[NSProgressIndicator alloc] initWithFrame:NSMakeRect(24 + 64 + 16, windowSize.height - 15 - 17 - 8 - 20, 260, 20)] autorelease];
	[progressBar setIndeterminate:YES];
	[progressBar startAnimation:self];
	[progressBar setControlSize:NSRegularControlSize];
	[contentView addSubview:progressBar];
	
	// Place the action button.
	actionButton = [[[NSButton alloc] initWithFrame:NSMakeRect(windowSize.width - 15 - 82, 12, 82, 32)] autorelease];
	[actionButton setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSRegularControlSize]]];
	[actionButton setBezelStyle:NSRoundedBezelStyle];
	[self setActionButtonTitle:NSLocalizedString(@"Cancel", nil)];
	[actionButton setTarget:self];
	[actionButton setAction:@selector(cancelDownload:)];
	[contentView addSubview:actionButton];
}

- (void)showReleaseNotesOfFeed:(RSS *)feed
{
	NSPanel *notesPanel = [[NSPanel alloc] initWithContentRect:NSMakeRect(0, 0, 478, 283) styleMask:NSTitledWindowMask | NSMiniaturizableWindowMask backing:NSBackingStoreBuffered defer:NO];
	[notesPanel setTitle:NSLocalizedStringFromTable(@"Release Notes", @"Sparkle", nil)];
	
	id contentView = [notesPanel contentView];
	NSSize windowSize = [contentView bounds].size;
	
	// Place the application icon
	NSImageView *appIconView = [[[NSImageView alloc] initWithFrame:NSMakeRect(20, windowSize.height - 15 - 64, 64, 64)] autorelease];
	[appIconView setImageFrameStyle:NSImageFrameNone];
	[appIconView setImage:[NSApp applicationIconImage]];
	[contentView addSubview:appIconView];
	
	// Place the release notes title text
	NSTextField *notesTitle = [[[NSTextField alloc] initWithFrame:NSMakeRect(20 + 64 + 15, windowSize.height - 15 - 17, 360, 17)] autorelease];
	[notesTitle setAttributedStringValue:[[[NSAttributedString alloc] initWithString:NSLocalizedStringFromTable(@"Release Notes", @"Sparkle", nil) attributes:[NSDictionary dictionaryWithObject:[NSFont boldSystemFontOfSize:[NSFont systemFontSizeForControlSize:NSRegularControlSize]] forKey:NSFontAttributeName]] autorelease]]; // A very long line to make the words "Release Notes" bold.
	[notesTitle setBezeled:NO];
	[notesTitle setEditable:NO];
	[notesTitle setDrawsBackground:NO];
	[contentView addSubview:notesTitle];
	
	// Place the release notes reader
	NSScrollView *scrollView = [[[NSScrollView alloc] initWithFrame:NSMakeRect(20 + 64 + 16, 54, 358, 184)] autorelease];
	[scrollView setHasVerticalScroller:YES];
	[scrollView setBorderType:NSBezelBorder];
	[contentView addSubview:scrollView];
	
	NSTextView *textView = [[NSTextView alloc] initWithFrame:[[scrollView contentView] bounds]];
	NSAttributedString *attributedString = [[[NSMutableAttributedString alloc] initWithHTML:[NSData dataWithBytes:[[[feed newestItem] objectForKey:@"description"] cString] length:[(NSString *)[[feed newestItem] objectForKey:@"description"] length]] options:nil documentAttributes:nil] autorelease];
	[[textView textStorage] setAttributedString:attributedString];
	[textView setEditable:NO];
	[textView setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]]];
	[scrollView setDocumentView:textView];
	
	// Place the OK button.
	NSButton *okButton = [[[NSButton alloc] initWithFrame:NSMakeRect(windowSize.width - 14 - 82, 12, 82, 32)] autorelease];
	[okButton setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSRegularControlSize]]];
	[okButton setTitle:NSLocalizedString(@"OK", nil)];
	[okButton setKeyEquivalent:@"\r"];
	[okButton setBezelStyle:NSRoundedBezelStyle];
	[okButton setTarget:self];
	[okButton setAction:@selector(stopReleaseNotes:)];
	[contentView addSubview:okButton];
	
	[NSApp runModalForWindow:notesPanel];
}

- (IBAction)stopReleaseNotes:sender
{
	[NSApp stopModal];
	[[sender window] orderOut:self];
	[[sender window] release];
}

- (BOOL)shouldPerformUpdateWithFeed:(RSS *)feed
{
	// This method is called when there's an update to determine if the user wants it.
	NSString *appName = SUHostAppName();
	id title = [NSString stringWithFormat:NSLocalizedStringFromTable(@"A new version of %@ is available!", @"Sparkle", nil), appName];
	
	id body = [NSString stringWithFormat:NSLocalizedStringFromTable(@"%@ %@ is now available (you have %@). Would you like to download it now?", @"Sparkle", nil), appName, [self newestRemoteVersionStringInFeed:feed], [self currentVersionString]];
	
	id downloadUpdate = NSLocalizedStringFromTable(@"Download New Version", @"Sparkle", nil);
	id notNow = NSLocalizedStringFromTable(@"Cancel", @"Sparkle", nil);
	id viewReleaseNotes = NSLocalizedStringFromTable(@"Review Changes", @"Sparkle", nil);
	
	int result;
	do
	{
		// Get the release notes option from Info.plist.
		NSNumber *showNotesObj = [[[NSBundle mainBundle] infoDictionary] objectForKey:SUShowReleaseNotesKey];
		BOOL showNotes;
		if (!showNotesObj)
			showNotes = YES;
		else
			showNotes = [showNotesObj boolValue];
		
		result = NSRunAlertPanel(title, body, downloadUpdate, notNow, showNotes ? viewReleaseNotes : nil);
		if (result == NSAlertOtherReturn)
		{
			[self showReleaseNotesOfFeed:feed];
		}
	}
	while (result == NSAlertOtherReturn);
	return result;
}

- (void)didFetchFeed:(RSS *)feed
{
	NSString *newestVersionString = [self newestRemoteVersionStringInFeed:feed];
	if (!newestVersionString) { return; }
	if ([[self currentVersionString] isEqualToString:newestVersionString])
	{
		// We only notify on no new version when the notify flag is on.
		if (verbose)
		{
			NSRunAlertPanel(NSLocalizedStringFromTable(@"You're up to date!", @"Sparkle", nil), NSLocalizedStringFromTable(@"%@ %@ is currently the newest version available.", @"Sparkle", nil), NSLocalizedString(@"OK", nil), nil, nil, SUHostAppName(), [self currentVersionString]);
		}
	}
	else
	{
		// There's a new version!
		if (checkTimer)
		{
			[checkTimer invalidate];
			checkTimer = nil;
		}
		
		if (![self shouldPerformUpdateWithFeed:feed])
		{
			if (checkInterval)
				[self scheduleCheckWithInterval:checkInterval];
			return;
		}
		[self createStatusWindow];
		[statusWindow makeKeyAndOrderFront:self];
		NSString *urlString = [[[feed newestItem] objectForKey:@"enclosure"] objectForKey:@"url"];
		downloader = [[NSURLDownload alloc] initWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]] delegate:self];
	}
	[feed release];
}

- (void)download:(NSURLDownload *)download didReceiveResponse:(NSURLResponse *)response
{
	[progressBar setIndeterminate:NO];
	[progressBar startAnimation:self];
	[progressBar setMaxValue:[response expectedContentLength]];
	[progressBar setDoubleValue:0];
}

- (void)download:(NSURLDownload *)download decideDestinationWithSuggestedFilename:(NSString *)name
{
	// If name ends in .txt, the server probably has a stupid MIME configuration. We'll give
	// the developer the benefit of the doubt and chop that off.
	if ([[name pathExtension] isEqualToString:@"txt"])
		name = [name stringByDeletingPathExtension];
	
	// We create a temporary directory in /tmp and stick the file there.
	NSString *tempDir = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]];
	BOOL success = [[NSFileManager defaultManager] createDirectoryAtPath:tempDir attributes:nil];
	if (!success)
	{
		[NSException raise:@"SUFailTmpWrite" format:@"Couldn't create temporary directory in /tmp"];
		[download cancel];
		[download release];
	}
	downloadPath = [[tempDir stringByAppendingPathComponent:name] retain];
	[download setDestination:downloadPath allowOverwrite:YES];
}

- (void)download:(NSURLDownload *)download didReceiveDataOfLength:(unsigned)length
{
	[progressBar setDoubleValue:[progressBar doubleValue] + length];
	[downloadProgressField setStringValue:[NSString stringWithFormat:NSLocalizedStringFromTable(@"%.0lfk of %.0lfk", @"Sparkle", nil), [progressBar doubleValue] / 1024.0, [progressBar maxValue] / 1024.0]];
}

- (void)downloadDidFinish:(NSURLDownload *)download
{
	[download release];
	downloader = nil;
	
	// Now we have to extract the downloaded archive.
	[self setStatusText:NSLocalizedStringFromTable(@"Extracting update...", @"Sparkle", nil)];
	NSDictionary *commandDictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"tar -jxC \"$DESTINATION\"", @"tbz", @"tar -zxC \"$DESTINATION\"", @"tgz", @"tar -xC \"$DESTINATION\"", @"tar", nil];
	NSString *command = [commandDictionary objectForKey:[downloadPath pathExtension]];
	if (!command)
	{
		NSRunAlertPanel(NSLocalizedStringFromTable(@"Update Error!", @"Sparkle", nil), NSLocalizedStringFromTable(@"Can't extract archives of type %@; only %@ are supported.\n\nIf you're a user reading this, try again later and the developer may have fixed it.", @"Sparkle", nil), NSLocalizedString(@"OK", nil), nil, nil, [downloadPath pathExtension], [commandDictionary allKeys]);
		[statusWindow orderOut:self];
		[statusWindow release];
		statusWindow = nil;
		return;
		//[NSException raise:@"SUCannotHandleFile" format:@"Can't extract %@ files; I can only handle %@", [downloadPath pathExtension], [commandDictionary allKeys]];
	}
	
	// Get the file size.
	NSNumber *fs = [[[NSFileManager defaultManager] fileAttributesAtPath:downloadPath traverseLink:NO] objectForKey:NSFileSize];
	if (!fs)
	{
		NSRunAlertPanel(NSLocalizedStringFromTable(@"Update Error!", @"Sparkle", nil), NSLocalizedStringFromTable(@"Okay, where'd it go? I just downloaded the update, but it seems to have vanished! Please try again later.", @"Sparkle", nil), NSLocalizedString(@"OK", nil), nil, nil);
		[statusWindow orderOut:self];
		[statusWindow release];
		statusWindow = nil;
		return;
		//[NSException raise:@"SUCannotReadFile" format:@"Can't determine downloaded file size"];
	}
	long fileSize = [fs longValue];
	
	// Thank you, Allan Odgaard!
	// (who wrote the following extraction alg.)
	[progressBar setIndeterminate:NO];
	[progressBar setDoubleValue:0.0];
	[progressBar setMaxValue:fileSize];
	[progressBar startAnimation:self];
	
	long current = 0;
	FILE *fp, *cmdFP;
	if ((fp = fopen([downloadPath UTF8String], "r")))
	{
		setenv("DESTINATION", [[downloadPath stringByDeletingLastPathComponent] UTF8String], 1);
		if ((cmdFP = popen([command cString], "w")))
		{
			char buf[32*1024];
			long len;
			while((len = fread(buf, 1, 32 * 1024, fp)))
			{
				// It could be cancelled while this is happening...
				if (!statusWindow)
				{
					pclose(cmdFP);
					fclose(fp);
					return;
				}
				
				current += len;
				[progressBar setDoubleValue:(double)current];
				[downloadProgressField setStringValue:[NSString stringWithFormat:NSLocalizedStringFromTable(@"%.0lfk of %.0lfk", @"Sparkle", nil), current / 1024.0, fileSize / 1024.0]];
				
				NSEvent *event;
				while((event = [NSApp nextEventMatchingMask:NSAnyEventMask untilDate:nil inMode:NSDefaultRunLoopMode dequeue:YES]))
					[NSApp sendEvent:event];
				
				fwrite(buf, 1, len, cmdFP);
			}
			pclose(cmdFP);
		}
		fclose(fp);
	}
	
	[self setStatusText:NSLocalizedStringFromTable(@"Ready to install!", @"Sparkle", nil)];
	[self setActionButtonTitle:NSLocalizedStringFromTable(@"Install and Relaunch", @"Sparkle", nil)];
	[downloadProgressField setHidden:YES];
	[actionButton setAction:@selector(installAndRestart:)];
	[NSApp requestUserAttention:NSInformationalRequest];
	[actionButton setKeyEquivalent:@"\r"]; // Make the button active
}

- (void)download:(NSURLDownload *)download didFailWithError:(NSError *)error
{
	[statusWindow orderOut:self];
	[statusWindow release];
	statusWindow = nil;
	NSRunAlertPanel(NSLocalizedStringFromTable(@"Update Error!", @"Sparkle", nil), NSLocalizedStringFromTable(@"An error occurred while trying to download the file:\n\n%@", @"Sparkle", nil), NSLocalizedString(@"OK", nil), nil, nil, [error localizedDescription]);
}

- (IBAction)installAndRestart:sender
{
	[progressBar setIndeterminate:YES];
	[progressBar startAnimation:self];
	[self setStatusText:NSLocalizedStringFromTable(@"Installing update...", @"Sparkle", nil)];
	[progressBar display];
	[statusField display];
	
	// We assume that the archive will contain a file named {CFBundleName}.app
	// (where, obviously, CFBundleName comes from Info.plist)
	NSString *currentPath = [[NSBundle mainBundle] bundlePath];
	NSString *executableName = [[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"] stringByAppendingPathExtension:@"app"];
	NSString *targetPath = [[downloadPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:executableName];
	if (![[NSFileManager defaultManager] fileExistsAtPath:targetPath])
	{
		NSRunAlertPanel(NSLocalizedStringFromTable(@"Update Error!", @"Sparkle", nil), NSLocalizedStringFromTable(@"The update archive didn't contain an application with the name I was expecting (%@). Remember, the updated app's file name must be identical to the running app's name as specified in the Info.plist!\n\nIf you're a user reading this, try again later and the developer may have fixed it.", @"Sparkle", nil), NSLocalizedString(@"OK", nil), nil, nil, targetPath);
		[statusWindow orderOut:self];
		[statusWindow release];
		statusWindow = nil;
		return;
		//[NSException raise:@"SUFileNotFound" format:@"Couldn't find a new version of the app where I expected it to be (%@). The .app in the archive should have the same filename as the current executable.", targetPath];
	}
	
	// Now we delete the old one.
	int tag = 0;
	if (![[NSWorkspace sharedWorkspace] performFileOperation:NSWorkspaceRecycleOperation source:[currentPath stringByDeletingLastPathComponent] destination:@"" files:[NSArray arrayWithObject:[currentPath lastPathComponent]] tag:&tag])
	{
		NSRunAlertPanel(NSLocalizedStringFromTable(@"Update Error!", @"Sparkle", nil), NSLocalizedStringFromTable(@"Couldn't delete the current application, which has to be done before the update can be installed. Is it in a write-only location (like on the disk image?). Move it to /Applications and try again.", @"Sparkle", nil), NSLocalizedString(@"OK", nil), nil, nil);
		[statusWindow orderOut:self];
		[statusWindow release];
		statusWindow = nil;
		return;
		//[NSException raise:@"SUCouldntDeleteCurrentApp" format:@"Couldn't delete the current copy of the application. Is it read-only or something?"];
	}
	
	// And the new one is born.
	if (![[NSFileManager defaultManager] movePath:targetPath toPath:currentPath handler:NULL])
	{
		NSRunAlertPanel(NSLocalizedStringFromTable(@"Update Error!", @"Sparkle", nil), NSLocalizedStringFromTable(@"Couldn't move the update to its new home. Are you running this application from a write-only directory. Since the old application has already been deleted, it might be in the trash now, but it should be recoverable. Very sorry for the inconvenience!", @"Sparkle", nil), NSLocalizedString(@"OK", nil), nil, nil);
		[statusWindow orderOut:self];
		[statusWindow release];
		statusWindow = nil;
		return;
	}
	
	[[NSWorkspace sharedWorkspace] openFile:currentPath];
	[NSApp terminate:self];
}

- (IBAction)cancelDownload:sender
{
	if (downloader)
	{
		[downloader cancel];
		[downloader release];
	}
	[statusWindow orderOut:self];
	[statusWindow release];
	statusWindow = nil;
	
	if (checkInterval)
	{
		[self scheduleCheckWithInterval:checkInterval];
	}
}

@end

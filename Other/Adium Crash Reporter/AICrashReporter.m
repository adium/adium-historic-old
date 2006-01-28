/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "AICrashReporter.h"
#import <AIUtilities/AITextViewWithPlaceholder.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AIFileManagerAdditions.h>
#import <AIUtilities/AIApplicationAdditions.h>
#import <AIUtilities/AIAutoScrollView.h>

#define CRASH_REPORT_URL				@"http://www.visualdistortion.org/crash/post.jsp"
#define KEY_CRASH_EMAIL_ADDRESS			@"AdiumCrashReporterEmailAddress"
#define KEY_CRASH_AIM_ACCOUNT			@"AdiumCrashReporterAIMAccount"

#define CRASH_REPORT_SLAY_ATTEMPTS		100
#define CRASH_REPORT_SLAY_INTERVAL		0.1

#define CRASH_LOG_WAIT_ATTEMPTS			100
#define CRASH_LOG_WAIT_INTERVAL			0.2

#define ADIUM_UPDATE_URL			@"http://download.adiumx.com/"
#define ADIUM_UPDATE_BETA_URL		@"http://beta.adiumx.com/"

#define VERSION_PLIST_URL			@"http://www.adiumx.com/version.plist"
#define VERSION_PLIST_KEY			@"adium-version"
#define VERSION_BETA_PLIST_KEY		@"adium-beta-version"

#define UNABLE_TO_SEND				AILocalizedString(@"Unable to send crash report",nil)

@interface AICrashReporter (PRIVATE)
- (void)performVersionChecking;
@end

@implementation AICrashReporter

//
- (id)init
{
    if ((self = [super init])) {
		slayerScript = [[NSAppleScript alloc] initWithSource:@"tell application \"UserNotificationCenter\" to quit"];
	}

    return self;
} 

//
- (void)dealloc
{
	[buildUser release];
	[buildDate release];
	[buildNumber release];
	[crashLog release];
	[slayerScript release];
	[adiumPath release];

	[super dealloc];
}

//
- (void)awakeFromNib
{
    [textView_details setPlaceholderString:AILocalizedString(@"A detailed explanation of what you were doing when Adium crashed (optional)",nil)];

    [scrollView_details setAlwaysDrawFocusRingIfFocused:YES];
	
    //Search for an exception log
    if ([[NSFileManager defaultManager] fileExistsAtPath:EXCEPTIONS_PATH]) {
        [self reportCrashForLogAtPath:EXCEPTIONS_PATH];
    } else {  
        //Kill the apple crash reporter
		[NSTimer scheduledTimerWithTimeInterval:CRASH_REPORT_SLAY_INTERVAL
										 target:self
									   selector:@selector(appleCrashReportSlayer:)
									   userInfo:nil
										repeats:YES];
        
        //Wait for a valid crash log to appear
        [NSTimer scheduledTimerWithTimeInterval:CRASH_LOG_WAIT_INTERVAL
                                         target:self
                                       selector:@selector(delayedCrashLogDiscovery:)
                                       userInfo:nil
                                        repeats:YES];
    }
	
	if ([progress_sending respondsToSelector:@selector(setHidden:)]) {
		[progress_sending setHidden:YES];
	}
}

- (BOOL)application:(NSApplication *)app openFile:(NSString *)path {
	[adiumPath release];
	adiumPath = [path retain];
	return YES;
}

//Actively tries to kill Apple's "Report this crash" dialog
- (void)appleCrashReportSlayer:(NSTimer *)inTimer
{
	static int 		countdown = CRASH_REPORT_SLAY_ATTEMPTS;
	
	//Kill the notification app if it's open
	if (countdown-- == 0 || ![[slayerScript executeAndReturnError:nil] booleanValue]) {
		[inTimer invalidate];
	}
}

#pragma mark Crash log loading
//Waits for a crash log to be written
- (void)delayedCrashLogDiscovery:(NSTimer *)inTimer
{
	static int 		countdown = CRASH_LOG_WAIT_ATTEMPTS;
	
	//Kill the notification app if it's open
	if (countdown-- == 0 || [self reportCrashForLogAtPath:CRASHES_PATH]) {
		[inTimer invalidate];
	}
}

//Display the report crash window for the passed log
- (BOOL)reportCrashForLogAtPath:(NSString *)inPath
{
    NSString	*emailAddress, *aimAccount;
    NSRange		binaryRange;
    
	if ([[NSFileManager defaultManager] fileExistsAtPath:inPath]) {
		NSString	*newLog = [NSString stringWithContentsOfFile:inPath];
		if (newLog && [newLog length]) {
			//Hang onto and delete the log
			crashLog = [newLog retain];
			[[NSFileManager defaultManager] trashFileAtPath:inPath];
			
			//Strip off PPC thread state and binary descriptions.. we don't need to send all that
			binaryRange = [crashLog rangeOfString:@"PPC Thread State:"];
			if (binaryRange.location != NSNotFound) {
				NSString	*shortLog = [crashLog substringToIndex:binaryRange.location];
				[crashLog release]; crashLog = [shortLog retain];
			}
			
			//Restore the user's email address and account if they've entered it previously
			if ((emailAddress = [[NSUserDefaults standardUserDefaults] objectForKey:KEY_CRASH_EMAIL_ADDRESS])) {
				[textField_emailAddress setStringValue:emailAddress];
			}
			if ((aimAccount = [[NSUserDefaults standardUserDefaults] objectForKey:KEY_CRASH_AIM_ACCOUNT])) {
				[textField_accountIM setStringValue:aimAccount];
			}
			
			//Highlight the existing details text
			[textView_details setSelectedRange:NSMakeRange(0, [[textView_details textStorage] length])
									  affinity:NSSelectionAffinityUpstream
								stillSelecting:NO];
			
			//Open our window
			[window_MainWindow makeKeyAndOrderFront:nil];
			
			return YES;
		}
	}
	
	return NO;
}

#pragma mark Privacy Details
//Display privacy information sheet
- (IBAction)showPrivacyDetails:(id)sender
{
    NSDictionary		*attributes = [NSDictionary dictionaryWithObject:[NSFont systemFontOfSize:11]
																  forKey:NSFontAttributeName];
    NSAttributedString	*attrLogString = [[[NSAttributedString alloc] initWithString:crashLog
																		  attributes:attributes] autorelease];
    
    //Fill in crash log
    [[textView_crashLog textStorage] setAttributedString:attrLogString];
    
    //Display the sheet
    [NSApp beginSheet:panel_privacySheet
       modalForWindow:window_MainWindow
        modalDelegate:nil
       didEndSelector:nil
          contextInfo:nil];
}

//Close the privacy details sheet
- (IBAction)closePrivacyDetails:(id)sender
{
    [panel_privacySheet orderOut:nil];
    [NSApp endSheet:panel_privacySheet returnCode:0];
}

#pragma mark Report sending

/*
 * @brief Disable the close button and begin spinning the indeterminate progress indicator
 */
- (void)activateProgressIndicator
{
	//Hide the button, even on 10.2
	[button_close setFrame:NSZeroRect];
	
	//Display immediately since we need it for this run loop.
	[[button_close superview] display];
	
	if ([progress_sending respondsToSelector:@selector(setHidden:)]) {
		[progress_sending setHidden:NO];
	}
	
	//start the progress spinner (using multi-threading)
	[progress_sending setUsesThreadedAnimation:YES];
	[progress_sending startAnimation:nil];
}	

/*
 * @brief User wants to send the report
 */
- (IBAction)send:(id)sender
{
	if ([[textField_emailAddress stringValue] isEqualToString:@""] &&
	   [[textField_accountIM stringValue] isEqualToString:@""]) {
		NSBeginCriticalAlertSheet(AILocalizedString(@"Contact Information Required",nil),
								  @"OK", nil, nil, window_MainWindow, nil, nil, nil, NULL,
								  AILocalizedString(@"Please provide either your email address or AIM name in case we need to contact you for additional information (or to suggest a solution).",nil));
	} else {
		//Begin showing progress
		[self activateProgressIndicator];
		
		//Load the build information
		[self _loadBuildInformation];

		//Perform version checking; when it is complete or fails, the submission process wil continue
		[self performVersionChecking];
	}
}

/*
 * @brief Build the crash report and associated information, then pass it to sendReport:
 */
- (void)buildAndSendReport
{
	NSString	*shortDescription = [textField_description stringValue];
	
	//Truncate description field to 300 characters
	if ([shortDescription length] > 300) {
		shortDescription = [shortDescription substringToIndex:300];
	}

	//Build the report
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] initWithDateFormat:@"%m-%d" 
															 allowNaturalLanguage:NO] autorelease];
	NSString		*buildDateAndInfo = [NSString stringWithFormat:@"%@	(%@)",
		[dateFormatter stringForObjectValue:buildDate],
		(buildUser ? buildUser : buildNumber)];
	
	NSDictionary	*crashReport = [NSDictionary dictionaryWithObjectsAndKeys:
		buildDateAndInfo, @"build",
		[textField_emailAddress stringValue], @"email",
		[textField_accountIM stringValue], @"service_name",
		shortDescription, @"short_desc",
		[textView_details string], @"desc",
		crashLog, @"log",
		nil];
	
	//Send
	[self sendReport:crashReport];
}

/*
 * @brief Send a crash report to the crash reporter web site
 */
- (void)sendReport:(NSDictionary *)crashReport
{
    NSMutableString *reportString = [[[NSMutableString alloc] init] autorelease];
    NSEnumerator	*enumerator;
    NSString		*key;
    NSData 			*data = nil;
    
    //Compact the fields of the report into a long URL string
    enumerator = [[crashReport allKeys] objectEnumerator];
    while ((key = [enumerator nextObject])) {
        if ([reportString length] != 0) [reportString appendString:@"&"];
        [reportString appendFormat:@"%@=%@", key, [[crashReport objectForKey:key] stringByEncodingURLEscapes]];
    }

    //
    while (!data || [data length] == 0) {
        NSError 			*error;
        NSURLResponse 		*reply;
        NSMutableURLRequest *request;
        
        //Build the URL request
        request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:CRASH_REPORT_URL]
                                          cachePolicy:NSURLRequestReloadIgnoringCacheData
                                      timeoutInterval:120];
        [request addValue:@"Adium 2.0a" forHTTPHeaderField:@"X-Adium-Bug-Report"];
        [request setHTTPMethod:@"POST"];
        [request setHTTPBody:[reportString dataUsingEncoding:NSUTF8StringEncoding]];

        //Attempt to send report
        data = [NSURLConnection sendSynchronousRequest:request returningResponse:&reply error:&error];
        
        //stop the progress spinner
        [progress_sending stopAnimation:nil];
        
        //Alert on failure, and offer the option to quit or retry
        if (!data || [data length] == 0) {
            if (NSRunAlertPanel(UNABLE_TO_SEND,
                               [error localizedDescription],
                               AILocalizedString(@"Try Again",nil),
                               AILocalizedString(@"Quit",nil),
                               nil) == NSAlertAlternateReturn) {
                break;
            }
        }
    }
}

#pragma mark Closing behavior
//Save some of the information for next time on quit
- (void)windowWillClose:(id)sender
{
    //Remember the user's email address, account name
    [[NSUserDefaults standardUserDefaults] setObject:[textField_emailAddress stringValue]
                                              forKey:KEY_CRASH_EMAIL_ADDRESS];	
    [[NSUserDefaults standardUserDefaults] setObject:[textField_accountIM stringValue]
                                              forKey:KEY_CRASH_AIM_ACCOUNT];	
}

//Terminate if our window is closed
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
    return YES;
}

#pragma mark Build information
//Load the current build date and our svn revision
- (void)_loadBuildInformation
{
    //Grab the info from our buildnum script
    char *path, unixDate[256], num[256],whoami[256];
    if ((path = (char *)[[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/../../../buildnum"] fileSystemRepresentation]))
    {
        FILE *f = fopen(path, "r");
        fscanf(f, "%s | %s | %s", num, unixDate, whoami);
        fclose(f);
		
        if (*num) {
            buildNumber = [[NSString stringWithFormat:@"%s", num] retain];
		}
		
		if (*unixDate) {
			buildDate = [[NSDate dateWithTimeIntervalSince1970:[[NSString stringWithCString:unixDate] doubleValue]] retain];
		}
		
		if (*whoami) {
			buildUser = [[NSString stringWithFormat:@"%s", whoami] retain];
			if ([buildUser isEqualToString:@"adamiser"] || 
				[buildUser isEqualToString:@"evands"] || 
				[buildUser isEqualToString:@"jmelloy"]) {
				[buildUser release];
				buildUser = nil;
			}
			
		}
    }
    
    //Default to empty strings if something goes wrong
    if (!buildDate) buildDate = [@"" retain];
    if (!buildNumber) buildNumber = [@"" retain];
}

/*!
* @brief Invoked when version information is received
 *
 * Parse the version dictionary. Only allow crash reports to be sent for the latest release (or beta).
 * If the user is running an old version, offer the chance to go to the download site immediately.
 *
 * @param versionDict Dictionary from the web containing version numbers of the most recent releases
 */
- (void)_versionReceived:(NSDictionary *)versionDict
{
	NSString	*number = [versionDict objectForKey:VERSION_PLIST_KEY];
	NSDate		*newestDate;
	BOOL		allowReport;
	BOOL		shouldRelaunchAdium = YES;
	
	//Get the newest version date from the passed version dict
	newestDate = ((versionDict && number) ?
				  [NSDate dateWithTimeIntervalSince1970:[number doubleValue]] :
				  nil);

	/* If we got no version information, or this version is as new or newer than the one available on the server,
	 * allow the report to be sent
	 */
	if (!newestDate ||
		[buildDate isEqualToDate:newestDate] || [buildDate isEqualToDate:[buildDate laterDate:newestDate]]) {
		allowReport = YES;
		
		// Don't allow old betas to send crash reports
		if (BETA_RELEASE) {
			NSString	*betaNumber = [versionDict objectForKey:VERSION_BETA_PLIST_KEY];
			NSDate		*betaDate;
			
			betaDate = ((versionDict && number) ?
						[NSDate dateWithTimeIntervalSince1970:[betaNumber doubleValue]] :
						nil);
			
			//Don't allow the report if we got a beta date, and it's not the current date and it's later than our date
			if (betaDate &&
				![buildDate isEqualToDate:betaDate] &&
				![buildDate isEqualToDate:[buildDate laterDate:betaDate]]) {
				allowReport = NO;
			}
		}
		
	} else {
		allowReport = NO;
	}

	if (allowReport) {
		[self buildAndSendReport];
		
	} else {
		if (NSRunAlertPanel(UNABLE_TO_SEND,
							AILocalizedString(@"You are running an old version of Adium; crash reporting has been disabled. Please update to the latest version, as your crash may have already been fixed.",nil),
							AILocalizedString(@"Update Now",nil),
							AILocalizedString(@"Cancel",nil),
							nil) == NSAlertDefaultReturn) {
			shouldRelaunchAdium = NO;
			[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:(BETA_RELEASE ?
																		 ADIUM_UPDATE_BETA_URL :
																		 ADIUM_UPDATE_URL)]];
		}
	}

	//Relaunch Adium if appropriate
	if (shouldRelaunchAdium) {
		if (adiumPath) {
			[[NSWorkspace sharedWorkspace] openFile:adiumPath];
		} else {
			[[NSWorkspace sharedWorkspace] launchApplication:@"Adium"];
		}
	}
	
	//Close our window to terminate
	[window_MainWindow performClose:nil];
}


/*!
* @brief Returns the date of the most recent Adium build (contacts adiumx.com asynchronously)
 */
- (void)performVersionChecking
{
	[[NSURL URLWithString:VERSION_PLIST_URL] loadResourceDataNotifyingClient:self usingCache:NO];
}

/*!
* @brief Invoked when the versionDict was downloaded succesfully
 *
 * In response, we parse the received version information.
 */
- (void)URLResourceDidFinishLoading:(NSURL *)sender
{
	NSData			*data = [sender resourceDataUsingCache:YES];
	
	if (data) {
		NSDictionary	*versionDict;
		
		versionDict = [NSPropertyListSerialization propertyListFromData:data
													   mutabilityOption:NSPropertyListImmutable
																 format:nil
													   errorDescription:nil];
		
		[self _versionReceived:versionDict];
	}
}

/*!
* @brief Invoked when the versionDict could not be loaded
 */
- (void)URLResourceDidCancelLoading:(NSURL *)sender
{
	[self _versionReceived:nil];
}

@end


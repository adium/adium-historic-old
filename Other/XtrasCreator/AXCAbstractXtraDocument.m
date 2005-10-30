//
//  AXCAbstractXtraDocument.m
//  XtrasCreator
//
//  Created by David Smith on 10/27/05.
//  Copyright 2005 Adium Team. All rights reserved.
//

#import "AXCAbstractXtraDocument.h"
#import "MessageStyleViewController.h"

@implementation AXCAbstractXtraDocument

- (id)init
{
    self = [super init];
    if (self) {
    
        // Add your subclass-specific initialization here.
        // If an error occurs here, send a [self release] message and return nil.
    
    }
    return self;
}

- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"MyDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];
	[typePopup setAutoenablesItems:NO];
	NSMenuItem * item = [[[NSMenuItem alloc] initWithTitle:@"Message View Style" 
													action:@selector(setXtraType:) 
											 keyEquivalent:@""]autorelease];
	[item setEnabled:YES];
    [[typePopup menu] addItem:item];
	item = [[[NSMenuItem alloc] initWithTitle:@"Status Icons" 
									   action:@selector(setXtraType:) 
								keyEquivalent:@""]autorelease];
	[item setEnabled:YES];
	[[typePopup menu] addItem:item];
}

- (BOOL)writeToFile:(NSString *)fileName ofType:(NSString *)docType
{
	NSString * path = fileName;
	NSFileManager * manager = [NSFileManager defaultManager];
	NSString * name = [nameField stringValue];
	if(![manager fileExistsAtPath:path])
	{
		[manager createDirectoryAtPath:path attributes:nil];

		path = [path stringByAppendingPathComponent:@"Contents"];
		[manager createDirectoryAtPath:path attributes:nil];

		NSDictionary *infoPlist = [NSDictionary dictionaryWithObjectsAndKeys:
			@"English", kCFBundleDevelopmentRegionKey,
			name, kCFBundleNameKey,
			@"AdIM", @"CFBundlePackageType",
			[@"com.adiumx." stringByAppendingString:name], kCFBundleIdentifierKey,
			[NSNumber numberWithInt:1], @"XtraBundleVersion",
			@"1.0", kCFBundleInfoDictionaryVersionKey,
			[versionField stringValue], @"XtraVersion",
			[authorField stringValue], @"XtraAuthors",
			xtraType, @"XtraType",
			nil];
		[infoPlist writeToFile:[path stringByAppendingPathComponent:@"Info.plist"] atomically:YES];

		path = [path stringByAppendingPathComponent:@"Resources"];
		[manager createDirectoryAtPath:path attributes:nil];

		NSEnumerator * resourceEnu = [resources objectEnumerator];
		NSString * resourcePath;
		while ((resourcePath = [resourceEnu nextObject]))
		{
			[manager copyPath:resourcePath 
					   toPath:[path stringByAppendingPathComponent:[resourcePath lastPathComponent]]												  handler:nil];
		}

		NSString *iconPathExtension = [iconPath pathExtension];
		if(iconPath || !([iconPathExtension isEqualToString:@"icns"] || [iconPathExtension isEqualToString:@"tiff"] || [iconPathExtension isEqualToString:@"tif"])) {
			//TODO: error handling
			NSLog(@"OMGWTF, not an IconFamily or TIFF file");
		}
		[manager copyPath:iconPath
				   toPath:[path stringByAppendingPathComponent:[@"Icon." stringByAppendingPathExtension:extension]]
				  handler:nil];

		[[readmeView RTFFromRange: NSMakeRange(0, [[readmeView string] length])] writeToFile:[path stringByAppendingPathComponent:@"ReadMe.rtf"] atomically:YES];

		[controller writeCustomFilesToPath:path];
		return YES;
	}	
	else
		return NO;
}

- (BOOL) readFromFile:(NSString *)path ofType:(NSString *)type
{
    return YES;
}

- (IBAction) addFiles:(id)sender
{
	if(!resources)
		resources = [[NSMutableSet alloc] init];
	NSOpenPanel * p = [NSOpenPanel openPanel];
	[p setAllowsMultipleSelection:YES];
	[p runModal];
	[resources addObjectsFromArray:[p filenames]];
	[fileView setString:[[resources allObjects] componentsJoinedByString:@"\n"]];
}

- (IBAction) setIcon:(id)sender
{
	NSOpenPanel * p = [NSOpenPanel openPanel];
	[p setAllowsMultipleSelection:YES];
	[p runModal];
	[self setIconPath: [[p filenames] objectAtIndex:0]];
}

- (void) setIconPath:(NSString *)inPath
{
	[iconPath autorelease];
	iconPath = [inPath retain];
}

- (NSString *) iconPath
{
	return iconPath;
}

- (IBAction) setXtraType:(id)sender
{
	if([tabs numberOfTabViewItems] > 2)
		[tabs removeTabViewItem:[tabs tabViewItemAtIndex:2]];
	xtraType = [sender title];
	[typePopup selectItemWithTitle:xtraType];
	NSTabViewItem * item = [[NSTabViewItem alloc] initWithIdentifier:xtraType];
	[item setLabel:xtraType];
	if([xtraType isEqualToString:@"Message View Style"]) {
		controller = [[MessageStyleViewController controller]retain];
		[item setView:[controller view]];
	}
	[tabs addTabViewItem:[item autorelease]];
}

@end

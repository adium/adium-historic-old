//
//  AXCAbstractXtraDocument.m
//  XtrasCreator
//
//  Created by David Smith on 10/27/05.
//  Copyright 2005 Adium Team. All rights reserved.
//

#import "AXCAbstractXtraDocument.h"
#import "MessageStyleViewController.h"
#import "AXCFileCell.h"
#import "IconFamily.h"
#import "NSFileManager+BundleBit.h"

@implementation AXCAbstractXtraDocument

- (id)init
{
	if ((self = [super init])) {
		resources = [[NSMutableArray alloc] init];
		resourcesSet = [[NSMutableSet alloc] init];
	}
	return self;
}

- (void)dealloc {
	[resources release];
	[resourcesSet release];

	[super dealloc];
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

	/*fill in typePopUp*/ {
		//XXX typePopup will be axed
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

	/*set up cell in table view*/ {
		AXCFileCell *cell = [[AXCFileCell alloc] initTextCell:@""];
		[[[fileView tableColumns] objectAtIndex:0U] setDataCell:cell];
		[cell release];
	}

	/*fill in tab view*/ {
		NSEnumerator * tabViewItemsEnum = [[self tabViewItems] objectEnumerator];
		NSTabViewItem * item;
		while((item = [tabViewItemsEnum nextObject]))
			[tabs addTabViewItem:item];
	}
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
			[self OSType], @"CFBundlePackageType",
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
					   toPath:[path stringByAppendingPathComponent:[resourcePath lastPathComponent]]							  handler:nil];
		}

		IconFamily* iconFamily = [IconFamily iconFamilyWithThumbnailsOfImage:icon]; //check on error handling for this
		[iconFamily setAsCustomIconForFile:fileName];

		[[readmeView RTFFromRange: NSMakeRange(0, [[readmeView string] length])] writeToFile:[path stringByAppendingPathComponent:@"ReadMe.rtf"] atomically:YES];

		[controller writeCustomFilesToPath:path];

		//all Xtras are bundles
		[manager setBundleBitOfFile:path toBool:YES];

		return YES;
	}	
	else
		return NO;
}
- (BOOL)writeToURL:(NSURL *)URL ofType:(NSString *)typeName error:(NSError **)outError {
	NSString * path = [URL path];
	return [self writeToFile:path ofType:typeName];
}

- (BOOL) readFromFile:(NSString *)path ofType:(NSString *)type
{
    return YES;
}

- (void) printShowingPrintPanel:(BOOL)flag
{
	//XXX TEMP - should make a new view that grabs all the information from this document, and displays it linearly
	NSPrintOperation *op = [NSPrintOperation printOperationWithView:fileView];
	[op setShowsPrintPanel:flag];
	[op runOperation];
}

- (IBAction) addFiles:(id)sender
{
	NSOpenPanel * p = [NSOpenPanel openPanel];
	[p setAllowsMultipleSelection:YES];
	[p runModal];

	NSArray *newFiles = [p filenames];
	NSMutableSet *newFilesSet = [NSMutableSet setWithArray:newFiles];
	//remove from newFilesSet all the files that we already have added.
	NSMutableSet *temp = [resourcesSet mutableCopy];
	[temp intersectSet:newFilesSet];
	[newFilesSet minusSet:temp];
	[temp release];

	if([newFilesSet count]) {
		newFiles = [newFilesSet allObjects];
		[resourcesSet addObjectsFromArray:newFiles];

		NSIndexSet *newIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange([resources count], [newFiles count])];
		[self willChange:NSKeyValueChangeInsertion valuesAtIndexes:newIndexes forKey:@"resources"];
		[resources addObjectsFromArray:newFiles];
		[self  didChange:NSKeyValueChangeInsertion valuesAtIndexes:newIndexes forKey:@"resources"];
	}
}

- (IBAction) runChooseIconPanel:(id)sender
{
	NSOpenPanel * p = [NSOpenPanel openPanel];
	[p setAllowsMultipleSelection:YES];
	[p runModal];
	[self setIcon:[[[NSImage alloc] initByReferencingFile:[[p filenames] objectAtIndex:0]]autorelease]];
}

#pragma mark -

- (void) setIcon:(NSImage *)inImage
{
	[icon autorelease];
	icon = [inImage retain];
}

- (NSImage *) icon
{
	return icon;
}

#pragma mark -

- (NSString *) OSType
{
	return @"AdIM";
}
- (NSString *) pathExtension
{
	return nil;
}
- (NSString *) uniformTypeIdentifier
{
	return @"com.adiumx.xtra";
}

//added to the tab view.
- (NSArray *) tabViewItems
{
	return [NSArray array];
}

@end

//
//  AXCAbstractXtraDocument.m
//  XtrasCreator
//
//  Created by David Smith on 10/27/05.
//  Copyright 2005 Adium Team. All rights reserved.
//

#import "AXCAbstractXtraDocument.h"

#import "AXCFileCell.h"
#import "IconFamily.h"
#import "NSFileManager+BundleBit.h"
#include <c.h>

#define THUMBNAIL_SIZE 16.0

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
	[name release];
	[author release];
	[version release];
	[icon release];
	
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
	if(![manager fileExistsAtPath:path])
	{
		[manager createDirectoryAtPath:path attributes:nil];

		path = [path stringByAppendingPathComponent:@"Contents"];
		[manager createDirectoryAtPath:path attributes:nil];

		NSDictionary *infoPlist = [self infoPlistDictionary];
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

- (IBAction) runAddFilesPanel:(id)sender
{
	NSOpenPanel * p = [NSOpenPanel openPanel];
	[p setAllowsMultipleSelection:YES];
	[p beginSheetForDirectory:nil
						 file:nil
						types:[self validResourceTypes]
			   modalForWindow:[self windowForSheet]
				modalDelegate:self
			   didEndSelector:@selector(didEndAddFilesPanel:returnCode:contextInfo:)
				  contextInfo:NULL];
}

- (void) didEndAddFilesPanel:(NSOpenPanel *)p returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	if (returnCode != NSOKButton)
		return;

	NSArray *newFiles = [p filenames];
	NSMutableSet *newFilesSet = [NSMutableSet setWithArray:newFiles];
	//remove from newFilesSet all the files that we already have added.
	NSMutableSet *temp = [resourcesSet mutableCopy];
	[temp intersectSet:newFilesSet];
	[newFilesSet minusSet:temp];
	[temp release];

	if ([newFilesSet count]) {
		newFiles = [newFilesSet allObjects];
		[resourcesSet addObjectsFromArray:newFiles];

		NSIndexSet *newIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange([resources count], [newFiles count])];
		[self willChange:NSKeyValueChangeInsertion valuesAtIndexes:newIndexes forKey:@"resources"];
		[resources addObjectsFromArray:newFiles];
		[self  didChange:NSKeyValueChangeInsertion valuesAtIndexes:newIndexes forKey:@"resources"];

		//add the files to the imagePreviews and displayNames dictionaries.
		NSEnumerator *newFilesEnum = [newFiles objectEnumerator];
		NSString *path;
		while ((path = [newFilesEnum nextObject])) {
			NSImage *image = [[NSImage alloc] initWithContentsOfFile:path];
			NSSize size = [image size]; //note: only used if image != nil
			if (image) {
				if (!imagePreviews)
					imagePreviews = [[NSMutableDictionary alloc] init];

				NSSize previewSize = size;
				float maxDimension = MAX(size.width, size.height);
				if (maxDimension > THUMBNAIL_SIZE) {
					//scale proportionally to Wx16 or 16xH.
					float scale = maxDimension / THUMBNAIL_SIZE;
					previewSize.width  /= scale;
					previewSize.height /= scale;
					[image setScalesWhenResized:YES];
					[image setSize:previewSize];
				}
				[image setName:[@"Preview of " stringByAppendingString:path]];

				[imagePreviews setObject:image forKey:path];
			}

			/*now store the display name as well*/ {
				if (!displayNames)
					displayNames = [[NSMutableDictionary alloc] init];

				NSString *displayName = [[NSFileManager defaultManager] displayNameAtPath:path];
				if (image) {
					enum { MULTIPLICATION_SIGN = 0x00d7 };
					displayName = [NSString stringWithFormat:@"%@ (%u%C%u)", displayName, (unsigned)size.width, MULTIPLICATION_SIGN, (unsigned)size.height];
				}

				[displayNames setObject:displayName forKey:path];
			}
		}
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

- (void) setName:(NSString *)newName {
	[name release];
	name = [newName copy];
}
- (NSString *) name {
	return name;
}

- (void) setAuthor:(NSString *)newAuthor {
	[author release];
	author = [newAuthor copy];
}
- (NSString *) author {
	return author;
}

- (void) setVersion:(NSString *)newVersion {
	[version release];
	version = [newVersion copy];
}
- (NSString *) version {
	return version;
}

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

- (NSArray *) validResourceTypes
{
	return nil;
}

- (NSDictionary *) infoPlistDictionary
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
		@"English", kCFBundleDevelopmentRegionKey,
		name, kCFBundleNameKey,
		[self OSType], @"CFBundlePackageType",
		[@"com.adiumx." stringByAppendingString:name], kCFBundleIdentifierKey,
		[NSNumber numberWithInt:1], @"XtraBundleVersion",
		@"1.0", kCFBundleInfoDictionaryVersionKey,
		version, @"XtraVersion",
		author, @"XtraAuthors",
		nil];
}

//added to the tab view.
- (NSArray *) tabViewItems
{
	return [NSArray array];
}

@end

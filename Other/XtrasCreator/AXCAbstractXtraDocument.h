//
//  AXCAbstractXtraDocument.h
//  XtrasCreator
//
//  Created by David Smith on 10/27/05.
//  Copyright 2005 Adium Team. All rights reserved.
//


#import <Cocoa/Cocoa.h>

@protocol ViewController;

@interface AXCAbstractXtraDocument : NSDocument
{
	NSMutableArray * resources;
	NSMutableSet * resourcesSet;
	NSImage * icon;

	NSMutableDictionary *imagePreviews; //keys: paths to image files; values: NSImages
	NSMutableDictionary *displayNames; //keys: paths to files; values: display names (for an image, includes ' (WxH)' suffix)

	IBOutlet NSTabView * tabs;
	IBOutlet NSTableView * fileView;
	IBOutlet NSTextField * authorField;
	IBOutlet NSTextField * nameField;
	IBOutlet NSTextField * versionField;
	id<ViewController> controller;
	IBOutlet NSTextView * readmeView;
}

#pragma mark Actions

- (IBAction) runAddFilesPanel:(id)sender;
- (IBAction) runChooseIconPanel:(id)sender;

#pragma mark Accessors

- (void) setIcon:(NSImage *)icon;
- (NSImage *) icon;

#pragma mark For subclasses

//all three of these are used for new documents. for an existing document, these will not be called.
- (NSString *) OSType;
- (NSString *) pathExtension;
- (NSString *) uniformTypeIdentifier;

//types of files that can be added as resources via the 'Add Files...' button, or via drag-and-drop.
//if nil, all types are valid.
- (NSArray *) validResourceTypes;

//added to the tab view.
- (NSArray *) tabViewItems;

@end

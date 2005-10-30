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
	NSString * iconPath;
	NSString * xtraType; //XXX might be axed

	IBOutlet NSTabView * tabs;
	IBOutlet NSTableView * fileView;
	IBOutlet NSTextField * authorField;
	IBOutlet NSTextField * nameField;
	IBOutlet NSTextField * versionField;
	IBOutlet NSPopUpButton * typePopup; //XXX will be axed
	id<ViewController> controller;
	IBOutlet NSTextView * readmeView;
}

#pragma mark Actions

- (IBAction) addFiles:(id)sender;

#pragma mark Accessors

- (void) setIconPath:(NSString *)path;
- (NSString *) iconPath;

#pragma mark For subclasses

//all three of these are used for new documents. for an existing document, these will not be called.
- (NSString *) OSType;
- (NSString *) pathExtension;
- (NSString *) uniformTypeIdentifier;

//added to the tab view.
- (NSArray *) tabViewItems;

@end

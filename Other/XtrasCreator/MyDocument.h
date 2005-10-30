//
//  MyDocument.h
//  XtrasCreator
//
//  Created by David Smith on 10/27/05.
//  Copyright 2005 Adium Team. All rights reserved.
//


#import <Cocoa/Cocoa.h>

@protocol ViewController;

@interface MyDocument : NSDocument
{
	NSMutableSet * resources;
	NSString * xtraType;
	IBOutlet NSTabView * tabs;
	IBOutlet NSTextView * fileView;
	IBOutlet NSTextField * authorField;
	IBOutlet NSTextField * nameField;
	IBOutlet NSTextField * versionField;
	IBOutlet NSPopUpButton * typePopup;
	id<ViewController> controller;
	IBOutlet NSTextView * readmeView;
	NSString * iconPath;
}

- (IBAction) addFiles:(id)sender;
- (IBAction) setIcon:(id)sender;
- (void) setIconPath:(NSString *)path;
- (NSString *) iconPath;
- (IBAction) setXtraType:(id)sender;
@end

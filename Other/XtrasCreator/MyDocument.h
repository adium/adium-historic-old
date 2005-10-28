//
//  MyDocument.h
//  XtrasCreator
//
//  Created by David Smith on 10/27/05.
//  Copyright __MyCompanyName__ 2005 . All rights reserved.
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
}

- (IBAction) addFiles:(id)sender;
- (IBAction) setXtraType:(id)sender;
@end

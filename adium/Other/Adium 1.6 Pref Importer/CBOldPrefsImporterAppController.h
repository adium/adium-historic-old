//
//  CBOldPrefsImporterAppController.h
//  Adium
//
//  Created by Colin Barrett on Sun Aug 24 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

@interface CBOldPrefsImporterAppController : NSObject 
{
    IBOutlet	NSWindow		*window_main;
    IBOutlet	NSPopUpButton		*popUpButton_account;
    IBOutlet	NSButton		*checkBox_aliases;
    IBOutlet	NSButton		*checkBox_contacts;
    IBOutlet	NSProgressIndicator	*progressIndicator;
    IBOutlet	NSTextField		*currentTask;
    IBOutlet	NSButton		*button_import;
    
    IBOutlet	NSWindow		*theSheet;
    IBOutlet	NSPopUpButton		*popUpButton_user;
    IBOutlet	NSButton		*button_OK;
    IBOutlet	NSButton		*button_Cancel;
}

- (IBAction)import:(id)sender;
- (IBAction)sheetButton:(id)sender;

//NSApplication delegate methods
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication;

//modal delegate methods
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)code contextInfo:(void *)info;
@end

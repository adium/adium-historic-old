//
//  CBOldPrefsImporterAppController.h
//  Adium
//
//  Created by Colin Barrett on Sun Aug 24 2003.
//

@interface CBOldPrefsImporterAppController : NSObject 
{
    IBOutlet	NSWindow		*window_main;
    IBOutlet	NSPopUpButton		*popUpButton_account;
    IBOutlet	NSProgressIndicator	*progressIndicator;
    IBOutlet	NSTextField		*currentTask;
    
    IBOutlet	NSWindow		*theSheet;
    IBOutlet	NSPanel			*importListSheet;
    IBOutlet	NSPopUpButton		*popUpButton_user;
    IBOutlet	NSButton		*button_OK;
    IBOutlet	NSButton		*button_Cancel;
}

- (IBAction)importLogs:(id)sender;
- (IBAction)importAliases:(id)sender;
- (IBAction)importContacts:(id)sender;
- (IBAction)sheetButton:(id)sender;
- (BOOL)ensureAdiumIsClosed;

//NSApplication delegate methods
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication;

@end

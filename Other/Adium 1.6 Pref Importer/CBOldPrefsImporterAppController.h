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
    IBOutlet    NSImageView             *image_AdiumImage;
    IBOutlet	NSWindow		*theSheet;
    IBOutlet	NSPanel			*importListSheet;
    IBOutlet	NSPopUpButton		*popUpButton_user;
    IBOutlet	NSButton		*button_OK;
    IBOutlet	NSButton		*button_Cancel;
    IBOutlet    NSButton                *button_ImportAwayMessages;
    IBOutlet    NSPopUpButton           *popUpButton_Clients;
    IBOutlet    NSButton                *button_Import;
    IBOutlet    NSProgressIndicator     *spinner_importProgress;
    IBOutlet    NSTabView               *tabView_ClientTabs;
    IBOutlet    NSTabView               *tabView_optionsTab;
    IBOutlet	AIContentController     *contentController;
    IBOutlet    NSButton                *button_importAllProteusAways;
    
    
}
- (AIContentController *)contentController;
- (IBAction)importLogs:(id)sender;
- (IBAction)importAliases:(id)sender;
- (IBAction)importContacts:(id)sender;
- (IBAction)sheetButton:(id)sender;
- (IBAction)importAwayMessages:(id)sender;

- (BOOL)ensureAdiumIsClosed;
- (void)importiChatAways;
- (void)importProteusAways;
- (void)importFireAways;

//NSApplication delegate methods
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication;


@end

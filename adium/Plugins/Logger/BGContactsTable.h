#import <Cocoa/Cocoa.h>
#import "AILogViewerWindowController.h"

@interface BGContactsTable : AIObject {
    IBOutlet    NSTableView                    *table_contacts;
    IBOutlet    NSTableView                    *table_accounts;
    IBOutlet    NSTabView                      *tabs_hiddenLogSwitch;
    IBOutlet    AILogViewerWindowController    *controller_LogViewer;
    IBOutlet    NSPopUpButton                  *popup_switcherThingie;
}
-(IBAction)switchTable:(id)sender;
@end

/* BDImportController */

#import <Cocoa/Cocoa.h>
#import "BDImporter.h"
#import "BDProteusImporter.h"
#import "BDFireImporter.h"
#import "BDiChatImporter.h"

@interface BDImportController : NSObject
{
    IBOutlet NSButton		*button_Cancel;
    IBOutlet NSButton		*button_Import;
    IBOutlet NSButton		*button_proteusAddAccount;
    IBOutlet NSButton		*button_proteusDelAccount;
    IBOutlet NSImageView	*image_proteusImage;
    IBOutlet NSTableView	*table_proteusAccounts;
    IBOutlet NSTabView		*tabView_ClientTab;
	IBOutlet NSPanel		*panel_importPanel;
	
	BDProteusImporter		*proteus;
	BDFireImporter			*fire;
	BDiChatImporter			*iChat;
	
}
@end

//
//  ESContactAlerts.h
//  Adium
//
//  Created by Evan Schoenberg on Sun Aug 03 2003.
//

#import <Cocoa/Cocoa.h>
#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>
#import "AIAdium.h"

@interface ESContactAlerts : NSObject {
    NSView				*view_main;
    AIAlternatingRowTableView		*tableView_actions;
    NSView				*view_blank;
    NSView				*view_details;
    NSView				*view_pref;

    //Menu View
    IBOutlet	NSView			*view_details_menu;
    IBOutlet	NSTextField		*textField_description_popUp;
    IBOutlet	NSPopUpButton		*popUp_actionDetails;
    //Text View
    IBOutlet	NSView			*view_details_text;
    IBOutlet 	NSTextField		*textField_description_textField;
    IBOutlet	NSTextField		*textField_actionDetails;
    //Message View
    IBOutlet	NSView			*view_details_message;
    IBOutlet	NSTextField		*textField_message_actionDetails;
    IBOutlet	NSPopUpButton		*popUp_message_actionDetails_one;
    IBOutlet	NSPopUpButton		*popUp_message_actionDetails_two;
    IBOutlet	NSButton		*button_anotherAccount;
    IBOutlet	NSButton		*button_displayAlert;

    int					row;
    int					offset;

    AIListObject			*activeContactObject;
    NSMutableArray			*eventActionArray;
    NSMutableArray			*eventSoundArray;

    AIAdium				*owner;
}

- (id)init;
- (id)initForObject:(AIListObject *)inObject withDetailsView:(NSView *)inView withTable:(AIAlternatingRowTableView *)inTable withPrefView:(NSView *)inPrefView owner:(id)inOwner;
- (void)removeAllSubviews:(NSView *)view;
- (void)configureWithSubview:(NSView *)view_inView;
- (void)oneTimeEvent:(NSButton *)inButton;
- (NSMenu *)actionListMenu;
- (NSMenu *)eventMenu;
- (BOOL)hasAlerts;
- (int)count;
- (int)currentRow;
- (NSMutableDictionary *)dictAtIndex:(int)inRow;
- (NSMutableArray *)eventActionArray;
- (void)currentRowIs:(int)currentRow;
- (void)setOffset:(int)inOffset;
- (void)changeOffsetBy:(int)changeOffset;
- (void)replaceDictAtIndex:(int)inRow withDict:(NSDictionary *)selectedActionDict;
- (void)executeAppropriateAction:(NSString *)action inMenu:(NSMenu *)actionMenu;
- (AIListObject *)activeObject;

- (IBAction)deleteEventAction:(id)sender;
- (IBAction)newEvent:(id)sender;
- (IBAction)selectSound:(id)sender;
- (IBAction)selectBehavior:(id)sender;
- (IBAction)selectAccount:(id)sender;
- (IBAction)saveMessageDetails:(id)sender;

- (IBAction)actionBounceDock:(id)sender;
- (IBAction)actionDisplayAlert:(id)sender;
- (IBAction)actionPlaySound:(id)sender;
- (IBAction)actionSendMessage:(id)sender;
- (IBAction)actionSpeakText:(id)sender;

- (BOOL)isEqual:(id)inInstance;
- (unsigned) hash;

@end

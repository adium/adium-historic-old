//
//  ESContactAlertsPreferences.h
//  Adium
//
//  Created by Evan Schoenberg on Sun Aug 03 2003.
//

#import <Cocoa/Cocoa.h>
#import <Adium/Adium.h>
#import "ESContactAlerts.h"
#import "ESContactAlertsActionColumn.h"

@class AIAdium, AIAlternatingRowTableView, AIListContact, ESContactAlertsPlugin;

@interface ESContactAlertsPreferences : NSObject {
    IBOutlet	NSPopUpButton			*popUp_addEvent;
    IBOutlet	AIAlternatingRowTableView	*tableView_actions;
    IBOutlet	ESContactAlertsActionColumn	*actionColumn;
    IBOutlet	NSButton			*button_delete;
    IBOutlet	NSButton			*button_oneTime;
    IBOutlet	NSButton			*button_active;
    IBOutlet	NSPopUpButton			*popUp_contactList;
    IBOutlet	NSView				*view_main;

    NSMenu					*actionMenu;

    AIAdium					*owner;
    AIListObject				*activeContactObject;
    NSMutableArray				*prefAlertsArray;
    NSMutableDictionary				*offsetDictionary;
    IBOutlet NSView				*view_prefView;

    ESContactAlerts				*instance;
}

+ (ESContactAlertsPreferences *)contactAlertsPreferencesWithOwner:(id)inOwner;

- (IBAction)deleteEventAction:(id)sender;
- (IBAction)addedEvent:(id)sender;
- (IBAction)anInstanceChanged:(id)sender;
- (IBAction)oneTimeEvent:(id)sender;
- (IBAction)onlyWhileActive:(id)sender;
@end

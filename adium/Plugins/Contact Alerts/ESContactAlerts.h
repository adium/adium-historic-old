//
//  ESContactAlerts.h
//  Adium
//
//  Created by Evan Schoenberg on Sun Aug 03 2003.
//

@interface ESContactAlerts : NSObject <ESContactAlerts> {
    NSView				*view_main;
    AIAlternatingRowTableView		*tableView_actions;
    NSView				*view_blank;
    NSView				*view_details;
    NSView				*view_pref;

    int					row;

    AIListObject			*activeContactObject;
    NSMutableArray			*eventActionArray;
    NSMutableArray			*eventSoundArray;

    NSMutableDictionary			*selectedActionDict;

    NSMenu				*actionListMenu_cached;
    NSMenu				*eventMenu_cached;
    NSMenu				*soundMenu_cached;

    NSString				*oldIdentifier;

    NSMutableDictionary			*cachedAlertsDict;
    
    AIAdium				*owner;
}

- (id)initWithDetailsView:(NSView *)inView withTable:(AIAlternatingRowTableView*)inTable withPrefView:(NSView *)inPrefView owner:(id)inOwner;
- (void)configForObject:(AIListObject *)inObject;
- (void)configureWithSubview:(NSView *)view_inView;
- (void)removeAllSubviews:(NSView *)view;
- (void)oneTimeEvent:(NSButton *)inButton;
- (void)onlyWhileActive:(NSButton *)inButton;
- (NSMenu *)actionListMenu;
- (NSMenu *)eventMenu;
- (BOOL)hasAlerts;
- (int)count;
- (int)currentRow;
- (NSMutableDictionary *)dictAtIndex:(int)inRow;
- (NSMutableArray *)eventActionArray;
- (void)currentRowIs:(int)currentRow;
- (void)replaceDictAtIndex:(int)inRow withDict:(NSDictionary *)newDict;
- (AIListObject *)activeObject;
- (void)reload:(AIListObject *)object usingCache:(BOOL)useCache;

- (IBAction)deleteEventAction:(id)sender;
- (IBAction)newEvent:(id)sender;

- (BOOL)isEqual:(id)inInstance;
- (unsigned) hash;

@end

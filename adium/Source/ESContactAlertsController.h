//
//  ESContactAlertsController.h
//  Adium
//
//  Created by Evan Schoenberg on Wed Nov 26 2003.

@class AIHandle, AIAccount, AIListGroup, AIListContact, ESContactAlert;
@protocol AIListObjectObserver;

#define One_Time_Event_Fired 		@"One Time Event Fired"

//A contact alert provider performs contact alert actions and provides ESContactAlert instances as required for the contact alert UI
@protocol ESContactAlertProvider <NSObject>
- (NSString *)identifier;
- (ESContactAlert *)contactAlert;
//performs an action using the information in details and detailsDict (either may be passed as nil in many cases), returning YES if the action fired and NO if it failed for any reason
- (BOOL)performActionWithDetails:(NSString *)details andDictionary:(NSDictionary *)detailsDict triggeringObject:(AIListObject *)inObject triggeringEvent:(NSString *)event eventStatus:(BOOL)event_status actionName:(NSString *)actionName;
- (BOOL)shouldKeepProcessing;
@end

@protocol ESContactAlerts <NSObject>
- (void)configureWithSubview:(NSView *)view_inView;
@end

@interface ESContactAlertsController : NSObject <AIListObjectObserver> {
    IBOutlet	AIAdium			*owner;
    NSMutableDictionary			*contactAlertProviderDictionary;
    AIMutableOwnerArray			*arrayOfStateDictionaries;
    AIMutableOwnerArray			*arrayOfAlertsArrays;
    
    NSMutableArray				*completedActionTypes;
}

//
- (void)registerContactAlertProvider:(id <ESContactAlertProvider>)contactAlertProvider;
- (void)unregisterContactAlertProvider:(id <ESContactAlertProvider>)contactAlertProvider;
//
- (void)createAlertsArrayWithOwner:(id <ESContactAlerts>)inOwner;
- (void)destroyAlertsArrayWithOwner:(id <ESContactAlerts>)inOwner;
//
- (void)configureWithSubview:(NSView *)inView forContactAlert:(ESContactAlert *)contactAlert;
- (NSMutableArray *)eventActionArrayForContactAlert:(ESContactAlert *)contactAlert;
- (NSDictionary *)currentDictForContactAlert:(ESContactAlert *)contactAlert;
- (AIListObject *)currentObjectForContactAlert:(ESContactAlert *)contactAlert;
- (NSWindow *)currentWindowForContactAlert:(ESContactAlert *)contactAlert;
- (int)rowForContactAlert:(ESContactAlert *)contactAlert;
- (void)saveEventActionArrayForContactAlert:(ESContactAlert *)contactAlert;
//
- (NSMenu *)actionListMenuWithOwner:(id <ESContactAlerts>)owner;
- (void)updateOwner:(id <ESContactAlerts>)inOwner toArray:(NSArray *)eventActionArray forObject:(AIListObject *)inObject;
- (void)updateOwner:(id <ESContactAlerts>)inOwner toRow:(int)row;
//list object observer
- (NSArray *)updateListObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys silent:(BOOL)silent;

//Private
- (void)initController;
- (void)closeController;

@end

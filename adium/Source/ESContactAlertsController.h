//
//  ESContactAlertsController.h
//  Adium
//
//  Created by Evan Schoenberg on Wed Nov 26 2003.

@protocol AIEventHandler <NSObject>
- (NSString *)shortDescriptionForEventID:(NSString *)eventID;
- (NSString *)longDescriptionForEventID:(NSString *)eventID;
@end

@protocol AIActionHandler <NSObject>
- (NSString *)shortDescriptionForActionID:(NSString *)actionID;
- (NSString *)longDescriptionForActionID:(NSString *)actionID withDetails:(NSDictionary *)details;
- (NSImage *)imageForActionID:(NSString *)actionID;
- (void)performActionID:(NSString *)actionID forListObject:(AIListObject *)listObject withDetails:(NSDictionary *)details;
- (AIModularPane *)detailsPaneForActionID:(NSString *)actionID;
@end

//Event preferences
#define PREF_GROUP_CONTACT_ALERTS	@"Contact Alerts"
#define KEY_CONTACT_ALERTS			@"Contact Alerts"

//Event Dictionary keys
#define	KEY_EVENT_ID				@"EventID"
#define	KEY_ACTION_ID				@"ActionID"
#define	KEY_ACTION_DETAILS			@"ActionDetails"

@interface ESContactAlertsController : NSObject {
    IBOutlet	AIAdium			*owner;
	
	NSMutableDictionary			*eventHandlers;
	NSMutableDictionary			*actionHandlers;
}

//
- (void)initController;
- (void)closeController;

//Events
- (void)registerEventID:(NSString *)eventID withHandler:(id <AIEventHandler>)handler;
- (NSDictionary *)eventHandlers;
- (NSMenu *)menuOfEventsWithTarget:(id)target;
- (void)generateEvent:(NSString *)eventID forListObject:(AIListObject *)listObject;

//Actions
- (void)registerActionID:(NSString *)actionID withHandler:(id <AIActionHandler>)handler;
- (NSDictionary *)actionHandlers;
- (NSMenu *)menuOfActionsWithTarget:(id)target;

//Alerts
- (NSArray *)alertsForListObject:(AIListObject *)listObject;
- (void)addAlert:(NSDictionary *)alert toListObject:(AIListObject *)listObject;
- (void)removeAlert:(NSDictionary *)victimAlert fromListObject:(AIListObject *)listObject;

@end

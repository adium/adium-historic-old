//
//  ESContactAlertsController.h
//  Adium
//
//  Created by Evan Schoenberg on Wed Nov 26 2003.

@class AIModularPane;

@protocol AIEventHandler <NSObject>
- (NSString *)shortDescriptionForEventID:(NSString *)eventID;
- (NSString *)globalShortDescriptionForEventID:(NSString *)eventID;
- (NSString *)englishGlobalShortDescriptionForEventID:(NSString *)eventID;
- (NSString *)longDescriptionForEventID:(NSString *)eventID forListObject:(AIListObject *)listObject;

- (NSString *)naturalLanguageDescriptionForEventID:(NSString *)eventID
										listObject:(AIListObject *)listObject
										  userInfo:(id)userInfo
									includeSubject:(BOOL)includeSubject;
@end

@protocol AIActionHandler <NSObject>
- (NSString *)shortDescriptionForActionID:(NSString *)actionID;
- (NSString *)longDescriptionForActionID:(NSString *)actionID withDetails:(NSDictionary *)details;
- (NSImage *)imageForActionID:(NSString *)actionID;
- (void)performActionID:(NSString *)actionID forListObject:(AIListObject *)listObject withDetails:(NSDictionary *)details triggeringEventID:(NSString *)eventID userInfo:(id)userInfo;
- (AIModularPane *)detailsPaneForActionID:(NSString *)actionID;
- (BOOL)allowMultipleActionsWithID:(NSString *)actionID;
@end

//Event preferences
#define PREF_GROUP_CONTACT_ALERTS	@"Contact Alerts"
#define KEY_CONTACT_ALERTS			@"Contact Alerts"
#define KEY_DEFAULT_EVENT_ID		@"Default Event ID"
#define KEY_DEFAULT_ACTION_ID		@"Default Action ID"

//Event Dictionary keys
#define	KEY_EVENT_ID				@"EventID"
#define	KEY_ACTION_ID				@"ActionID"
#define	KEY_ACTION_DETAILS			@"ActionDetails"
#define KEY_ONE_TIME_ALERT			@"OneTime"

typedef enum {
	AIContactsEventHandlerGroup = 0,
	AIMessageEventHandlerGroup,
	AIAccountsEventHandlerGroup,
	AIFileTransferEventHandlerGroup,
	AIOtherEventHandlerGroup
} AIEventHandlerGroupType;
#define EVENT_HANDLER_GROUP_COUNT 5

@interface ESContactAlertsController : NSObject {
    IBOutlet	AIAdium			*adium;
	
	NSMutableDictionary			*globalOnlyEventHandlers;
	NSMutableDictionary			*eventHandlers;
	NSMutableDictionary			*actionHandlers;

	NSMutableDictionary			*globalOnlyEventHandlersByGroup[EVENT_HANDLER_GROUP_COUNT];
	NSMutableDictionary			*eventHandlersByGroup[EVENT_HANDLER_GROUP_COUNT];
}

//
- (void)initController;
- (void)closeController;

//Events
- (void)registerEventID:(NSString *)eventID withHandler:(id <AIEventHandler>)handler inGroup:(AIEventHandlerGroupType)inGroup globalOnly:(BOOL)global;
- (NSDictionary *)allEventIDs;
- (NSMenu *)menuOfEventsWithTarget:(id)target forGlobalMenu:(BOOL)global;
- (void)generateEvent:(NSString *)eventID forListObject:(AIListObject *)listObject userInfo:(id)userInfo;
- (NSString *)defaultEventID;
- (NSString *)eventIDForEnglishDisplayName:(NSString *)displayName;
- (NSString *)globalShortDescriptionForEventID:(NSString *)eventID;
- (NSString *)longDescriptionForEventID:(NSString *)eventID forListObject:(AIListObject *)listObject;
- (NSString *)naturalLanguageDescriptionForEventID:(NSString *)eventID
										listObject:(AIListObject *)listObject
										  userInfo:(id)userInfo
									includeSubject:(BOOL)includeSubject;

//Actions
- (void)registerActionID:(NSString *)actionID withHandler:(id <AIActionHandler>)handler;
- (NSDictionary *)actionHandlers;
- (NSMenu *)menuOfActionsWithTarget:(id)target;
- (NSString *)defaultActionID;

//Alerts
- (NSArray *)alertsForListObject:(AIListObject *)listObject;
- (void)addAlert:(NSDictionary *)alert toListObject:(AIListObject *)listObject;
- (void)addGlobalAlert:(NSDictionary *)newAlert;
- (void)removeAlert:(NSDictionary *)victimAlert fromListObject:(AIListObject *)listObject;
- (void)removeAllGlobalAlertsWithActionID:(NSString *)actionID;
- (void)mergeAndMoveContactAlertsFromListObject:(AIListObject *)oldObject intoListObject:(AIListObject *)newObject;


@end

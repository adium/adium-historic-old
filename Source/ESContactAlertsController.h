/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

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
- (NSArray *)allEventIDs;
- (NSMenu *)menuOfEventsWithTarget:(id)target forGlobalMenu:(BOOL)global;
- (NSSet *)generateEvent:(NSString *)eventID forListObject:(AIListObject *)listObject userInfo:(id)userInfo previouslyPerformedActionIDs:(NSSet *)previouslyPerformedActionIDs;
- (NSString *)defaultEventID;
- (NSString *)eventIDForEnglishDisplayName:(NSString *)displayName;
- (NSString *)globalShortDescriptionForEventID:(NSString *)eventID;
- (NSString *)longDescriptionForEventID:(NSString *)eventID forListObject:(AIListObject *)listObject;
- (NSString *)naturalLanguageDescriptionForEventID:(NSString *)eventID
										listObject:(AIListObject *)listObject
										  userInfo:(id)userInfo
									includeSubject:(BOOL)includeSubject;
- (BOOL)isMessageEvent:(NSString *)eventID;

//Actions
- (void)registerActionID:(NSString *)actionID withHandler:(id <AIActionHandler>)handler;
- (NSDictionary *)actionHandlers;
- (NSMenu *)menuOfActionsWithTarget:(id)target;
- (NSString *)defaultActionID;

//Alerts
- (NSArray *)alertsForListObject:(AIListObject *)listObject;
- (NSArray *)alertsForListObject:(AIListObject *)listObject withActionID:(NSString *)actionID;
- (void)addAlert:(NSDictionary *)alert toListObject:(AIListObject *)listObject setAsNewDefaults:(BOOL)setAsNewDefaults;
- (void)addGlobalAlert:(NSDictionary *)newAlert;
- (void)removeAlert:(NSDictionary *)victimAlert fromListObject:(AIListObject *)listObject;
- (void)removeAllGlobalAlertsWithActionID:(NSString *)actionID;
- (void)mergeAndMoveContactAlertsFromListObject:(AIListObject *)oldObject intoListObject:(AIListObject *)newObject;


@end

//
//  ESContactAlert.h
//  Adium
//
//  Created by Evan Schoenberg on Wed Nov 26 2003.

#define PREF_GROUP_ALERTS		@"Alerts"
#define KEY_EVENT_ACTIONSET		@"Contact Actions"	//storage of a set of events and associated actions

#define	KEY_EVENT_NOTIFICATION		@"Notification"  	//event, actually
#define KEY_EVENT_ACTION		@"Action"		//actions to take
#define KEY_EVENT_DETAILS		@"Details"		//details (text, path, etc.)
#define KEY_EVENT_STATUS		@"Status"		//allows for inverse events (came back from away, etc.)
#define KEY_EVENT_DISPLAYNAME		@"Display Name"		//display name of the event
#define KEY_EVENT_DELETE		@"Delete"		//delete after execution?
#define KEY_EVENT_ACTIVE		@"Only While Active"
#define KEY_EVENT_DETAILS_DICT		@"Details Dictionary"	//additional options storage

//An ESContactAlert object is responsible for its details view in the UI, both visually and in terms of storing its action preferences

@interface ESContactAlert : AIObject {

}

+ (id)contactAlert;
- (id)init;
- (NSMenuItem *)alertMenuItem;
- (NSString *)nibName;
//PRIVATE
- (void)setObject:(id)object forKey:(NSString *)key;
- (void)saveEventActionArray;
- (void)configureWithSubview:(NSView *)view;
@end

//
//  AIActionDetailsPane.m
//  Adium
//
//  Created by Adam Iser on Sun Apr 18 2004.
//

#import "AIActionDetailsPane.h"
#import "ESContactAlertsViewController.h"

@implementation AIActionDetailsPane

//Return a new action details pane
+ (AIActionDetailsPane *)actionDetailsPane
{
    return([[[self alloc] init] autorelease]);
}

//Return a new preference pane, passing plugin
+ (AIActionDetailsPane *)actionDetailsPaneForPlugin:(id)inPlugin
{
    return([[[self alloc] initForPlugin:inPlugin] autorelease]);
}

- (void)detailsForHeaderChanged
{
   [[adium notificationCenter] postNotificationName:CONTACT_ALERTS_DETAILS_FOR_HEADER_CHANGED
											 object:self];
}

//For subclasses -------------------------------------------------------------------------------
//
- (void)configureForActionDetails:(NSDictionary *)inDetails listObject:(AIListObject *)inObject
{
	
}

//
- (NSDictionary *)actionDetails
{
	return(nil);
}

@end

//
//  ESOpenMessageWindowContactAlertPlugin.m
//  Adium XCode
//
//  Created by Evan Schoenberg on Sat Nov 29 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "ESOpenMessageWindowContactAlertPlugin.h"
#import "ESOpenMessageWindowContactAlert.h"

@implementation ESOpenMessageWindowContactAlertPlugin
- (void)installPlugin
{
    //Install our contact alert
    [[owner contactAlertsController] registerContactAlertProvider:self];
}

- (void)uninstallPlugin
{
    //Uninstall our contact alert
    [[owner contactAlertsController] unregisterContactAlertProvider:self];
}




//*****
//ESContactAlertProvider
//*****

- (NSString *)identifier
{
    return CONTACT_ALERT_IDENTIFIER;
}

- (ESContactAlert *)contactAlert
{
    return [ESOpenMessageWindowContactAlert contactAlertWithOwner:owner];   
}

//performs an action using the information in details and detailsDict (either may be passed as nil in many cases), returning YES if the action fired and NO if it failed for any reason
- (BOOL)performActionWithDetails:(NSString *)details andDictionary:(NSDictionary *)detailsDict triggeringObject:(AIListObject *)inObject triggeringEvent:(NSString *)event eventStatus:(BOOL)event_status actionName:(NSString *)actionName
{
    BOOL success = YES;
    AIAccount * account = [[owner accountController] accountWithID:details];
    if ([[account propertyForKey:@"Status"] intValue] == STATUS_OFFLINE) { //desired account not available
        if ([[detailsDict objectForKey:KEY_MESSAGE_OTHERACCOUNT] intValue]) { //use another account if necessary pref
            account = [[owner accountController] accountForSendingContentType:CONTENT_MESSAGE_TYPE toListObject:inObject];
        }
        if (!account)
            success = NO;
    }
    if (success) {
        AIChat	*chat = [[owner contentController] openChatOnAccount:account withListObject:inObject];
        [[owner interfaceController] setActiveChat:chat];
    }
    return success;
}

//continue processing after a successful action
- (BOOL)shouldKeepProcessing
{
    return NO;
}
@end

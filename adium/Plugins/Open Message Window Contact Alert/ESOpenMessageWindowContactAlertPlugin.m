//
//  ESOpenMessageWindowContactAlertPlugin.m
//  Adium
//
//  Created by Evan Schoenberg on Sat Nov 29 2003.
//

#import "ESOpenMessageWindowContactAlertPlugin.h"
#import "ESOpenMessageWindowContactAlert.h"

@implementation ESOpenMessageWindowContactAlertPlugin
- (void)installPlugin
{
    //Install our contact alert
    [[adium contactAlertsController] registerContactAlertProvider:self];
}

- (void)uninstallPlugin
{
    //Uninstall our contact alert
    [[adium contactAlertsController] unregisterContactAlertProvider:self];
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
    return [ESOpenMessageWindowContactAlert contactAlert];   
}

//performs an action using the information in details and detailsDict (either may be passed as nil in many cases), returning YES if the action fired and NO if it failed for any reason
- (BOOL)performActionWithDetails:(NSString *)details andDictionary:(NSDictionary *)detailsDict triggeringObject:(AIListObject *)inObject triggeringEvent:(NSString *)event eventStatus:(BOOL)event_status actionName:(NSString *)actionName
{
	BOOL success = YES;

	if([inObject isKindOfClass:[AIListContact class]]){
		AIAccount * account = [[adium accountController] accountWithObjectID:details];
		if (![[account statusObjectForKey:@"Online"] boolValue]) { //desired account not available
			if ([[detailsDict objectForKey:KEY_MESSAGE_OTHERACCOUNT] intValue]) { //use another account if necessary pref
				account = [[adium accountController] preferredAccountForSendingContentType:CONTENT_MESSAGE_TYPE
																			  toListObject:inObject];
			}
			if (!account)
				success = NO;
		}
		if(success){
			AIChat	*chat = [[adium contentController] openChatWithContact:(AIListContact *)inObject];
			[[adium interfaceController] setActiveChat:chat];
		}
	}
	
    return success;
}

//continue processing after a successful action
- (BOOL)shouldKeepProcessing
{
    return NO;
}
@end

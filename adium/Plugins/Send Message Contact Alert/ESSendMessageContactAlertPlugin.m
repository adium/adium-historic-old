//
//  ESSendMessageContactAlertPlugin.m
//  Adium XCode
//
//  Created by Evan Schoenberg on Fri Nov 28 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "ESSendMessageContactAlertPlugin.h"
#import "ESSendMessageContactAlert.h"

@implementation ESSendMessageContactAlertPlugin
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
    return [ESSendMessageContactAlert contactAlertWithOwner:owner];   
}

//performs an action using the information in details and detailsDict (either may be passed as nil in many cases), returning YES if the action fired and NO if it failed for any reason
- (BOOL)performActionWithDetails:(NSString *)details andDictionary:(NSDictionary *)detailsDict triggeringObject:(AIListObject *)inObject triggeringEvent:(NSString *)event eventStatus:(BOOL)event_status actionName:(NSString *)actionName
{
    AIAccount           *account;

    AIContentMessage    *responseContent;
    NSAttributedString  *message;
    
    AIListContact       *contact;
    NSString            *uid;
    NSString            *service;
    
    NSString            *errorReason = nil;
    int                 displayError;
    BOOL                success;

    //Source account
    account = [[owner accountController] accountWithID:[detailsDict objectForKey:KEY_MESSAGE_SENDFROM]];
    
    message = [[[NSAttributedString alloc] initWithString:details] autorelease];

    //intended recipient
    uid = [detailsDict objectForKey:KEY_MESSAGE_SENDTO_UID];
    service = [detailsDict objectForKey:KEY_MESSAGE_SENDTO_SERVICE];
    contact = [[owner contactController] contactInGroup:nil withService:service UID:uid];
    
    //error message
    displayError = [[detailsDict objectForKey:KEY_MESSAGE_ERROR] intValue];

    if ([[owner contentController] availableForSendingContentType:CONTENT_MESSAGE_TYPE toListObject:contact onAccount:account]) { //desired account is available to send to contact
        success = YES;
    } else {
        if ([[detailsDict objectForKey:KEY_MESSAGE_OTHERACCOUNT] intValue]) { //use another account if necessary pref
            account = [[owner accountController] accountForSendingContentType:CONTENT_MESSAGE_TYPE toListObject:contact];
            
            if (!account) {//no appropriate accounts found
                errorReason = @"failed because no appropriate accounts are online.";
                success = NO;
            } else
                success = YES;
        }
        else {
            errorReason = [NSString stringWithFormat:@"with %@ failed because the account %@ is currently offline.",[account accountDescription],[account accountDescription]];
            success = NO;
        }
    }
    if (success) { //we're good so far...
            if ([[contact statusArrayForKey:@"Online"] greatestIntegerValue]) {
                AIChat	*chat = [[owner contentController] openChatOnAccount:account withListObject:contact];
                
                [[owner interfaceController] setActiveChat:chat];
                responseContent = [AIContentMessage messageInChat:chat
                                                       withSource:account
                                                      destination:contact
                                                             date:nil
                                                          message:message
                                                        autoreply:NO];
                success = [[owner contentController] sendContentObject:responseContent];
                
                if (!success)
                    errorReason = @"failed while sending the message.";
            }
            else { //target contact is not online
                errorReason = [NSString stringWithFormat:@"failed because %@ is currently unavailable.",[contact displayName]];
                success = NO;
            }
    }
    
    if (!success && displayError) { //Would have had it if it weren't for those pesky account and contact kids...
        NSString *alertMessage = [NSString stringWithFormat:@"The attempt to send \"%@\" to %@ %@",[message string],[contact displayName],errorReason];
        NSString *title = [NSString stringWithFormat:@"%@ %@", [inObject displayName], actionName];
        [[owner interfaceController] handleMessage:title withDescription:alertMessage withWindowTitle:@"Error Sending Message"];
    }
    
    return success;
}

//continue processing after a successful action
- (BOOL)shouldKeepProcessing
{
    return YES;
}

@end

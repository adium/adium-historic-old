//
//  ESSendMessageContactAlertPlugin.m
//  Adium XCode
//
//  Created by Evan Schoenberg on Fri Nov 28 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "ESSendMessageContactAlertPlugin.h"
#import "ESSendMessageContactAlert.h"

@interface ESSendMessageContactAlertPlugin (PRIVATE)
- (void)preferencesChanged:(NSNotification *)notification;
@end

@implementation ESSendMessageContactAlertPlugin
- (void)installPlugin
{
    //Install our contact alert
    [[adium contactAlertsController] registerContactAlertProvider:self];
    
    attributes = nil;
    
    //Observe preference changes
    [[adium notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    [self preferencesChanged:nil];
}

- (void)uninstallPlugin
{
    //Uninstall our contact alert
    [[adium contactAlertsController] unregisterContactAlertProvider:self];
    
    [attributes release];
}

- (void)dealloc
{
    [attributes release];
    [super dealloc];
}

- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_FORMATTING] == 0){
        NSDictionary		*prefDict;
        NSColor			*textColor;
        NSColor			*backgroundColor;
        NSColor			*subBackgroundColor;
        NSFont			*font;
        
        //Get the prefs
        prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_FORMATTING];
        font = [[prefDict objectForKey:KEY_FORMATTING_FONT] representedFont];
        textColor = [[prefDict objectForKey:KEY_FORMATTING_TEXT_COLOR] representedColor];
        backgroundColor = [[prefDict objectForKey:KEY_FORMATTING_BACKGROUND_COLOR] representedColor];
        subBackgroundColor = [[prefDict objectForKey:KEY_FORMATTING_SUBBACKGROUND_COLOR] representedColor];
        
        [attributes release];
        //Setup the attributes
        if(!subBackgroundColor){
            attributes = [[NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, textColor, NSForegroundColorAttributeName, backgroundColor, AIBodyColorAttributeName, nil] retain];
        }else{
            attributes = [[NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, textColor, NSForegroundColorAttributeName, backgroundColor, AIBodyColorAttributeName, subBackgroundColor, NSBackgroundColorAttributeName, nil] retain];
        }
    }
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
    return [ESSendMessageContactAlert contactAlert];   
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
    BOOL                success = NO;

    //Source account
    account = [[adium accountController] accountWithID:[detailsDict objectForKey:KEY_MESSAGE_SENDFROM]];
    
    message = [[NSAttributedString alloc] initWithString:details attributes:attributes];

    //intended recipient
    uid = [detailsDict objectForKey:KEY_MESSAGE_SENDTO_UID];
    service = [detailsDict objectForKey:KEY_MESSAGE_SENDTO_SERVICE];
    contact = [[adium contactController] contactWithService:service accountUID:[account UID] UID:uid];
    
    //error message
    displayError = [[detailsDict objectForKey:KEY_MESSAGE_ERROR] intValue];

    if ([[adium contentController] availableForSendingContentType:CONTENT_MESSAGE_TYPE toListObject:contact onAccount:account]) { //desired account is available to send to contact
        success = YES;
    } else {
        if ([[detailsDict objectForKey:KEY_MESSAGE_OTHERACCOUNT] intValue]) { //use another account if necessary pref
            account = [[adium accountController] preferredAccountForSendingContentType:CONTENT_MESSAGE_TYPE
																		  toListObject:contact];
            
            if (!account) {//no appropriate accounts found
                errorReason = @"failed because no appropriate accounts are online.";
                success = NO;
            } else
                success = YES;
        }
        else {
            errorReason = [NSString stringWithFormat:@"with %@ failed because the account %@ is currently offline.",[account displayName],[account displayName]];
            success = NO;
        }
    }
    if (success) { //we're good so far...
            if ([[contact statusArrayForKey:@"Online"] intValue]) {
                AIChat	*chat = [[adium contentController] openChatWithContact:contact];
                
                [[adium interfaceController] setActiveChat:chat];
                responseContent = [AIContentMessage messageInChat:chat
                                                       withSource:account
                                                      destination:contact
                                                             date:nil
                                                          message:message
                                                        autoreply:NO];
                success = [[adium contentController] sendContentObject:responseContent];
                
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
        [[adium interfaceController] handleMessage:title withDescription:alertMessage withWindowTitle:@"Error Sending Message"];
    }
    
    [message release];
    return success;
}

//continue processing after a successful action
- (BOOL)shouldKeepProcessing
{
    return YES;
}

@end

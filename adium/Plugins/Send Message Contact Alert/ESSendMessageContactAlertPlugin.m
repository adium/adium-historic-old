//
//  ESSendMessageContactAlertPlugin.m
//  Adium
//
//  Created by Evan Schoenberg on Fri Nov 28 2003.
//

#import "ESSendMessageContactAlertPlugin.h"
#import "ESSendMessageAlertDetailPane.h"

#define SEND_MESSAGE_ALERT_SHORT	@"Send a message"
#define SEND_MESSAGE_ALERT_LONG		@"Send %@ the message \"%@\""

@interface ESSendMessageContactAlertPlugin (PRIVATE)
- (void)preferencesChanged:(NSNotification *)notification;
@end

@implementation ESSendMessageContactAlertPlugin
- (void)installPlugin
{
    //Install our contact alert
	[[adium contactAlertsController] registerActionID:@"SendMessage" withHandler:self];
    
    attributes = nil;
    
    //Observe preference changes
//    [[adium notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
//    [self preferencesChanged:nil];
}

- (void)uninstallPlugin
{
    [attributes release];
}


//Send Message Alert -----------------------------------------------------------------------------------------------------
#pragma mark Send Message Alert
- (NSString *)shortDescriptionForActionID:(NSString *)actionID
{
	return(SEND_MESSAGE_ALERT_SHORT);
}

- (NSString *)longDescriptionForActionID:(NSString *)actionID withDetails:(NSDictionary *)details
{
	NSString		*messageText = [[NSAttributedString stringWithData:[details objectForKey:KEY_MESSAGE_SEND_MESSAGE]] string];
	NSString		*destUniqueID = [details objectForKey:KEY_MESSAGE_SEND_TO];
	AIListContact	*contact = nil;

	if(destUniqueID) contact = (AIListContact *)[[adium contactController] existingListObjectWithUniqueID:destUniqueID];
	return([NSString stringWithFormat:SEND_MESSAGE_ALERT_LONG, [contact displayName], messageText]);
}

- (NSImage *)imageForActionID:(NSString *)actionID
{
	return([NSImage imageNamed:@"MessageAlert" forClass:[self class]]);
}

- (AIModularPane *)detailsPaneForActionID:(NSString *)actionID
{
	return([ESSendMessageAlertDetailPane actionDetailsPane]);
}

- (void)performActionID:(NSString *)actionID forListObject:(AIListObject *)listObject withDetails:(NSDictionary *)details triggeringEventID:(NSString *)eventID userInfo:(id)userInfo
{
	BOOL					success = NO;
	AIAccount				*account;
	NSString				*destUniqueID;
	AIListContact			*contact = nil;
	BOOL					useAnotherAccount;
		
	//Intended source and dest
	account = [[adium accountController] accountWithObjectID:[details objectForKey:KEY_MESSAGE_SEND_FROM]];
	destUniqueID = [details objectForKey:KEY_MESSAGE_SEND_TO];
	if(destUniqueID) contact = (AIListContact *)[[adium contactController] existingListObjectWithUniqueID:destUniqueID];

	//Message to send and other options
	useAnotherAccount = [[details objectForKey:KEY_MESSAGE_OTHER_ACCOUNT] boolValue];

	//If we have a contact (and not a meta contact), we need to make sure it's the contact for account, or 
	//availableForSendingContentType: will return NO incorrectly.
	//######### The core should really handle this for us. #########
	if([contact isKindOfClass:[AIListContact class]]){
		contact = [[adium contactController] existingContactWithService:[contact serviceID]
															  accountID:[account uniqueObjectID]
																	UID:[contact UID]];
	}
	
	//If the desired account is not available for sending, ask Adium for the best available account
	if(![[adium contentController] availableForSendingContentType:CONTENT_MESSAGE_TYPE toListObject:contact onAccount:account]){
		if(useAnotherAccount){
			account = [[adium accountController] preferredAccountForSendingContentType:CONTENT_MESSAGE_TYPE toListObject:contact];
		}else{
			account = nil;
		}
	}
	
	if(account){
		//Find the contact listed on this account (If it's not listed, this will add it as a stranger)
		//######### The core should really handle this for us. #########
		contact = [[adium contactController] contactWithService:[contact serviceID]
													  accountID:[account uniqueObjectID] 
															UID:[contact UID]];
		if(contact){
			//Create and open a chat with this contact
			AIChat					*chat;
			NSAttributedString 		*message;
			
			chat = [[adium contentController] openChatWithContact:contact];
			[[adium interfaceController] setActiveChat:chat];
			
			message = [NSAttributedString stringWithData:[details objectForKey:KEY_MESSAGE_SEND_MESSAGE]];
				
			//Prepare the content object we're sending
			AIContentMessage	*content = [AIContentMessage messageInChat:chat
																withSource:account
															   destination:contact
																	  date:nil
																   message:message
																 autoreply:NO];
			
			//Send the content
			success = [[adium contentController] sendContentObject:content];
		}
			
	}
	
	//Display an error message if the message was not delivered
	if(!success){
        [[adium interfaceController] handleMessage:@"Contact Alert Error"
								   withDescription:[NSString stringWithFormat:@"Unable to send message to %@.", [contact displayName]]
								   withWindowTitle:@""];
	}
}

/*
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
    account = [[adium accountController] accountWithObjectID:[detailsDict objectForKey:KEY_MESSAGE_SENDFROM]];
    
    message = [[NSAttributedString alloc] initWithString:details attributes:attributes];

    //intended recipient
    uid = [detailsDict objectForKey:KEY_MESSAGE_SENDTO_UID];
    service = [detailsDict objectForKey:KEY_MESSAGE_SENDTO_SERVICE];
    contact = [[adium contactController] contactWithService:service accountID:[account uniqueObjectID] UID:uid];
    
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
            if ([contact integerStatusObjectForKey:@"Online"]) {
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
 */










//- (void)preferencesChanged:(NSNotification *)notification
//{
//    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_FORMATTING] == 0){
//        NSDictionary		*prefDict;
//        NSColor			*textColor;
//        NSColor			*backgroundColor;
//        NSColor			*subBackgroundColor;
//        NSFont			*font;
//        
//        //Get the prefs
//        prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_FORMATTING];
//        font = [[prefDict objectForKey:KEY_FORMATTING_FONT] representedFont];
//        textColor = [[prefDict objectForKey:KEY_FORMATTING_TEXT_COLOR] representedColor];
//        backgroundColor = [[prefDict objectForKey:KEY_FORMATTING_BACKGROUND_COLOR] representedColor];
//        subBackgroundColor = [[prefDict objectForKey:KEY_FORMATTING_SUBBACKGROUND_COLOR] representedColor];
//        
//        [attributes release];
//        //Setup the attributes
//        if(!subBackgroundColor){
//            attributes = [[NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, textColor, NSForegroundColorAttributeName, backgroundColor, AIBodyColorAttributeName, nil] retain];
//        }else{
//            attributes = [[NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, textColor, NSForegroundColorAttributeName, backgroundColor, AIBodyColorAttributeName, subBackgroundColor, NSBackgroundColorAttributeName, nil] retain];
//        }
//    }
//}
//*****
//ESContactAlertProvider
//*****

//- (NSString *)identifier
//{
//    return CONTACT_ALERT_IDENTIFIER;
//}
//
//- (ESContactAlert *)contactAlert
//{
//    return [ESSendMessageContactAlert contactAlert];   
//}
//
////performs an action using the information in details and detailsDict (either may be passed as nil in many cases), returning YES if the action fired and NO if it failed for any reason
//- (BOOL)performActionWithDetails:(NSString *)details andDictionary:(NSDictionary *)detailsDict triggeringObject:(AIListObject *)inObject triggeringEvent:(NSString *)event eventStatus:(BOOL)event_status actionName:(NSString *)actionName
//{
//    AIAccount           *account;
//
//    AIContentMessage    *responseContent;
//    NSAttributedString  *message;
//    
//    AIListContact       *contact;
//    NSString            *uid;
//    NSString            *service;
//    
//    NSString            *errorReason = nil;
//    int                 displayError;
//    BOOL                success = NO;
//
//    //Source account
//    account = [[adium accountController] accountWithObjectID:[detailsDict objectForKey:KEY_MESSAGE_SENDFROM]];
//    
//    message = [[NSAttributedString alloc] initWithString:details attributes:attributes];
//
//    //intended recipient
//    uid = [detailsDict objectForKey:KEY_MESSAGE_SENDTO_UID];
//    service = [detailsDict objectForKey:KEY_MESSAGE_SENDTO_SERVICE];
//    contact = [[adium contactController] contactWithService:service accountID:[account uniqueObjectID] UID:uid];
//    
//    //error message
//    displayError = [[detailsDict objectForKey:KEY_MESSAGE_ERROR] intValue];
//
//    if ([[adium contentController] availableForSendingContentType:CONTENT_MESSAGE_TYPE toListObject:contact onAccount:account]) { //desired account is available to send to contact
//        success = YES;
//    } else {
//        if ([[detailsDict objectForKey:KEY_MESSAGE_OTHERACCOUNT] intValue]) { //use another account if necessary pref
//            account = [[adium accountController] preferredAccountForSendingContentType:CONTENT_MESSAGE_TYPE
//																		  toListObject:contact];
//            
//            if (!account) {//no appropriate accounts found
//                errorReason = @"failed because no appropriate accounts are online.";
//                success = NO;
//            } else
//                success = YES;
//        }
//        else {
//            errorReason = [NSString stringWithFormat:@"with %@ failed because the account %@ is currently offline.",[account displayName],[account displayName]];
//            success = NO;
//        }
//    }
//    if (success) { //we're good so far...
//            if ([contact integerStatusObjectForKey:@"Online"]) {
//                AIChat	*chat = [[adium contentController] openChatWithContact:contact];
//                
//                [[adium interfaceController] setActiveChat:chat];
//                responseContent = [AIContentMessage messageInChat:chat
//                                                       withSource:account
//                                                      destination:contact
//                                                             date:nil
//                                                          message:message
//                                                        autoreply:NO];
//                success = [[adium contentController] sendContentObject:responseContent];
//                
//                if (!success)
//                    errorReason = @"failed while sending the message.";
//            }
//            else { //target contact is not online
//                errorReason = [NSString stringWithFormat:@"failed because %@ is currently unavailable.",[contact displayName]];
//                success = NO;
//            }
//    }
//    
//    if (!success && displayError) { //Would have had it if it weren't for those pesky account and contact kids...
//        NSString *alertMessage = [NSString stringWithFormat:@"The attempt to send \"%@\" to %@ %@",[message string],[contact displayName],errorReason];
//        NSString *title = [NSString stringWithFormat:@"%@ %@", [inObject displayName], actionName];
//        [[adium interfaceController] handleMessage:title withDescription:alertMessage withWindowTitle:@"Error Sending Message"];
//    }
//    
//    [message release];
//    return success;
//}
//
////continue processing after a successful action
//- (BOOL)shouldKeepProcessing
//{
//    return YES;
//}

@end

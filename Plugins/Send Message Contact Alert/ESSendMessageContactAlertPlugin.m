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
	account = [[adium accountController] accountWithAccountNumber:[[details objectForKey:KEY_MESSAGE_SEND_FROM] intValue]];
	destUniqueID = [details objectForKey:KEY_MESSAGE_SEND_TO];
	if(destUniqueID) contact = (AIListContact *)[[adium contactController] existingListObjectWithUniqueID:destUniqueID];

	//Message to send and other options
	useAnotherAccount = [[details objectForKey:KEY_MESSAGE_OTHER_ACCOUNT] boolValue];

	//If we have a contact (and not a meta contact), we need to make sure it's the contact for account, or 
	//availableForSendingContentType: will return NO incorrectly.
	//######### The core should really handle this for us. #########
	if([contact isKindOfClass:[AIMetaContact class]]){
		contact = [(AIMetaContact *)contact preferredContactWithService:[account service]];
		
	}else if([contact isKindOfClass:[AIListContact class]]){
		contact = [[adium contactController] contactWithService:[contact service]
														account:account 
															UID:[contact UID]];
	}
	
	//If the desired account is not available for sending, ask Adium for the best available account
	if(![[adium contentController] availableForSendingContentType:CONTENT_MESSAGE_TYPE
														toContact:contact
														onAccount:account]){
		if(useAnotherAccount){
			account = [[adium accountController] preferredAccountForSendingContentType:CONTENT_MESSAGE_TYPE
																			 toContact:contact];
			//Repeat the refinement process using the newly retrieved account
			if([contact isKindOfClass:[AIMetaContact class]]){
				contact = [(AIMetaContact *)contact preferredContactWithService:[account service]];
				
			}else if([contact isKindOfClass:[AIListContact class]]){
				contact = [[adium contactController] contactWithService:[contact service]
																account:account 
																	UID:[contact UID]];
			}
		}else{
			account = nil;
		}
	}
	
	if(account && contact){
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
	
	//Display an error message if the message was not delivered
	if(!success){
        [[adium interfaceController] handleMessage:@"Contact Alert Error"
								   withDescription:[NSString stringWithFormat:@"Unable to send message to %@.", [contact displayName]]
								   withWindowTitle:@""];
	}
}

- (BOOL)allowMultipleActionsWithID:(NSString *)actionID
{
	return(YES);
}

@end

/*
 * Project:     Adium Rendezvous Plugin
 * File:        AWRendezvousAccount.m
 * Author:      Andrew Wellington <proton[at]wiretapped.net>
 *
 * License:
 * Copyright (C) 2004 Andrew Wellington.
 * All rights reserved.
 * 
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation; either version 2 of the License, or (at your
 * option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "AWRendezvousAccount.h"
#import "AWRendezvousPlugin.h"

#import "AWEzv.h"
#import "AWEzvContact.h"
#import "AWEzvDefines.h"

@implementation AWRendezvousAccount
//
- (void)initAccount
{
    [super initAccount];
    libezvContacts = [[NSMutableDictionary dictionary] retain];
    
    libezv = [[AWEzv alloc] initWithClient:self];
}

- (BOOL)disconnectOnFastUserSwitch
{
	return YES;
}

//Return the default properties for this account
- (NSDictionary *)defaultProperties
{
    return([NSDictionary dictionary]);
}

// Return a unique ID specific to THIS account plugin, and the user's account name
- (NSString *)accountID{
    return([self uniqueObjectID]);
}

//The service ID (shared by any account code accessing this service)
- (NSString *)serviceID{
    return(RENDEZVOUS_SERVICE_IDENTIFIER);
}

// Return a readable description of this account's username
- (NSString *)accountDescription
{
    
}

//No need for a password for Rendezvous accounts
- (BOOL)requiresPassword
{
	return NO;
}

- (void)connect
{
    // Say we're connecting...
    [self setStatusObject:[NSNumber numberWithBool:YES] forKey:@"Connecting" notify:YES];

    [libezv setName:[self displayName]];
    [libezv login];
}

- (void)disconnect
{
    // Say we're disconnecting...
    [self setStatusObject:[NSNumber numberWithBool:YES] forKey:@"Disconnecting" notify:YES];
    
    [libezv logout];
}

- (void)removeContacts:(NSArray *)objects
{

}

#pragma mark Libezv Callbacks
// Libezv Callbacks
- (void) reportLoggedIn {
    //We are now online
    [self setStatusObject:[NSNumber numberWithBool:NO] forKey:@"Disconnecting" notify:NO];
    [self setStatusObject:[NSNumber numberWithBool:NO] forKey:@"Connecting" notify:NO];
    [self setStatusObject:[NSNumber numberWithBool:YES] forKey:@"Online" notify:NO];

    //Apply any changes
    [self notifyOfChangedStatusSilently:NO];
}

- (void) reportLoggedOut {
    NSEnumerator *enumerator = [libezvContacts objectEnumerator];
    NSString *uniqueID;
    AIListContact *user;

    while (uniqueID = [enumerator nextObject]) {
	user = [[adium contactController] existingContactWithService:RENDEZVOUS_SERVICE_IDENTIFIER
			accountID:[self uniqueObjectID] UID:uniqueID];
	[user setRemoteGroupName:nil];
    }
    [libezvContacts removeAllObjects];
    
	//We are now offline
    [self setStatusObject:[NSNumber numberWithBool:NO] forKey:@"Disconnecting" notify:NO];
    [self setStatusObject:[NSNumber numberWithBool:NO] forKey:@"Connecting" notify:NO];
    [self setStatusObject:[NSNumber numberWithBool:NO] forKey:@"Online" notify:NO];
	
	//Apply any changes
    [self notifyOfChangedStatusSilently:NO];
}

- (void) userChangedState:(AWEzvContact *)contact {
    AIListContact *user;
       
    user = [[adium contactController] contactWithService:RENDEZVOUS_SERVICE_IDENTIFIER
			accountID:[self uniqueObjectID]
			UID:[contact uniqueID]];  
    //Set the server display name status object as the full display name
    [user setStatusObject:[contact name] forKey:@"Server Display Name" notify:NO];
    [[user displayArrayForKey:@"Display Name"] setObject:[[contact name] stringWithEllipsisByTruncatingToLength:25] 
					       withOwner:self
					   priorityLevel:Lowest_Priority];;

    [user setRemoteGroupName:AILocalizedString(@"Rendezvous", @"Rendezvous group name")];
    [user setStatusObject:[contact statusMessage] forKey:@"StatusMessageString" notify:NO];

     //[user setStatusObject:nil forKey:@"StatusMessage" notify:NO];
    
    switch ([contact status]) {
	case AWEzvOnline:
	    [user setStatusObject:[NSNumber numberWithBool:YES] forKey:@"Online" notify:NO];
	    break;
	case AWEzvAway:
	    [user setStatusObject:[NSNumber numberWithBool:YES] forKey:@"Away" notify:NO];
	    break;
	case AWEzvIdle:
	    [user setStatusObject:[NSNumber numberWithBool:YES] forKey:@"Away" notify:NO];
	    break;
	default:
	    [user setStatusObject:[NSNumber numberWithBool:YES] forKey:@"Online" notify:NO];
    }
    
    if ([contact idleSinceDate])
	[user setStatusObject:[contact idleSinceDate] forKey:@"IdleSince" notify:NO];
    else
	[user setStatusObject:nil forKey:@"IdleSince" notify:NO];

    if ([contact statusMessage])
	[user setStatusObject:[[[NSAttributedString alloc] initWithString:[contact statusMessage]] autorelease]
		       forKey:@"StatusMessage" notify:NO];

    
    [[adium contactController] listObjectAttributesChanged:user 
			       modifiedKeys:[NSArray arrayWithObject:@"Display Name"]];
			
    [libezvContacts setObject:[contact uniqueID] forKey:[contact uniqueID]];   

    //Apply any changes
    [user notifyOfChangedStatusSilently:silentAndDelayed];
}

- (void) userLoggedOut:(AWEzvContact *)contact
{
    AIListContact *user;
    
    user = [[adium contactController] existingContactWithService:RENDEZVOUS_SERVICE_IDENTIFIER
			accountID:[self uniqueObjectID] UID:[contact uniqueID]];
    
    [user setRemoteGroupName:nil];
    [libezvContacts removeObjectForKey:[contact uniqueID]];
}

- (void) user:(AWEzvContact *)contact sentMessage:(NSString *)message withHtml:(NSString *)html
{
    AIListContact *user;
    AIContentMessage *msgObj;
    
    user = [[adium contactController] existingContactWithService:RENDEZVOUS_SERVICE_IDENTIFIER
			accountID:[self uniqueObjectID] UID:[contact uniqueID]];

    msgObj = [AIContentMessage messageInChat:[[adium contentController] chatWithContact:user initialStatus:nil]
				  withSource:user destination:self date:nil
				     message:[AIHTMLDecoder decodeHTML:html]
				   autoreply:NO];
    
    [[adium contentController] receiveContentObject:msgObj];
}
- (void) user:(AWEzvContact *)contact typingNotification:(AWEzvTyping)typingStatus
{
    AIListContact *user;
    
    user = [[adium contactController] existingContactWithService:RENDEZVOUS_SERVICE_IDENTIFIER
			accountID:[self uniqueObjectID] UID:[contact uniqueID]];
			
    [user setStatusObject:[NSNumber numberWithBool:(typingStatus == AWEzvIsTyping)]
					    forKey:@"Typing"
					    notify:NO];
    
    //Apply any changes
    [user notifyOfChangedStatusSilently:silentAndDelayed];
}

- (void) user:(AWEzvContact *)contact typeAhead:(NSString *)message withHtml:(NSString *)html {
/* unimplemented in libezv at this stage */
}

- (void) user:(AWEzvContact *)contact sentFile:(NSString *)filename size:(size_t)size cookie:(int)cookie
{
/* sorry, no file transfer in libezv at the moment */
}

- (void) reportError:(NSString *)error ofLevel:(AWEzvErrorSeverity)severity
{

}

- (void) reportError:(NSString *)error ofLevel:(AWEzvErrorSeverity)severity forUser:(NSString *)contact
{

}

#pragma mark AIAccount Messaging
// AIAccount_Messaging ---------------------------------------------------------------------------
// Send a content object
- (BOOL)sendContentObject:(AIContentObject *)object
{
    if([[object type] isEqualToString:CONTENT_MESSAGE_TYPE]) {
		NSString	*message = [[(AIContentMessage *)object message] string];
		NSString	*htmlMessage = [AIHTMLDecoder encodeHTML:[(AIContentMessage *)object message]
													 headers:NO
													fontTags:YES
										  includingColorTags:YES
											   closeFontTags:YES
												   styleTags:YES
								  closeStyleTagsOnFontChange:YES
											  encodeNonASCII:YES
												  imagesPath:nil
										   attachmentsAsText:YES
							  attachmentImagesOnlyForSending:NO
											  simpleTagsOnly:NO];
		
		AIChat			*chat = [(AIContentMessage *)object chat];
		AIListObject    *listObject = [chat listObject];
		NSString		*to = [listObject UID];
		
		[libezv sendMessage:message 
						 to:to 
				   withHtml:htmlMessage];
		
    } else if([[object type] isEqualToString:CONTENT_TYPING_TYPE]) {
		AIContentTyping *contentTyping = (AIContentTyping*)object;
		AIChat			*chat = [contentTyping chat];
		AIListObject    *listObject = [chat listObject];
		NSString		*to = [listObject UID];
		
		[libezv sendTypingNotification:([contentTyping typing] ? AWEzvIsTyping : AWEzvNotTyping)
									to:to];
    }
}

//Return YES if we're available for sending the specified content.  If inListObject is NO, we can return YES if we will 'most likely' be able to send the content.
- (BOOL)availableForSendingContentType:(NSString *)inType toListObject:(AIListObject *)inListObject
{
    if([inType isEqualToString:CONTENT_MESSAGE_TYPE]){
		return(YES);
    }
    
    return NO;
}

//Initiate a new chat
- (BOOL)openChat:(AIChat *)chat
{
    return(YES);
}

//Close a chat instance
- (BOOL)closeChat:(AIChat *)inChat
{
    return(YES);
}

#pragma mark Account Status
//Respond to account status changes
- (void)updateStatusForKey:(NSString *)key
{
    [super updateStatusForKey:key];
    
    BOOL    areOnline = [[self statusObjectForKey:@"Online"] boolValue];
    
    //Now look at keys which only make sense while online
    if(areOnline){
        NSData  *data;
        if([key isEqualToString:@"IdleSince"]){
            NSDate	*idleSince = [self preferenceForKey:@"IdleSince" group:GROUP_ACCOUNT_STATUS];
			
			[libezv setStatus:AWEzvIdle withMessage:[self preferenceForKey:@"AwayMessage" group:GROUP_ACCOUNT_STATUS]];
            [self setAccountIdleTo:idleSince];
			
        } else if ( ([key isEqualToString:@"AwayMessage"])){
            NSAttributedString	*attributedString = nil;
            
            if(data = [self preferenceForKey:key group:GROUP_ACCOUNT_STATUS]){
                attributedString = [NSAttributedString stringWithData:data];
            }
            
	    if (attributedString != nil)
		[libezv setStatus:AWEzvAway withMessage:[attributedString string]];
	    else
		[libezv setStatus:AWEzvOnline withMessage:nil];
	    
	    [self setStatusObject:[NSNumber numberWithBool:(attributedString != nil)] forKey:@"Away" notify:YES];
	    [self setStatusObject:attributedString forKey:@"StatusMessage" notify:YES];
        }
    }
}

- (void)setAccountIdleTo:(NSDate *)idle
{
	[libezv setIdleTime:idle];

	//We are now idle
	[self setStatusObject:idle forKey:@"IdleSince" notify:YES];
}

//Status keys this account supports
- (NSArray *)supportedPropertyKeys
{
	static NSArray *supportedPropertyKeys = nil;
	
	if (!supportedPropertyKeys)
		supportedPropertyKeys = [[NSArray alloc] initWithObjects:
        @"Display Name",
        @"Online",
        @"Offline",
	@"IdleSince",
	@"IdleManuallySet",
//      KEY_USER_ICON,
        @"Away",
        @"AwayMessage",
//      @"TextProfile",
//      KEY_USER_ICON,
//      @"DefaultUserIconFilename",
        nil];
	
	return supportedPropertyKeys;
}

//Update all our status keys
- (void)updateAllStatusKeys
{
    [self updateStatusForKey:@"IdleSince"];
    [self updateStatusForKey:@"TextProfile"];
    [self updateStatusForKey:@"AwayMessage"];
    [self updateStatusForKey:KEY_USER_ICON];
}


@end
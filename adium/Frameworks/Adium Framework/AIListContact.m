/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2004, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
 | This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 | General Public License as published by the Free Software Foundation; either version 2 of the License,
 | or (at your option) any later version.
 |
 | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 | Public License for more details.
 |
 | You should have received a copy of the GNU General Public License along with this program; if not,
 | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 \------------------------------------------------------------------------------------------------------ */

#import "AIListContact.h"
#import "AIContentMessage.h"
#import "ESFileTransfer.h"

#define CONTENT_OBJECT_SCROLLBACK	5  //Number of content object that say in the scrollback

@implementation AIListContact

- (id)initWithUID:(NSString *)inUID accountID:(NSString *)inAccountID serviceID:(NSString *)inServiceID
{
    [self initWithUID:inUID serviceID:inServiceID];

	accountID = [inAccountID retain];

    return(self);
}

- (id)initWithUID:(NSString *)inUID serviceID:(NSString *)inServiceID
{
	[super initWithUID:inUID serviceID:inServiceID];

	accountID = nil;
	remoteGroupName = nil;
    ultraUniqueObjectID = nil;
	
	return(self);
}

- (void)dealloc
{
	[accountID release];
    [remoteGroupName release];
    [ultraUniqueObjectID release];
	
    [super dealloc];
}

//
- (NSString *)accountID
{
	return(accountID);
}

- (AIAccount *)account
{
	return([[adium accountController] accountWithObjectID:[self accountID]]);
}

- (NSString *)ultraUniqueObjectID
{
	if (!ultraUniqueObjectID){
		if (accountID){
			ultraUniqueObjectID = [[[self uniqueObjectID] stringByAppendingString:accountID] retain];
		}else{
			ultraUniqueObjectID = [[self uniqueObjectID] retain];
		}
	}
	
	return (ultraUniqueObjectID);
}

//Remote Grouping ------------------------------------------------------------------------------------------------------
#pragma mark Remote Grouping
//Set the desired group for this contact.  Pass nil to indicate this object is no longer listed.
- (void)setRemoteGroupName:(NSString *)inName
{
//	NSString	*oldGroupName = remoteGroupName;
//
//	if(inName != nil || oldGroupName != nil){ //If both are nil, we can skip this operation
		//Change it here
	[remoteGroupName autorelease];
	remoteGroupName = [inName retain];
	
	//Tell core it changed
	[[adium contactController] listObjectRemoteGroupingChanged:self];
//
//		[oldGroupName release];
//	}
}

- (NSString *)remoteGroupName
{
	return(remoteGroupName);
}


#pragma mark Applescript Commands
- (id)sendScriptCommand:(NSScriptCommand *)command {
	NSDictionary	*evaluatedArguments = [command evaluatedArguments];
	NSString		*message = [evaluatedArguments objectForKey:@"message"];
	AIAccount		*account = [evaluatedArguments objectForKey:@"account"];
	NSString		*filePath = [evaluatedArguments objectForKey:@"filePath"];
	
	AIListContact   *targetMessagingContact = nil;
	AIListContact   *targetFileTransferContact = nil;

	if (account){
		targetMessagingContact = [[adium contactController] contactOnAccount:account
															 fromListContact:self];
		targetFileTransferContact = targetMessagingContact;
	}
	
	//Send any message we were told to send
	if (message && [message length]){
		AIChat			*chat;
		BOOL			autoreply = [[evaluatedArguments objectForKey:@"autoreply"] boolValue];
		
		//Make sure we know where we are sending the message - if we don't have a target yet, find the best contact for
		//sending CONTENT_MESSAGE_TYPE.
		if (!targetMessagingContact){
			//Get the target contact.  This could be the same contact, an identical contact on another account, 
			//or a subcontact (if we're talking about a metaContact, for example)
			targetMessagingContact = [[adium contactController] preferredContactForContentType:CONTENT_MESSAGE_TYPE
																				forListContact:self];
			account = [targetMessagingContact account];	
		}
		
		chat = [[adium contentController] openChatWithContact:targetMessagingContact];
		
		//Take the string and turn it into an attributed string (in case we were passed HTML)
		NSAttributedString  *attributedMessage = [AIHTMLDecoder decodeHTML:message];
		AIContentMessage	*messageContent;
		messageContent = [AIContentMessage messageInChat:chat
											  withSource:account
											 destination:targetMessagingContact
													date:nil
												 message:attributedMessage
											   autoreply:autoreply];
		
		[[adium contentController] sendContentObject:messageContent];
	}
	
	//Send any file we were told to send
	if (filePath && [filePath length]){
		//Make sure we know where we are sending the file - if we don't have a target yet, find the best contact for
		//sending FILE_TRANSFER_TYPE.
		if (!targetFileTransferContact){
			//Get the target contact.  This could be the same contact, an identical contact on another account, 
			//or a subcontact (if we're talking about a metaContact, for example)
			targetFileTransferContact = [[adium contactController] preferredContactForContentType:FILE_TRANSFER_TYPE
																				   forListContact:self];
		}
		
		[[adium fileTransferController] sendFile:filePath toListContact:targetFileTransferContact];
	}
		
	return nil;
}

@end

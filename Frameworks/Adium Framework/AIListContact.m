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

@implementation AIListContact

//Init with an account
- (id)initWithUID:(NSString *)inUID account:(AIAccount *)inAccount service:(AIService *)inService
{
    [self initWithUID:inUID service:inService];
	
	account = [inAccount retain];
	
    return(self);
}

//Standard init
- (id)initWithUID:(NSString *)inUID service:(AIService *)inService
{
	[super initWithUID:inUID service:inService];

	account = nil;
	remoteGroupName = nil;
	internalUniqueObjectID = nil;
	
	return(self);
}

//Dealloc
- (void)dealloc
{
	[account release]; account = nil;
    [remoteGroupName release]; remoteGroupName = nil;
    [internalUniqueObjectID release]; internalUniqueObjectID = nil;
	
    [super dealloc];
}

//The account that owns this contact
- (AIAccount *)account
{
	return(account);
}

//An object ID generated by Adium that is completely unique to this contact.  This ID is generated from the service ID, 
//UID, and account UID.  Adium will not allow multiple contacts with the same internalUniqueObjectID to be created.
- (NSString *)internalUniqueObjectID
{
	if(!internalUniqueObjectID){
		internalUniqueObjectID = [[AIListContact internalUniqueObjectIDForService:[self service]
																		  account:[self account]
																			  UID:[self UID]] retain];
	}
	return(internalUniqueObjectID);
}

//Generate a unique object ID for the passed object
+ (NSString *)internalUniqueObjectIDForService:(AIService *)inService account:(AIAccount *)inAccount UID:(NSString *)inUID
{
	return([NSString stringWithFormat:@"%@.%@.%@", [inService serviceClass], [inAccount UID], inUID]);
}


//Remote Grouping ------------------------------------------------------------------------------------------------------
#pragma mark Remote Grouping
//Set the desired group for this contact.  Pass nil to indicate this object is no longer listed.
- (void)setRemoteGroupName:(NSString *)inName
{
	//Autorelease so we don't have to worry about whether (remoteGroupName == inName) or not
	[remoteGroupName autorelease];
	remoteGroupName = [inName retain];
	
	[[adium contactController] listObjectRemoteGroupingChanged:self];
}

//The current desired group of this contact
- (NSString *)remoteGroupName
{
	return(remoteGroupName);
}

//An AIListContact normally groups based on its remoteGroupName (if it is not within a metaContact). 
//Restore this grouping.
- (void)restoreGrouping
{
	[[adium contactController] listObjectRemoteGroupingChanged:self];
}

//A listContact is a stranger if it has a nil remoteGroupName
- (BOOL)isStranger
{
	return([self integerStatusObjectForKey:@"Stranger"]);
}


//Applescript ----------------------------------------------------------------------------------------------------------
#pragma mark Applescript
- (id)sendScriptCommand:(NSScriptCommand *)command {
	NSDictionary	*evaluatedArguments = [command evaluatedArguments];
	NSString		*message = [evaluatedArguments objectForKey:@"message"];
	AIAccount		*targetAccount = [evaluatedArguments objectForKey:@"account"];
	NSString		*filePath = [evaluatedArguments objectForKey:@"filePath"];
	
	AIListContact   *targetMessagingContact = nil;
	AIListContact   *targetFileTransferContact = nil;

	if (targetAccount){
		targetMessagingContact = [[adium contactController] contactOnAccount:targetAccount
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
			targetAccount = [targetMessagingContact account];	
		}
		
		chat = [[adium contentController] openChatWithContact:targetMessagingContact];
		
		//Take the string and turn it into an attributed string (in case we were passed HTML)
		NSAttributedString  *attributedMessage = [AIHTMLDecoder decodeHTML:message];
		AIContentMessage	*messageContent;
		messageContent = [AIContentMessage messageInChat:chat
											  withSource:targetAccount
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

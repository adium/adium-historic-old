//
//  ESFileTransferMessagesPlugin.m
//  Adium
//
//  Created by Evan Schoenberg on 9/23/04.
//  Copyright 2004 The Adium Team. All rights reserved.
//

#import "ESFileTransferMessagesPlugin.h"

@interface ESFileTransferMessagesPlugin (PRIVATE)
- (void)statusMessage:(NSString *)message forContact:(AIListContact *)contact withType:(NSString *)type;
@end

@implementation ESFileTransferMessagesPlugin

- (void)installPlugin
{
	//Install our observers
    [[adium notificationCenter] addObserver:self 
								   selector:@selector(handleFleTransferEvent:) 
									   name:FILE_TRANSFER_CANCELED 
									 object:nil];

	[[adium notificationCenter] addObserver:self 
								   selector:@selector(handleFleTransferEvent:) 
									   name:FILE_TRANSFER_COMPLETE 
									 object:nil];
	
	[[adium notificationCenter] addObserver:self 
								   selector:@selector(handleFleTransferEvent:) 
									   name:FILE_TRANSFER_BEGAN 
									 object:nil];
}

- (void)uninstallPlugin
{
	[[adium notificationCenter] removeObserver:self];
}

- (void)handleFleTransferEvent:(NSNotification *)notification
{
	ESFileTransfer	*fileTransfer = (ESFileTransfer *)[notification userInfo];
	AIListContact	*listContact = [notification object];
	NSString		*message = nil;
	NSString		*type = nil;
	
	NSString		*filename = [[fileTransfer localFilename] lastPathComponent];
	
	if ([[notification name] isEqualToString:FILE_TRANSFER_CANCELED]){
		type = @"file_transfer_canceled";
		message = [NSString stringWithFormat:AILocalizedString(@"%@ canceled the transfer of %@",nil),[listContact formattedUID],filename];
		
	}else if ([[notification name] isEqualToString:FILE_TRANSFER_COMPLETE]){
		type = @"file_transfer_complete";
		if ([fileTransfer type] == Incoming_FileTransfer){
			message = [NSString stringWithFormat:AILocalizedString(@"Successfully received %@",nil),filename];
		}else{
			message = [NSString stringWithFormat:AILocalizedString(@"Successfully sent %@",nil),filename];			
		}
		
	}else if ([[notification name] isEqualToString:FILE_TRANSFER_BEGAN]){
		type = @"file_transfer_began";
		if ([fileTransfer type] == Incoming_FileTransfer){
			message = [NSString stringWithFormat:AILocalizedString(@"Began receiving %@",nil),filename];
		}else{
			message = [NSString stringWithFormat:AILocalizedString(@"Began sending %@",nil),filename];			
		}
	}
	
	[self statusMessage:message forContact:listContact withType:type];
}

//Post a status message on all active chats for this object
- (void)statusMessage:(NSString *)message forContact:(AIListContact *)contact withType:(NSString *)type
{
    NSEnumerator		*enumerator;
    AIChat				*chat;
	NSAttributedString	*attributedMessage = [[[NSAttributedString alloc] initWithString:message
																			  attributes:[[adium contentController] defaultFormattingAttributes]] autorelease];
	
    enumerator = [[[adium contentController] allChatsWithContact:contact] objectEnumerator];
    while((chat = [enumerator nextObject])){
        AIContentStatus	*content;
		
        //Create our content object
        content = [AIContentStatus statusInChat:chat
                                     withSource:contact
                                    destination:[chat account]
                                           date:[NSDate date]
                                        message:attributedMessage
									   withType:type];
		
        //Add the object
        [[adium contentController] receiveContentObject:content];
    }
}

@end

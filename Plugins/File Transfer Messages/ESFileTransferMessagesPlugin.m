/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "AIContentController.h"
#import "ESFileTransferMessagesPlugin.h"
#import <Adium/AIChat.h>
#import <Adium/AIContentStatus.h>
#import <Adium/AIListContact.h>
#import <Adium/ESFileTransfer.h>

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
	NSAttributedString	*attributedMessage = [[NSAttributedString alloc] initWithString:message
																			attributes:[[adium contentController] defaultFormattingAttributes]];
	
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
	
	[attributedMessage release];
}

@end

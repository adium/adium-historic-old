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

#import "AINewMessagePromptController.h"

#define NEW_MESSAGE_PROMPT_NIB	@"NewMessagePrompt"

static AINewMessagePromptController *sharedNewMessageInstance = nil;

@implementation AINewMessagePromptController

+ (id)sharedInstance 
{
	return sharedNewMessageInstance;
}

+ (id)createSharedInstance 
{
	sharedNewMessageInstance = [[self alloc] initWithWindowNibName:NEW_MESSAGE_PROMPT_NIB];
	
	return sharedNewMessageInstance;
}

+ (void)destroySharedInstance 
{
	[sharedNewMessageInstance autorelease]; sharedNewMessageInstance = nil;
}

//New Message
- (IBAction)okay:(id)sender
{
	AIListContact	*contact;
	
    if(contact = [self contactFromTextField]){
        //Initiate the message
        [[adium interfaceController] setActiveChat:[[adium contentController] openChatWithContact:contact]];
		
		//Close the prompt
        [[self class] closeSharedInstance];
    }
}

@end

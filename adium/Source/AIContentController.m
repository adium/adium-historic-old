/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2003, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

#import "AIContentController.h"
#import "AIAdium.h"
#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>

@implementation AIContentController

//init
- (void)initController
{
    outgoingContentFilterArray = [[NSMutableArray alloc] init];
    incomingContentFilterArray = [[NSMutableArray alloc] init];
    displayingContentFilterArray = [[NSMutableArray alloc] init];
    textEntryFilterArray = [[NSMutableArray alloc] init];
    chatArray = [[NSMutableArray alloc] init];

    [owner registerEventNotification:Content_DidReceiveContent displayName:@"Message Received"];
    [owner registerEventNotification:Content_DidSendContent displayName:@"Message Sent"];
}

- (void)closeController
{

}

//dealloc
- (void)dealloc
{
    [chatArray release];
    [outgoingContentFilterArray release];
    [incomingContentFilterArray release];
    [textEntryFilterArray release];
    [super dealloc];
}

// Content Handlers--
- (void)registerDefaultHandler:(id <AIContentHandler>)inHandler forContentType:(NSString *)inType
{

}

- (void)invokeDefaultHandlerForObject:(AIContentObject *)inObject
{


}


// Text Entry Filters--
- (void)registerTextEntryFilter:(id <AITextEntryFilter>)inFilter
{
    [textEntryFilterArray addObject:inFilter];
}

- (void)stringAdded:(NSString *)inString toTextEntryView:(NSText<AITextEntryView> *)inTextEntryView
{
    NSEnumerator		*enumerator;
    id <AITextEntryFilter>	filter;

    enumerator = [textEntryFilterArray objectEnumerator];
    while((filter = [enumerator nextObject])){
        [filter stringAdded:inString toTextEntryView:inTextEntryView];
    }
}

- (void)contentsChangedInTextEntryView:(NSText<AITextEntryView> *)inTextEntryView
{
    NSEnumerator		*enumerator;
    id <AITextEntryFilter>	filter;

    enumerator = [textEntryFilterArray objectEnumerator];
    while((filter = [enumerator nextObject])){
        [filter contentsChangedInTextEntryView:inTextEntryView];
    }
}

- (void)initTextEntryView:(NSText<AITextEntryView> *)inTextEntryView
{
    NSEnumerator		*enumerator;
    id <AITextEntryFilter>	filter;

    enumerator = [textEntryFilterArray objectEnumerator];
    while((filter = [enumerator nextObject])){
        [filter initTextEntryView:inTextEntryView];
    }
}


//Content Filters--
- (void)registerOutgoingContentFilter:(id <AIContentFilter>)inFilter 
{
    [outgoingContentFilterArray addObject:inFilter];
}

- (void)registerIncomingContentFilter:(id <AIContentFilter>)inFilter
{
    [incomingContentFilterArray addObject:inFilter];
}

- (void)registerDisplayingContentFilter:(id <AIContentFilter>)inFilter
{
    [displayingContentFilterArray addObject:inFilter];
}


// Messaging --------------------------------------------------------------------------------
//Add a message object to a handle
- (void)addIncomingContentObject:(AIContentObject *)inObject
{
    AIChat		*chat = [inObject chat];
    AIListObject 	*object = [inObject source];
    BOOL		trackContent = [inObject trackContent];	//Adium should track this content
    BOOL		filterContent = [inObject filterContent]; //Adium should filter this content
    BOOL		displayContent = [inObject displayContent]; //Adium should filter this content

    if(object){
        //Will receive content
        if(trackContent){
            [[owner notificationCenter] postNotificationName:Content_WillReceiveContent object:chat userInfo:[NSDictionary dictionaryWithObjectsAndKeys:inObject,@"Object",nil]];
        }

        //Filter the object
        if(filterContent){
            NSEnumerator		*enumerator;
            id<AIContentFilter>		filter;

            enumerator = [incomingContentFilterArray objectEnumerator];
            while((filter = [enumerator nextObject])){
                [filter filterContentObject:inObject];
            }
            
        }

        //Add/Display the object
        if(displayContent){
	    [self displayContentObject:inObject];
        }

        if(trackContent){
            //Did receive content
            [[owner notificationCenter] postNotificationName:Content_DidReceiveContent object:chat userInfo:[NSDictionary dictionaryWithObjectsAndKeys:inObject, @"Object", nil]];
        }
    }
}

//Send a message object to a handle
- (BOOL)sendContentObject:(AIContentObject *)inObject
{
    AIChat		*chat = [inObject chat];
    BOOL		sent = NO;
    BOOL		trackContent = [inObject trackContent];	//Adium should track this content
    BOOL		filterContent = [inObject filterContent]; //Adium should filter this content
    BOOL		displayContent = [inObject displayContent]; //Adium should filter this content
    
    //Will send content
    if(trackContent){
        [[owner notificationCenter] postNotificationName:Content_WillSendContent object:chat userInfo:[NSDictionary dictionaryWithObjectsAndKeys:inObject,@"Object",nil]];
    }

    //Filter the content object
    if(filterContent){
        NSEnumerator	*enumerator;
        id<AIContentFilter>	filter;
        
        enumerator = [outgoingContentFilterArray objectEnumerator];
        while((filter = [enumerator nextObject])){
            [filter filterContentObject:inObject];
        }
    }

    //Send the object
    if([(AIAccount <AIAccount_Content> *)[inObject source] sendContentObject:inObject]){
        if(displayContent){
            //Add the object
            [self displayContentObject:inObject];
            //[chat addContentObject:inObject];
        }

        if(trackContent){
            //Did send content
            [[owner notificationCenter] postNotificationName:Content_DidSendContent object:chat userInfo:[NSDictionary dictionaryWithObjectsAndKeys:inObject,@"Object",nil]];
        }

        sent = YES;
    }

    return(sent);
}

- (void)displayContentObject:(AIContentObject *)inObject
{
    AIChat		*chat = [inObject chat];
    BOOL		filterContent = [inObject filterContent]; //Adium should filter this content

    //Filter the content object
    if(filterContent){
        NSEnumerator	*enumerator;
        id<AIContentFilter>	filter;

        enumerator = [displayingContentFilterArray objectEnumerator];
        while((filter = [enumerator nextObject])){
            [filter filterContentObject:inObject];
        }
    }
    
    //Add the object
    [chat addContentObject:inObject];

    //Content object added
    [[owner notificationCenter] postNotificationName:Content_ContentObjectAdded object:chat userInfo:[NSDictionary dictionaryWithObjectsAndKeys:inObject,@"Object",nil]];
}

//Is an account/chat available for sending content?
- (BOOL)availableForSendingContentType:(NSString *)inType toListObject:(AIListObject *)inListObject onAccount:(AIAccount *)inAccount 
{
    if([inAccount conformsToProtocol:@protocol(AIAccount_Content)]){
        return([(AIAccount <AIAccount_Content> *)inAccount availableForSendingContentType:inType toListObject:inListObject]);
    }else{
        return(NO);
    }
}


//Chats -------------------------------------------------------------------------------------------------
//Open a chat on the specified account, or returns an existing chat
- (AIChat *)openChatOnAccount:(AIAccount *)inAccount withListObject:(AIListObject *)inListObject
{
    NSEnumerator	*enumerator;
    AIChat		*chat;
    
    //Search for an existing chat
    enumerator = [chatArray objectEnumerator];
    while(chat = [enumerator nextObject]){
        if([chat listObject] == inListObject) break;
    }

    if(!chat){
        //If no account is passed, use the default
        if(!inAccount){
            inAccount = [[owner accountController] accountForSendingContentType:CONTENT_MESSAGE_TYPE toListObject:inListObject];
        }

        //Instruct the account to open the new chat
        chat = [(id <AIAccount_Content>)inAccount openChatWithListObject:inListObject];

    }else{
        //Have the interface re-open this chat
        [[owner interfaceController] openChat:chat];    

    }

    return(chat);
}

//Note a chat (Called by account code only, after creating a chat)
- (void)noteChat:(AIChat *)inChat forAccount:(AIAccount *)inAccount
{
    //Track the chat
    [chatArray addObject:inChat];    

    //Have the interface open this chat
    [[owner interfaceController] openChat:inChat];    
}

//Close a chat
- (BOOL)closeChat:(AIChat *)inChat
{
    //Notify the account, and remove the chat
    [(AIAccount<AIAccount_Content> *)[inChat account] closeChat:inChat];
    [chatArray removeObject:inChat];

    //Remove all content from the chat
    [inChat removeAllContent];

    return(YES);
}

//Returns all chats w/ the object
- (NSArray *)allChatsWithListObject:(AIListObject *)inObject
{
    NSMutableArray	*foundChats = [NSMutableArray array];
    NSEnumerator	*chatEnumerator;
    AIChat		*chat;

    chatEnumerator = [chatArray objectEnumerator];
    while((chat = [chatEnumerator nextObject])){
        NSEnumerator	*objectEnumerator;
        AIListObject	*object;

        objectEnumerator = [[chat participatingListObjects] objectEnumerator];
        while((object = [objectEnumerator nextObject])){
            if(object == inObject){
                [foundChats addObject:chat];
            }

        }
    }

    return(foundChats);
}

@end

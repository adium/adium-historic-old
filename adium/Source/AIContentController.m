/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2002, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

    [owner registerEventNotification:Content_DidReceiveContent displayName:@"Message Received"];
    [owner registerEventNotification:Content_DidSendContent displayName:@"Message Sent"];
}

- (void)closeController
{

}

//dealloc
- (void)dealloc
{    
    [super dealloc];
}

// Content Handlers--
- (void)registerDefaultHandler:(id <AIContentHandler>)inHandler forContentType:(NSString *)inType
{

}

- (void)invokeDefaultHandlerForObject:(id <AIContentObject>)inObject
{


}


// Text Entry Filters--
- (void)registerTextEntryFilter:(id <AITextEntryFilter>)inFilter
{
    [textEntryFilterArray addObject:inFilter];
}

/*- (NSArray *)textEntryFilters
{
    return(textEntryFilterArray);
}*/

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






//Content Filters--
- (void)registerOutgoingContentFilter:(id <AIContentFilter>)inFilter 
{
    [outgoingContentFilterArray addObject:inFilter];
}

- (void)registerIncomingContentFilter:(id <AIContentFilter>)inFilter
{
    [incomingContentFilterArray addObject:inFilter];
}



// Messaging --------------------------------------------------------------------------------
//Add a message object to a handle
- (void)addIncomingContentObject:(id <AIContentObject>)inObject
{
    AIHandle		*handle = [inObject source];
    AIListContact 	*contact = [handle containingContact];

    if(contact){
        NSEnumerator		*enumerator;
        id<AIContentFilter>	filter;

        //Will receive content
        [[owner notificationCenter] postNotificationName:Content_WillReceiveContent object:contact userInfo:[NSDictionary dictionaryWithObjectsAndKeys:inObject,@"Object",nil]];

        //Filter the object
        enumerator = [incomingContentFilterArray objectEnumerator];
        while((filter = [enumerator nextObject])){
            [filter filterContentObject:inObject];
        }

        //Add the object
        [contact addContentObject:inObject];

        //Set 'UnrespondedContent' to YES  (This could be done by a seperate plugin, but I'm not sure that's necessary)
        [[handle statusDictionary] setObject:[NSNumber numberWithBool:YES] forKey:@"UnrespondedContent"];
        [[owner contactController] handleStatusChanged:handle modifiedStatusKeys:[NSArray arrayWithObject:@"UnrespondedContent"]];

        //content object addeed
        [[owner notificationCenter] postNotificationName:Content_ContentObjectAdded object:contact userInfo:[NSDictionary dictionaryWithObjectsAndKeys:inObject, @"Object", nil]];

        //Did receive content
        [[owner notificationCenter] postNotificationName:Content_DidReceiveContent object:contact userInfo:[NSDictionary dictionaryWithObjectsAndKeys:inObject, @"Object", nil]];
    }
}

//Send a message object to a handle
- (BOOL)sendContentObject:(id <AIContentObject>)inObject
{
    AIHandle		*handle = [inObject destination];
    AIListContact 	*contact = [handle containingContact];
    BOOL		sent = NO;

    if(contact){
        NSEnumerator		*enumerator;
        id<AIContentFilter>	filter;
        
        //Will send content
        [[owner notificationCenter] postNotificationName:Content_WillSendContent object:contact userInfo:[NSDictionary dictionaryWithObjectsAndKeys:inObject,@"Object",nil]];
    
        //Filter the object
        enumerator = [outgoingContentFilterArray objectEnumerator];
        while((filter = [enumerator nextObject])){
            [filter filterContentObject:inObject];
        }
    
        //Send the object
        if([(AIAccount <AIAccount_Content> *)[inObject source] sendContentObject:inObject]){
            //Add the object
            [contact addContentObject:inObject];

            //Set 'UnrespondedContent' to NO  (This could be done by a seperate plugin, but I'm not sure that's necessary)
            [[handle statusDictionary] setObject:[NSNumber numberWithBool:NO] forKey:@"UnrespondedContent"];
            [[owner contactController] handleStatusChanged:handle modifiedStatusKeys:[NSArray arrayWithObject:@"UnrespondedContent"]];

            //Content object added
            [[owner notificationCenter] postNotificationName:Content_ContentObjectAdded object:contact userInfo:[NSDictionary dictionaryWithObjectsAndKeys:inObject,@"Object",nil]];

            //Did send content
            [[owner notificationCenter] postNotificationName:Content_DidSendContent object:contact userInfo:[NSDictionary dictionaryWithObjectsAndKeys:inObject,@"Object",nil]];

            sent = YES;
        }
    }

    return(sent);
}

@end

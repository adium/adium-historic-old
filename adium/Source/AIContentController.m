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

@implementation AIContentController

//init
- (void)initController
{
    outgoingContentFilterArray = [[NSMutableArray alloc] init];
    incomingContentFilterArray = [[NSMutableArray alloc] init];
}

- (void)closeController
{

}

//dealloc
- (void)dealloc
{
    [contentNotificationCenter release]; contentNotificationCenter = nil;
    
    [super dealloc];
}

//Notification center for content notifications
- (NSNotificationCenter *)contentNotificationCenter
{
    if(contentNotificationCenter == nil){
        contentNotificationCenter = [[NSNotificationCenter alloc] init];
    }
    
    return(contentNotificationCenter);
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

- (void)stringAdded:(NSString *)inString toTextEntryView:(NSView<AITextEntryView> *)inTextEntryView
{
    NSEnumerator		*enumerator;
    id <AITextEntryFilter>	filter;

    enumerator = [textEntryFilterArray objectEnumerator];
    while((filter = [enumerator nextObject])){
        [filter stringAdded:inString toTextEntryView:inTextEntryView];
    }
}

- (void)contentsChangedInTextEntryView:(NSView<AITextEntryView> *)inTextEntryView
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
- (void)addIncomingContentObject:(id <AIContentObject>)inObject toHandle:(AIContactHandle *)inHandle
{
    NSEnumerator	*enumerator;
    id<AIContentFilter>	filter;
    
    //Will receive content
    [[self contentNotificationCenter] postNotificationName:Content_WillReceiveContent object:inHandle userInfo:[NSDictionary dictionaryWithObjectsAndKeys:inObject,@"Object",nil]];

    //Filter the object
    enumerator = [incomingContentFilterArray objectEnumerator];
    while((filter = [enumerator nextObject])){
        [filter filterContentObject:inObject];
    }

    //Add the object
    [inHandle addContentObject:inObject];
    
    //content object addeed
    [[self contentNotificationCenter] postNotificationName:Content_ContentObjectAdded object:inHandle userInfo:[NSDictionary dictionaryWithObjectsAndKeys:inObject,@"Object",[NSNumber numberWithBool:YES],@"Incoming",nil]];

    //Did receive content
    [[self contentNotificationCenter] postNotificationName:Content_DidReceiveContent object:inHandle userInfo:[NSDictionary dictionaryWithObjectsAndKeys:inObject,@"Object",nil]];
}

- (void)sendContentObject:(id <AIContentObject>)inObject toHandle:(AIContactHandle *)inHandle
{
    NSEnumerator	*enumerator;
    id<AIContentFilter>	filter;

    //Will send content
    [[self contentNotificationCenter] postNotificationName:Content_WillSendContent object:inHandle userInfo:[NSDictionary dictionaryWithObjectsAndKeys:inObject,@"Object",nil]];

    //Filter the object
    enumerator = [outgoingContentFilterArray objectEnumerator];
    while((filter = [enumerator nextObject])){
        [filter filterContentObject:inObject];
    }
    
    //Send the object
    [(AIAccount <AIAccount_Content> *)[inObject source] sendContentObject:inObject toHandle:inHandle];
    
    //Add the object
    [inHandle addContentObject:inObject];
    
    //Content object added
    [[self contentNotificationCenter] postNotificationName:Content_ContentObjectAdded object:inHandle userInfo:[NSDictionary dictionaryWithObjectsAndKeys:inObject,@"Object",[NSNumber numberWithBool:NO],@"Incoming",nil]];

    //Did send content
    [[self contentNotificationCenter] postNotificationName:Content_DidSendContent object:inHandle userInfo:[NSDictionary dictionaryWithObjectsAndKeys:inObject,@"Object",nil]];
}

@end

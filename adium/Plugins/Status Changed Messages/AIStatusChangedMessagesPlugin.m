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

#import "AIStatusChangedMessagesPlugin.h"
#import "AIAdium.h"
#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>

@interface AIStatusChangedMessagesPlugin (PRIVATE)
- (void)statusMessage:(NSString *)message forObject:(AIListObject *)object;
@end

@implementation AIStatusChangedMessagesPlugin

- (void)installPlugin
{
    [[owner contactController] registerListObjectObserver:self];

    //Observe contact status changes
    [[owner notificationCenter] addObserver:self selector:@selector(Contact_StatusAwayYes:) name:@"Contact_StatusAwayYes" object:nil];
    [[owner notificationCenter] addObserver:self selector:@selector(Contact_StatusAwayNo:) name:@"Contact_StatusAwayNo" object:nil];
    [[owner notificationCenter] addObserver:self selector:@selector(Contact_StatusOnlineYes:) name:@"Contact_StatusOnlineYes" object:nil];
    [[owner notificationCenter] addObserver:self selector:@selector(Contact_StatusOnlineNO:) name:@"Contact_StatusOnlineNO" object:nil];
    [[owner notificationCenter] addObserver:self selector:@selector(Contact_StatusIdleYes:) name:@"Contact_StatusIdleYes" object:nil];
    [[owner notificationCenter] addObserver:self selector:@selector(Contact_StatusIdleNo:) name:@"Contact_StatusIdleNo" object:nil];
}

//Catch away message changes and display them
- (NSArray *)updateListObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys
{
    
    if([inModifiedKeys containsObject:@"StatusMessage"]){
        AIMutableOwnerArray	*statusMessageArray = [inObject statusArrayForKey:@"StatusMessage"];

        if([statusMessageArray count] != 0){
            NSString		*statusMessage = [[statusMessageArray objectAtIndex:0] string];

            if([statusMessage length] != 0){
                [self statusMessage:[NSString stringWithFormat:@"Away Message: \"%@\"",statusMessage] forObject:inObject];
            }
            
        }
        
    }

    return(nil);
}


- (void)Contact_StatusAwayYes:(NSNotification *)notification{
    [self statusMessage:@"%@ went away" forObject:[notification object]];
}
- (void)Contact_StatusAwayNo:(NSNotification *)notification{
    [self statusMessage:@"%@ came back" forObject:[notification object]];
}
- (void)Contact_StatusOnlineYes:(NSNotification *)notification{
    [self statusMessage:@"%@ connected" forObject:[notification object]];
}
- (void)Contact_StatusOnlineNO:(NSNotification *)notification{
    [self statusMessage:@"%@ disconnected" forObject:[notification object]];
}
- (void)Contact_StatusIdleYes:(NSNotification *)notification{
    [self statusMessage:@"%@ went idle" forObject:[notification object]];
}
- (void)Contact_StatusIdleNo:(NSNotification *)notification{
    [self statusMessage:@"%@ became active" forObject:[notification object]];
}


//Post a status message on all activa chats for this object
- (void)statusMessage:(NSString *)message forObject:(AIListObject *)object
{
    NSEnumerator	*enumerator;
    AIChat		*chat;

    enumerator = [[[owner contentController] allChatsWithListObject:object] objectEnumerator];
    while((chat = [enumerator nextObject])){
        AIContentStatus	*content;

        //Create our content object
        content = [AIContentStatus statusInChat:chat
                                     withSource:[chat object]
                                    destination:[chat account]
                                           date:[NSDate date]
                                        message:[NSString stringWithFormat:message,[object displayName]]];

        //Add the object
        [[owner contentController] addIncomingContentObject:content];
    }
}


@end

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
- (void)statusMessage:(NSString *)message forContact:(AIListContact *)contact;
@end

@implementation AIStatusChangedMessagesPlugin

- (void)installPlugin
{
    [[owner contactController] registerContactObserver:self];

    //Observe contact status changes
    [[owner notificationCenter] addObserver:self selector:@selector(Contact_StatusAwayYes:) name:@"Contact_StatusAwayYes" object:nil];
    [[owner notificationCenter] addObserver:self selector:@selector(Contact_StatusAwayNo:) name:@"Contact_StatusAwayNo" object:nil];
    [[owner notificationCenter] addObserver:self selector:@selector(Contact_StatusOnlineYes:) name:@"Contact_StatusOnlineYes" object:nil];
    [[owner notificationCenter] addObserver:self selector:@selector(Contact_StatusOnlineNO:) name:@"Contact_StatusOnlineNO" object:nil];
    [[owner notificationCenter] addObserver:self selector:@selector(Contact_StatusIdleYes:) name:@"Contact_StatusIdleYes" object:nil];
    [[owner notificationCenter] addObserver:self selector:@selector(Contact_StatusIdleNo:) name:@"Contact_StatusIdleNo" object:nil];
}

//Catch away message changes and display them
- (NSArray *)updateContact:(AIListContact *)inContact keys:(NSArray *)inModifiedKeys
{
    
    if([inModifiedKeys containsObject:@"StatusMessage"]){
        AIMutableOwnerArray	*statusMessageArray = [inContact statusArrayForKey:@"StatusMessage"];

        if([statusMessageArray count] != 0){
            NSString		*statusMessage = [statusMessageArray objectAtIndex:0];

            if([statusMessage length] != 0){
                [self statusMessage:[NSString stringWithFormat:@"Away Message: \"%@\"",[statusMessageArray objectAtIndex:0]] forContact:inContact];
            }
            
        }
        
    }

    return(nil);
}


- (void)Contact_StatusAwayYes:(NSNotification *)notification{
    [self statusMessage:@"%@ went away" forContact:[notification object]];
}
- (void)Contact_StatusAwayNo:(NSNotification *)notification{
    [self statusMessage:@"%@ came back" forContact:[notification object]];
}
- (void)Contact_StatusOnlineYes:(NSNotification *)notification{
    [self statusMessage:@"%@ connected" forContact:[notification object]];
}
- (void)Contact_StatusOnlineNO:(NSNotification *)notification{
    [self statusMessage:@"%@ disconnected" forContact:[notification object]];
}
- (void)Contact_StatusIdleYes:(NSNotification *)notification{
    [self statusMessage:@"%@ went idle" forContact:[notification object]];
}
- (void)Contact_StatusIdleNo:(NSNotification *)notification{
    [self statusMessage:@"%@ became active" forContact:[notification object]];
}


//Post a status message
- (void)statusMessage:(NSString *)message forContact:(AIListContact *)contact
{
    AIContentStatus		*content;

    //Create our content object
    content = [AIContentStatus statusWithSource:contact
                                    destination:contact
                                           date:[NSDate date]
                                        message:[NSString stringWithFormat:message,[contact displayName]]];

    //Add the object
    [contact addContentObject:content];
    [[owner notificationCenter] postNotificationName:Content_ContentObjectAdded
                                              object:contact
                                            userInfo:[NSDictionary dictionaryWithObject:content forKey:@"Object"]];
}


@end







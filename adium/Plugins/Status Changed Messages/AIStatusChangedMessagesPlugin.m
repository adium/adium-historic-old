//
//  AIStatusChangedMessagesPlugin.m
//  Adium
//
//  Created by Adam Iser on Fri Apr 04 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIStatusChangedMessagesPlugin.h"
#import "AIAdium.h"
#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>

@interface AIStatusChangedMessagesPlugin (PRIVATE)
- (void)statusMessage:(NSString *)message forHandle:(AIHandle *)handle;
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
- (NSArray *)updateContact:(AIListContact *)inContact handle:(AIHandle *)inHandle keys:(NSArray *)inModifiedKeys
{
    if([inModifiedKeys containsObject:@"StatusMessage"]){
        NSString	*statusMessage = [[[inHandle statusDictionary] objectForKey:@"StatusMessage"] string];

        if(statusMessage && [statusMessage length] != 0){
            [self statusMessage:[NSString stringWithFormat:@"Away Message: \"%@\"",statusMessage] forHandle:inHandle];
        }
    }

    return(nil);
}


- (void)Contact_StatusAwayYes:(NSNotification *)notification{
    [self statusMessage:@"%@ went away" forHandle:[notification object]];
}
- (void)Contact_StatusAwayNo:(NSNotification *)notification{
    [self statusMessage:@"%@ came back" forHandle:[notification object]];
}
- (void)Contact_StatusOnlineYes:(NSNotification *)notification{
    [self statusMessage:@"%@ connected" forHandle:[notification object]];
}
- (void)Contact_StatusOnlineNO:(NSNotification *)notification{
    [self statusMessage:@"%@ disconnected" forHandle:[notification object]];
}
- (void)Contact_StatusIdleYes:(NSNotification *)notification{
    [self statusMessage:@"%@ went idle" forHandle:[notification object]];
}
- (void)Contact_StatusIdleNo:(NSNotification *)notification{
    [self statusMessage:@"%@ became active" forHandle:[notification object]];
}


//Post a status message
- (void)statusMessage:(NSString *)message forHandle:(AIHandle *)handle
{
    AIListContact		*contact = [handle containingContact];
    AIContentStatus		*content;

    //Create our content object
    content = [AIContentStatus statusWithSource:[handle account]
                                    destination:handle
                                           date:[NSDate date]
                                        message:[NSString stringWithFormat:message,[contact displayName]]];

    //Add the object
    [contact addContentObject:content];
    [[owner notificationCenter] postNotificationName:Content_ContentObjectAdded
                                              object:contact
                                            userInfo:[NSDictionary dictionaryWithObject:content forKey:@"Object"]];
}


@end







//
//  AIDockUnviewedContentPlugin.m
//  Adium
//
//  Created by Adam Iser on Fri Apr 25 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIDockUnviewedContentPlugin.h"
#import "AIAdium.h"
#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>


@implementation AIDockUnviewedContentPlugin

- (void)installPlugin
{
    //init
    unviewedContactsArray = [[NSMutableArray alloc] init];
    unviewedState = nil;

    //Register as a contact observer (So we can catch the unviewed content status flag)
    [[owner contactController] registerContactObserver:self];

}

- (void)uninstallPlugin
{

}


- (NSArray *)updateContact:(AIListContact *)inContact handle:(AIHandle *)inHandle keys:(NSArray *)inModifiedKeys
{
    if([inModifiedKeys containsObject:@"UnviewedContent"]){
        if([[inContact statusArrayForKey:@"UnviewedContent"] greatestIntegerValue]){
            //If this is the first contact with unviewed content, animate the dock
            if(unviewedState == nil){
                unviewedState = [[owner dockController] setIconStateNamed:@"Alert"];
            }

            [unviewedContactsArray addObject:inContact];

        }else{
            if([unviewedContactsArray containsObject:inContact]){
                [unviewedContactsArray removeObject:inContact];

                //If there are no more contacts with unviewed content, stop animating the dock
                if([unviewedContactsArray count] == 0 && unviewedState != nil){
                    [[owner dockController] removeIconState:unviewedState];
                    unviewedState = nil;
                }
            }
        }

    }

    return(nil);
}

@end

//
//  AIContactAwayPlugin.m
//  Adium
//
//  Created by Adam Iser on Thu May 01 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIContactAwayPlugin.h"
#import <AIUtilities/AIUtilities.h>

@implementation AIContactAwayPlugin

- (void)installPlugin
{
    //Install our tooltip entry
    [[owner interfaceController] registerContactListTooltipEntry:self];
}

//Tooltip entry ---------------------------------------------------------------------------------------
- (NSString *)label
{
    return(@"Away");
}

- (NSString *)entryForObject:(AIListObject *)inObject
{
    NSString	*entry = nil;

    if([inObject isKindOfClass:[AIListContact class]]){
        BOOL 			away;
        NSAttributedString 	*statusMessage = nil;
        AIMutableOwnerArray	*ownerArray;

        //Get the away state
        away = [[(AIListContact *)inObject statusArrayForKey:@"Away"] greatestIntegerValue];

        //Get the status message
        ownerArray = [(AIListContact *)inObject statusArrayForKey:@"StatusMessage"];
        if([ownerArray count] != 0){
            statusMessage = [ownerArray objectAtIndex:0];
        }

        //Return the correct string
        if(statusMessage != nil && [statusMessage length] != 0){
            entry = [statusMessage string];
        }else if(away){
            entry = @"Yes";
        }
    }

    return(entry);
}


@end

//
//  ESContactServersideDisplayName.m
//  Adium
//
//  Created by Evan Schoenberg on Mon Mar 01 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

#import "ESContactServersideDisplayName.h"


@implementation ESContactServersideDisplayName

- (void)installPlugin
{
    //Install our tooltip entry
    [[adium interfaceController] registerContactListTooltipEntry:self secondaryEntry:YES];
}

//Tooltip entry ---------------------------------------------------------------------------------------
- (NSString *)labelForObject:(AIListObject *)inObject
{
    return(@"Display Name");
}

- (NSAttributedString *)entryForObject:(AIListObject *)inObject
{
    NSString			*serverDisplayName;
    NSAttributedString	*entry = nil;
	
    //Get the server display name
    serverDisplayName = [inObject statusObjectForKey:@"Server Display Name"];
    
    //Return the correct string
    if(serverDisplayName && ![serverDisplayName isEqualToString:[inObject displayName]]){
		entry = [[NSAttributedString alloc] initWithString:serverDisplayName];
    }
	
    return([entry autorelease]);
}

@end
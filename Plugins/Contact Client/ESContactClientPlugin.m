//
//  ESContactClientPlugin.m
//  Adium
//
//  Created by Evan Schoenberg on Fri Feb 13 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

#import "ESContactClientPlugin.h"

@implementation ESContactClientPlugin

- (void)installPlugin
{
    //Install our tooltip entry
    [[adium interfaceController] registerContactListTooltipEntry:self secondaryEntry:YES];
}

//Tooltip entry ---------------------------------------------------------------------------------------
- (NSString *)labelForObject:(AIListObject *)inObject
{
    return(@"Client");
}

- (NSAttributedString *)entryForObject:(AIListObject *)inObject
{
    NSString			*client;
    NSAttributedString	*entry = nil;
	
    //Get the client
    client = [inObject statusObjectForKey:@"Client"];
    
    //Return the correct string
    if(client){
		entry = [[NSAttributedString alloc] initWithString:client];
    }
	
    return([entry autorelease]);
}


@end
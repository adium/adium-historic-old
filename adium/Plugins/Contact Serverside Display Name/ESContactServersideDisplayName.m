//
//  ESContactServersideDisplayName.m
//  Adium
//
//  Created by Evan Schoenberg on Mon Mar 01 2004.
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
	
    //Get the client
    serverDisplayName = [inObject statusObjectForKey:@"Server Display Name"];
    
    //Return the correct string
    if(serverDisplayName){
		entry = [[NSAttributedString alloc] initWithString:serverDisplayName];
    }
	
    return([entry autorelease]);
}


@end
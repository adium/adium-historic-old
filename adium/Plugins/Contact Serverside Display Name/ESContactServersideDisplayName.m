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
	
    //Get the server display name
    serverDisplayName = [inObject statusObjectForKey:@"Server Display Name"];
    
    //Return the correct string
    if(serverDisplayName && ![serverDisplayName isEqualToString:[inObject displayName]]){

		//If we are away and the status message and server display name are the same, don't display the server display name
		if(!([inObject integerStatusObjectForKey:@"Away" fromAnyContainedObject:NO]) ||
		   !([serverDisplayName isEqualToString:[inObject stringFromAttributedStringStatusObjectForKey:@"StatusMessage"]])){
			
			entry = [[NSAttributedString alloc] initWithString:serverDisplayName];
		}
    }
	
    return([entry autorelease]);
}

@end
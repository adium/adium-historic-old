//
//  ESContactClientPlugin.m
//  Adium XCode
//
//  Created by Evan Schoenberg on Fri Feb 13 2004.
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
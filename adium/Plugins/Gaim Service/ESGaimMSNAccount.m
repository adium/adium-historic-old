//
//  ESGaimMSNAccount.m
//  Adium XCode
//
//  Created by Evan Schoenberg on Sun Dec 28 2003.
//

#import "ESGaimMSNAccount.h"

@interface ESGaimMSNAccount (PRIVATE)
-(void)_setFriendlyNameTo:(NSString *)inAlias;
@end

@implementation ESGaimMSNAccount

- (const char*)protocolPlugin
{
    return "prpl-msn";
}

//MSN doesn't use HTML at all... there's a font setting in the MSN Messenger text box, but maybe it's ignored?
- (NSString *)encodedAttributedString:(NSAttributedString *)inAttributedString forListObject:(AIListObject *)inListObject
{
    return ([inAttributedString string]);
}

//Update our status
- (void)updateStatusForKey:(NSString *)key
{    
	
	[super updateStatusForKey:key];
	
    //Now look at keys which only make sense while online
	if([[self statusObjectForKey:@"Online"] boolValue]){
		if([key compare:@"FullName"] == 0){
			[self updateStatusString:[self preferenceForKey:key group:GROUP_ACCOUNT_STATUS] forKey:@"FullName"];
		}
	}
}

- (void)setStatusString:(NSString *)inString forKey:(NSString *)key
{
	if([key compare:@"FullName"] == 0){
		[self _setFriendlyNameTo:inString];
	}
}

-(void)_setFriendlyNameTo:(NSString *)inAlias
{
	if (gc && account) 
		msn_set_friendly_name(gc,[inAlias UTF8String]);
}

//Update all our status keys
- (void)updateAllStatusKeys
{
	[super updateAllStatusKeys];
	[self updateStatusForKey:@"FullName"];
}
/*
 //Added to msn.c
//**ADIUM
void msn_set_friendly_name(GaimConnection *gc, const char *entry)
{
	msn_act_id(gc, entry);
}
*/
 
@end


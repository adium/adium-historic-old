//
//  ESGaimMSNAccount.m
//  Adium
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

- (NSString *)connectionStringForStep:(int)step
{
	switch (step)
	{
		case 0:
			return AILocalizedString(@"Connecting",nil);
			break;
		case 1:
			return AILocalizedString(@"Connecting",nil);
			break;
		case 2:
			return AILocalizedString(@"Syncing with server",nil);
			break;			
		case 3:
			return AILocalizedString(@"Requesting to send password",nil);
			break;
		case 4:
			return AILocalizedString(@"Syncing with server",nil);
			break;
		case 5:
			return AILocalizedString(@"Requesting to send password",nil);
			break;
		case 6:
			return AILocalizedString(@"Password sent",nil);
			break;
		case 7:
			return AILocalizedString(@"Retrieving buddy list",nil);
			break;
			
	}
	return nil;
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


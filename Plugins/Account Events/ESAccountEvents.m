//
//  ESAccountEvents.m
//  Adium
//
//  Created by Evan Schoenberg on Sun Jun 27 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

#import "ESAccountEvents.h"

#define ACCOUNT_CONNECTION_STATUS_GROUPING  2.0

@implementation ESAccountEvents

- (void)installPlugin
{
	accountConnectionStatusGroupingOnlineTimer = nil;
	accountConnectionStatusGroupingOfflineTimer = nil;
	
	//Register the events we generate
	[[adium contactAlertsController] registerEventID:ACCOUNT_CONNECTED withHandler:self inGroup:AIAccountsEventHandlerGroup globalOnly:YES];
	[[adium contactAlertsController] registerEventID:ACCOUNT_DISCONNECTED withHandler:self inGroup:AIAccountsEventHandlerGroup globalOnly:YES];
	[[adium contactAlertsController] registerEventID:ACCOUNT_RECEIVED_EMAIL withHandler:self inGroup:AIOtherEventHandlerGroup globalOnly:YES];

	//Observe status changes
    [[adium contactController] registerListObjectObserver:self];
}

- (NSString *)shortDescriptionForEventID:(NSString *)eventID { return @""; }

- (NSString *)globalShortDescriptionForEventID:(NSString *)eventID
{
	NSString	*description;
	
	if([eventID isEqualToString:ACCOUNT_CONNECTED]){
		description = AILocalizedString(@"You connect",nil);
	}else if([eventID isEqualToString:ACCOUNT_DISCONNECTED]){
		description = AILocalizedString(@"You disconnect",nil);
	}else if ([eventID isEqualToString:ACCOUNT_RECEIVED_EMAIL]){
		description = AILocalizedString(@"New email notification",nil);
	}else{
		description = @"";	
	}
	
	return(description);
}

//Evan: This exists because old X(tras) relied upon matching the description of event IDs, and I don't feel like making
//a converter for old packs.  If anyone wants to fix this situation, please feel free :)
- (NSString *)englishGlobalShortDescriptionForEventID:(NSString *)eventID
{
	NSString	*description;
	
	if([eventID isEqualToString:ACCOUNT_CONNECTED]){
		description = @"Connected";
	}else if([eventID isEqualToString:ACCOUNT_DISCONNECTED]){
		description = @"Disconnected";
	}else if ([eventID isEqualToString:ACCOUNT_RECEIVED_EMAIL]){
		description = @"New Mail Received";
	}else{
		description = @"";	
	}
	
	return(description);
}

- (NSString *)longDescriptionForEventID:(NSString *)eventID forListObject:(AIListObject *)listObject
{
	NSString	*description;
	
	if([eventID isEqualToString:ACCOUNT_CONNECTED]){
		description = AILocalizedString(@"When you connect",nil);
	}else if([eventID isEqualToString:ACCOUNT_DISCONNECTED]){
		description = AILocalizedString(@"When you disconnect",nil);
	}else if([eventID isEqualToString:ACCOUNT_RECEIVED_EMAIL]){
		description = AILocalizedString(@"When you receive a new email notification",nil);
	}else{
		description = @"";
	}
	
	return(description);
}

- (NSString *)naturalLanguageDescriptionForEventID:(NSString *)eventID
										listObject:(AIListObject *)listObject
										  userInfo:(id)userInfo
									includeSubject:(BOOL)includeSubject
{
	NSString	*description = nil;
	
	if(includeSubject){
		NSString	*format = nil;
		if([eventID isEqualToString:ACCOUNT_CONNECTED]){
			format = AILocalizedString(@"%@ connected",nil);
		}else if([eventID isEqualToString:ACCOUNT_DISCONNECTED]){
			format = AILocalizedString(@"%@ disconnected",nil);
		}else if([eventID isEqualToString:ACCOUNT_RECEIVED_EMAIL]){
			format = AILocalizedString(@"%@ received new email",nil);
		}
		
		if(format){
			description = [NSString stringWithFormat:format,[listObject formattedUID]];
		}
	}else{
		if([eventID isEqualToString:ACCOUNT_CONNECTED]){
			description = AILocalizedString(@"connected",nil);
		}else if([eventID isEqualToString:ACCOUNT_DISCONNECTED]){
			description = AILocalizedString(@"disconnected",nil);
		}else if([eventID isEqualToString:ACCOUNT_RECEIVED_EMAIL]){
			description = AILocalizedString(@"received new email",nil);
		}
	}
	
	return(description);
}


#pragma mark Aggregation and event generation
//
- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
	if([inObject isKindOfClass:[AIAccount class]]){ //We only care about accounts
		if([inModifiedKeys containsObject:@"Online"]){
			
			if ([[inObject numberStatusObjectForKey:@"Online"] boolValue]){
				if (accountConnectionStatusGroupingOnlineTimer){
					[accountConnectionStatusGroupingOnlineTimer invalidate]; [accountConnectionStatusGroupingOnlineTimer release];
				}
				
				accountConnectionStatusGroupingOnlineTimer = [[NSTimer scheduledTimerWithTimeInterval:ACCOUNT_CONNECTION_STATUS_GROUPING
																							   target:self
																							 selector:@selector(accountConnection:)
																							 userInfo:inObject
																							  repeats:NO] retain];
			}else{
				if (accountConnectionStatusGroupingOfflineTimer){
					[accountConnectionStatusGroupingOfflineTimer invalidate]; [accountConnectionStatusGroupingOfflineTimer release];
				}
				
				accountConnectionStatusGroupingOfflineTimer = [[NSTimer scheduledTimerWithTimeInterval:ACCOUNT_CONNECTION_STATUS_GROUPING
																								target:self
																							  selector:@selector(accountDisconnection:)
																							  userInfo:inObject
																							   repeats:NO] retain];
			}
		}
	}
	
	return(nil);	
}

- (void)accountConnection:(NSTimer *)timer
{
	[[adium contactAlertsController] generateEvent:ACCOUNT_CONNECTED
									 forListObject:[timer userInfo]
										  userInfo:nil
					  previouslyPerformedActionIDs:nil];
	[accountConnectionStatusGroupingOnlineTimer release]; accountConnectionStatusGroupingOnlineTimer = nil;
}

- (void)accountDisconnection:(NSTimer *)timer
{
	[[adium contactAlertsController] generateEvent:ACCOUNT_DISCONNECTED
									 forListObject:[timer userInfo]
										  userInfo:nil
					  previouslyPerformedActionIDs:nil];
	[accountConnectionStatusGroupingOfflineTimer release]; accountConnectionStatusGroupingOfflineTimer = nil;
}

@end

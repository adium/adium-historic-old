//
//  ESAccountEvents.m
//  Adium
//
//  Created by Evan Schoenberg on Sun Jun 27 2004.
//

#import "ESAccountEvents.h"

#define ACCOUNT_CONNECTION_STATUS_GROUPING  2.0

@implementation ESAccountEvents

- (void)installPlugin
{
	accountConnectionStatusGroupingOnlineTimer = nil;
	accountConnectionStatusGroupingOfflineTimer = nil;
	
	//Register the events we generate
	[[adium contactAlertsController] registerEventID:ACCOUNT_CONNECTED withHandler:self globalOnly:YES];
	[[adium contactAlertsController] registerEventID:ACCOUNT_DISCONNECTED withHandler:self globalOnly:YES];

	//Observe status changes
    [[adium contactController] registerListObjectObserver:self];
}

- (NSString *)shortDescriptionForEventID:(NSString *)eventID { return @""; }

- (NSString *)globalShortDescriptionForEventID:(NSString *)eventID
{
	NSString	*description;
	
	if([eventID isEqualToString:ACCOUNT_CONNECTED]){
		description = NSLocalizedString(@"Connected",nil);
	}else if([eventID isEqualToString:ACCOUNT_DISCONNECTED]){
		description = NSLocalizedString(@"Disconnected",nil);
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
	}else{
		description = @"";	
	}
	
	return(description);
}

- (NSString *)longDescriptionForEventID:(NSString *)eventID forListObject:(AIListObject *)listObject { return @""; }

//
- (NSArray *)updateListObject:(AIListObject *)inObject keys:(NSArray *)modifiedKeys silent:(BOOL)silent
{
	if([inObject isKindOfClass:[AIAccount class]]){ //We only care about accounts
		if([modifiedKeys containsObject:@"Online"]){
			
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
										  userInfo:nil];
	[accountConnectionStatusGroupingOnlineTimer release]; accountConnectionStatusGroupingOnlineTimer = nil;
}

- (void)accountDisconnection:(NSTimer *)timer
{
	[[adium contactAlertsController] generateEvent:ACCOUNT_DISCONNECTED
									 forListObject:[timer userInfo]
										  userInfo:nil];
	[accountConnectionStatusGroupingOfflineTimer release]; accountConnectionStatusGroupingOfflineTimer = nil;
}

@end

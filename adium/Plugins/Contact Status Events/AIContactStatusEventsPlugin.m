//
//  AIContactStatusEvents.m
//  Adium
//
//  Created by Adam Iser on Sun Apr 04 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "AIContactStatusEventsPlugin.h"

@interface AIContactStatusEventsPlugin (PRIVATE)
- (BOOL)updateCache:(NSMutableDictionary *)cache forKey:(NSString *)key ofType:(SEL)selector listObject:(AIListObject *)inObject;
@end

@implementation AIContactStatusEventsPlugin

- (void)installPlugin
{
	//
    onlineCache = [[NSMutableDictionary alloc] init];
    awayCache = [[NSMutableDictionary alloc] init];
    idleCache = [[NSMutableDictionary alloc] init];

	//Register the events we generate
	[[adium contactAlertsController] registerEventID:CONTACT_STATUS_ONLINE_YES withHandler:self];
	[[adium contactAlertsController] registerEventID:CONTACT_STATUS_ONLINE_NO withHandler:self];
	[[adium contactAlertsController] registerEventID:CONTACT_STATUS_AWAY_YES withHandler:self];
	[[adium contactAlertsController] registerEventID:CONTACT_STATUS_AWAY_NO withHandler:self];
	[[adium contactAlertsController] registerEventID:CONTACT_STATUS_IDLE_YES withHandler:self];
	[[adium contactAlertsController] registerEventID:CONTACT_STATUS_IDLE_NO withHandler:self];
	
	//Observe status changes
    [[adium contactController] registerListObjectObserver:self];
}

- (NSString *)shortDescriptionForEventID:(NSString *)eventID
{
	NSString	*description;
	
	if([eventID isEqualToString:CONTACT_STATUS_ONLINE_YES]){
		description = AILocalizedString(@"Connects",nil);
	}else if([eventID isEqualToString:CONTACT_STATUS_ONLINE_NO]){
		description = AILocalizedString(@"Disconnects",nil);
	}else if([eventID isEqualToString:CONTACT_STATUS_AWAY_YES]){
		description = AILocalizedString(@"Goes away",nil);
	}else if([eventID isEqualToString:CONTACT_STATUS_AWAY_NO]){
		description = AILocalizedString(@"Returns from away",nil);
	}else if([eventID isEqualToString:CONTACT_STATUS_IDLE_YES]){
		description = AILocalizedString(@"Goes idle",nil);
	}else if([eventID isEqualToString:CONTACT_STATUS_IDLE_NO]){
		description = AILocalizedString(@"Returns from idle",nil);
	}else{
		description = @"";
	}
	
	return(description);
}

- (NSString *)globalShortDescriptionForEventID:(NSString *)eventID
{
	NSString	*description;
	
	if([eventID isEqualToString:CONTACT_STATUS_ONLINE_YES]){
		description = AILocalizedString(@"Contact Signed On",nil);
	}else if([eventID isEqualToString:CONTACT_STATUS_ONLINE_NO]){
		description = AILocalizedString(@"Contact Signed Off",nil);
	}else if([eventID isEqualToString:CONTACT_STATUS_AWAY_YES]){
		description = AILocalizedString(@"Contact Went Away",nil);
	}else if([eventID isEqualToString:CONTACT_STATUS_AWAY_NO]){
		description = AILocalizedString(@"Contact Returned from Away",nil);
	}else if([eventID isEqualToString:CONTACT_STATUS_IDLE_YES]){
		description = AILocalizedString(@"Contact Went Idle",nil);
	}else if([eventID isEqualToString:CONTACT_STATUS_IDLE_NO]){
		description = AILocalizedString(@"Contact Returned from Idle",nil);
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
	
	if([eventID isEqualToString:CONTACT_STATUS_ONLINE_YES]){
		description = @"Contact Signed On";
	}else if([eventID isEqualToString:CONTACT_STATUS_ONLINE_NO]){
		description = @"Contact Signed Off";
	}else if([eventID isEqualToString:CONTACT_STATUS_AWAY_YES]){
		description = @"Contact Went Away";
	}else if([eventID isEqualToString:CONTACT_STATUS_AWAY_NO]){
		description = @"Contact Returned from Away";
	}else if([eventID isEqualToString:CONTACT_STATUS_IDLE_YES]){
		description = @"Contact Went Idle";
	}else if([eventID isEqualToString:CONTACT_STATUS_IDLE_NO]){
		description = @"Contact Returned from Idle";
	}else{
		description = @"";	
	}
	
	return(description);
}

- (NSString *)longDescriptionForEventID:(NSString *)eventID forListObject:(AIListObject *)listObject
{
	NSString	*description;
	
	if([eventID isEqualToString:CONTACT_STATUS_ONLINE_YES]){
		description = AILocalizedString(@"When %@ connects",nil);
	}else if([eventID isEqualToString:CONTACT_STATUS_ONLINE_NO]){
		description = AILocalizedString(@"When %@ disconnects",nil);
	}else if([eventID isEqualToString:CONTACT_STATUS_AWAY_YES]){
		description = AILocalizedString(@"When %@ goes away",nil);
	}else if([eventID isEqualToString:CONTACT_STATUS_AWAY_NO]){
		description = AILocalizedString(@"When %@ returns from away",nil);
	}else if([eventID isEqualToString:CONTACT_STATUS_IDLE_YES]){
		description = AILocalizedString(@"When %@ goes idle",nil);
	}else if([eventID isEqualToString:CONTACT_STATUS_IDLE_NO]){
		description = AILocalizedString(@"When %@ returns from idle",nil);
	}else{
		description = AILocalizedString(@"Unknown",nil);
	}
	
	return([NSString stringWithFormat:description, [listObject displayName]]);
}

//
- (NSArray *)updateListObject:(AIListObject *)inObject keys:(NSArray *)modifiedKeys silent:(BOOL)silent
{
	if(![inObject isKindOfClass:[AIAccount class]]){ //Ignore accounts
		if(![[inObject containingGroup] isKindOfClass:[AIMetaContact class]]){ //Ignore children of meta contacts
			if([modifiedKeys containsObject:@"Online"]){
				if([self updateCache:onlineCache forKey:@"Online" ofType:@selector(numberStatusObjectForKey:) listObject:inObject] && !silent){
					[[adium contactAlertsController] generateEvent:([[inObject numberStatusObjectForKey:@"Online"] boolValue] ? CONTACT_STATUS_ONLINE_YES : CONTACT_STATUS_ONLINE_NO)
													 forListObject:inObject];
				}
			}
			if([modifiedKeys containsObject:@"Away"]){
				if([self updateCache:awayCache forKey:@"Away" ofType:@selector(numberStatusObjectForKey:) listObject:inObject] && !silent){
					[[adium contactAlertsController] generateEvent:([[inObject numberStatusObjectForKey:@"Away"] boolValue] ? CONTACT_STATUS_AWAY_YES : CONTACT_STATUS_AWAY_NO)
													 forListObject:inObject];
				}
			}
			if([modifiedKeys containsObject:@"IdleSince"]){
				if([self updateCache:idleCache forKey:@"IdleSince" ofType:@selector(earliestDateStatusObjectForKey:) listObject:inObject] && !silent){
					[[adium contactAlertsController] generateEvent:(([inObject earliestDateStatusObjectForKey:@"IdleSince"] != nil) ? CONTACT_STATUS_IDLE_YES : CONTACT_STATUS_IDLE_NO)
													 forListObject:inObject];
				}
			}
		}
	}
	
	return(nil);	
}

- (BOOL)updateCache:(NSMutableDictionary *)cache forKey:(NSString *)key ofType:(SEL)selector listObject:(AIListObject *)inObject 
{
	id		newStatus = [inObject performSelector:selector withObject:key];
	id		oldStatus = [cache objectForKey:[inObject uniqueObjectID]];
	
	if(newStatus && (oldStatus == nil || ![newStatus performSelector:@selector(compare:) withObject:oldStatus] == 0)){
		[cache setObject:newStatus forKey:[inObject uniqueObjectID]];
		return(YES);
	}else{
		return(NO);
	}
}

@end

//
//  AIContactStatusEvents.m
//  Adium
//
//  Created by Adam Iser on Sun Apr 04 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "AIContactStatusEventsPlugin.h"

@interface AIContactStatusEventsPlugin (PRIVATE)
- (BOOL)updateChache:(NSMutableDictionary *)cache forKey:(NSString *)key ofType:(SEL)selector listObject:(AIListObject *)inObject;
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
	NSString	*description = @"";
	
	if([eventID compare:CONTACT_STATUS_ONLINE_YES] == 0){
		description = @"When %n connects";
	}else if([eventID compare:CONTACT_STATUS_ONLINE_NO] == 0){
		description = @"When %n disconnects";
	}else if([eventID compare:CONTACT_STATUS_AWAY_YES] == 0){
		description = @"When %n goes away";
	}else if([eventID compare:CONTACT_STATUS_AWAY_NO] == 0){
		description = @"When %n returns from away";
	}else if([eventID compare:CONTACT_STATUS_IDLE_YES] == 0){
		description = @"When %n goes idle";
	}else if([eventID compare:CONTACT_STATUS_IDLE_NO] == 0){
		description = @"When %n returns from idle";
	}
	
	return(description);
}

- (NSString *)longDescriptionForEventID:(NSString *)eventID
{
	NSString	*description = @"Unknown";
	
	if([eventID compare:CONTACT_STATUS_ONLINE_YES] == 0){
		description = @"When %n connects";
	}else if([eventID compare:CONTACT_STATUS_ONLINE_NO] == 0){
		description = @"When %n disconnects";
	}else if([eventID compare:CONTACT_STATUS_AWAY_YES] == 0){
		description = @"When %n goes away";
	}else if([eventID compare:CONTACT_STATUS_AWAY_NO] == 0){
		description = @"When %n returns from away";
	}else if([eventID compare:CONTACT_STATUS_IDLE_YES] == 0){
		description = @"When %n goes idle";
	}else if([eventID compare:CONTACT_STATUS_IDLE_NO] == 0){
		description = @"When %n returns from idle";
	}
	
	return(description);
}

//
- (NSArray *)updateListObject:(AIListObject *)inObject keys:(NSArray *)modifiedKeys silent:(BOOL)silent
{
	if(![inObject isKindOfClass:[AIAccount class]]){ //Ignore accounts
		if(![[inObject containingGroup] isKindOfClass:[AIMetaContact class]]){ //Ignore children of meta contacts
			if([modifiedKeys containsObject:@"Online"]){
				if([self updateChache:onlineCache forKey:@"Online" ofType:@selector(numberStatusObjectForKey:) listObject:inObject] && !silent){
					[[adium contactAlertsController] generateEvent:([inObject integerStatusObjectForKey:@"Online"] ? CONTACT_STATUS_ONLINE_YES : CONTACT_STATUS_ONLINE_NO)
													 forListObject:inObject];
				}
			}
			if([modifiedKeys containsObject:@"Away"]){
				if([self updateChache:awayCache forKey:@"Away" ofType:@selector(numberStatusObjectForKey:) listObject:inObject] && !silent){
					[[adium contactAlertsController] generateEvent:([inObject integerStatusObjectForKey:@"Away"] ? CONTACT_STATUS_AWAY_YES : CONTACT_STATUS_AWAY_NO)
													 forListObject:inObject];
				}
			}
			if([modifiedKeys containsObject:@"IdleSince"]){
				if([self updateChache:idleCache forKey:@"IdleSince" ofType:@selector(earliestDateStatusObjectForKey:) listObject:inObject] && !silent){
					[[adium contactAlertsController] generateEvent:(([inObject earliestDateStatusObjectForKey:@"IdleSince"] != nil) ? CONTACT_STATUS_IDLE_YES : CONTACT_STATUS_IDLE_NO)
													 forListObject:inObject];
				}
			}
		}
	}
	
	return(nil);	
}

- (BOOL)updateChache:(NSMutableDictionary *)cache forKey:(NSString *)key ofType:(SEL)selector listObject:(AIListObject *)inObject 
{
	id		newStatus = [inObject performSelector:selector withObject:key];
	id		oldStatus = [cache objectForKey:[inObject uniqueObjectID]];
	
	if(newStatus && (oldStatus == nil || ![newStatus performSelector:@selector(compare) withObject:oldStatus] == 0)){
		[cache setObject:newStatus forKey:[inObject uniqueObjectID]];
		return(YES);
	}else{
		return(NO);
	}
}

@end

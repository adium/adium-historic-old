//
//  AIContactStatusEvents.m
//  Adium
//
//  Created by Adam Iser on Sun Apr 04 2004.
//

#import "AIContactStatusEventsPlugin.h"

@interface AIContactStatusEventsPlugin (PRIVATE)
- (BOOL)updateCache:(NSMutableDictionary *)cache forKey:(NSString *)key ofType:(SEL)selector listObject:(AIListObject *)inObject performCompare:(BOOL)performCompare;
@end

@implementation AIContactStatusEventsPlugin

- (void)installPlugin
{
	//
    onlineCache = [[NSMutableDictionary alloc] init];
    awayCache = [[NSMutableDictionary alloc] init];
    idleCache = [[NSMutableDictionary alloc] init];
	statusMessageCache = [[NSMutableDictionary alloc] init];
	
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
	//Ignore accounts.
	//Ignore meta contact children since the actual meta contact provides a better event.
	if((![inObject isKindOfClass:[AIAccount class]]) &&		//Ignore accounts
	   (![[inObject containingObject] isKindOfClass:[AIMetaContact class]])){	
		
		if([modifiedKeys containsObject:@"Online"]){
			id newValue = [inObject numberStatusObjectForKey:@"Online" fromAnyContainedObject:NO];
			if([self updateCache:onlineCache
						  forKey:@"Online"
						newValue:newValue
					  listObject:inObject
				  performCompare:YES] && !silent){
				NSString	*event = ([newValue boolValue] ? CONTACT_STATUS_ONLINE_YES : CONTACT_STATUS_ONLINE_NO);
				[[adium contactAlertsController] generateEvent:event
												 forListObject:inObject
													  userInfo:nil];
			}
		}
		
		//Events which are irrelevent if the contact is not online - these changes occur when we are just doing bookkeeping
		//e.g. an away contact signs off, we clear the away flag, but they didn't actually come back from away.
		if ([[inObject numberStatusObjectForKey:@"Online"] boolValue]){
			if([modifiedKeys containsObject:@"Away"]){
				id newValue = [inObject numberStatusObjectForKey:@"Away" fromAnyContainedObject:NO];
				if([self updateCache:awayCache
							  forKey:@"Away"
							newValue:newValue
						  listObject:inObject
					  performCompare:YES] && !silent){
					NSString	*event = ([newValue boolValue] ? CONTACT_STATUS_AWAY_YES : CONTACT_STATUS_AWAY_NO);
					[[adium contactAlertsController] generateEvent:event
													 forListObject:inObject
														  userInfo:nil];
				}
			}
			if([modifiedKeys containsObject:@"IdleSince"]){
				id newValue = [inObject earliestDateStatusObjectForKey:@"IdleSince"
												fromAnyContainedObject:NO];
				if([self updateCache:idleCache
							  forKey:@"IdleSince"
							newValue:newValue
						  listObject:inObject
					  performCompare:NO] && !silent){
					NSString	*event = ((newValue != nil) ? CONTACT_STATUS_IDLE_YES : CONTACT_STATUS_IDLE_NO);
					[[adium contactAlertsController] generateEvent:event
													 forListObject:inObject
														  userInfo:nil];
				}
			}
			if([modifiedKeys containsObject:@"StatusMessage"]){
				id	newValue = [inObject stringFromAttributedStringStatusObjectForKey:@"StatusMessage"
															   fromAnyContainedObject:YES];
				if([self updateCache:statusMessageCache 
							  forKey:@"StatusMessage"
							newValue:newValue
						  listObject:inObject
					  performCompare:YES] && !silent){
					if (newValue != nil){
						//Evan: Not yet a contact alert, but we use the notification - how could/should we use this?
						[[adium contactAlertsController] generateEvent:CONTACT_STATUS_MESSAGE
														 forListObject:inObject
															  userInfo:nil];
					}
				}
			}
		}
	}
	
	return(nil);	
}

//Caches status changes, returning YES if it was a true change and NO if the change already happened for this listObject via another account
//If performCompare is NO, we are only concerned about the existance of the statusObject.  
//If it is YES, a change from one value to another is considered worthy of an update.
- (BOOL)updateCache:(NSMutableDictionary *)cache forKey:(NSString *)key newValue:(id)newStatus listObject:(AIListObject *)inObject performCompare:(BOOL)performCompare
{
	id		oldStatus = [cache objectForKey:[inObject uniqueObjectID]];
	if((newStatus && !oldStatus) ||
	   (oldStatus && !newStatus) ||
	   ((performCompare && newStatus && oldStatus && ![newStatus performSelector:@selector(compare:) withObject:oldStatus] == 0))){
		
		if (newStatus){
			[cache setObject:newStatus forKey:[inObject uniqueObjectID]];
		}else{
			[cache removeObjectForKey:[inObject uniqueObjectID]];
		}
		return(YES);
	}else{
		return(NO);
	}
}

@end

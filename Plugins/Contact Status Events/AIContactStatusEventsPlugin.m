//
//  AIContactStatusEvents.m
//  Adium
//
//  Created by Adam Iser on Sun Apr 04 2004.
//

#import "AIContactStatusEventsPlugin.h"

@interface AIContactStatusEventsPlugin (PRIVATE)
- (BOOL)updateCache:(NSMutableDictionary *)cache forKey:(NSString *)key newValue:(id)newStatus listObject:(AIListObject *)inObject performCompare:(BOOL)performCompare;
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
	[[adium contactAlertsController] registerEventID:CONTACT_STATUS_ONLINE_YES withHandler:self inGroup:AIContactsEventHandlerGroup globalOnly:NO];
	[[adium contactAlertsController] registerEventID:CONTACT_STATUS_ONLINE_NO withHandler:self inGroup:AIContactsEventHandlerGroup globalOnly:NO];
	[[adium contactAlertsController] registerEventID:CONTACT_STATUS_AWAY_YES withHandler:self inGroup:AIContactsEventHandlerGroup globalOnly:NO];
	[[adium contactAlertsController] registerEventID:CONTACT_STATUS_AWAY_NO withHandler:self inGroup:AIContactsEventHandlerGroup globalOnly:NO];
	[[adium contactAlertsController] registerEventID:CONTACT_STATUS_IDLE_YES withHandler:self inGroup:AIContactsEventHandlerGroup globalOnly:NO];
	[[adium contactAlertsController] registerEventID:CONTACT_STATUS_IDLE_NO withHandler:self inGroup:AIContactsEventHandlerGroup globalOnly:NO];
	
	//Observe status changes
    [[adium contactController] registerListObjectObserver:self];
}

- (NSString *)shortDescriptionForEventID:(NSString *)eventID
{
	NSString	*description;
	
	if([eventID isEqualToString:CONTACT_STATUS_ONLINE_YES]){
		description = AILocalizedString(@"Signs on",nil);
	}else if([eventID isEqualToString:CONTACT_STATUS_ONLINE_NO]){
		description = AILocalizedString(@"Signs off",nil);
	}else if([eventID isEqualToString:CONTACT_STATUS_AWAY_YES]){
		description = AILocalizedString(@"Goes away",nil);
	}else if([eventID isEqualToString:CONTACT_STATUS_AWAY_NO]){
		description = AILocalizedString(@"Returns from away",nil);
	}else if([eventID isEqualToString:CONTACT_STATUS_IDLE_YES]){
		description = AILocalizedString(@"Becomes idle",nil);
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
		description = AILocalizedString(@"Contact signs on",nil);
	}else if([eventID isEqualToString:CONTACT_STATUS_ONLINE_NO]){
		description = AILocalizedString(@"Contact signs off",nil);
	}else if([eventID isEqualToString:CONTACT_STATUS_AWAY_YES]){
		description = AILocalizedString(@"Contact goes away",nil);
	}else if([eventID isEqualToString:CONTACT_STATUS_AWAY_NO]){
		description = AILocalizedString(@"Contact returns from away",nil);
	}else if([eventID isEqualToString:CONTACT_STATUS_IDLE_YES]){
		description = AILocalizedString(@"Contact becomes idle",nil);
	}else if([eventID isEqualToString:CONTACT_STATUS_IDLE_NO]){
		description = AILocalizedString(@"Contact returns from idle",nil);
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
	NSString	*name;
	
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
	
	if(listObject){
		name = ([listObject isKindOfClass:[AIListGroup class]] ?
				[NSString stringWithFormat:AILocalizedString(@"a member of %@",nil),[listObject displayName]] :
				[listObject displayName]);
	}else{
		name = AILocalizedString(@"a contact",nil);
	}

	return([NSString stringWithFormat:description,name]);
}

//
- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
	//Ignore accounts.
	//Ignore meta contact children since the actual meta contact provides a better event.
	if((![inObject isKindOfClass:[AIAccount class]]) &&		//Ignore accounts
	   (![[inObject containingObject] isKindOfClass:[AIMetaContact class]])){	
		
		if([inModifiedKeys containsObject:@"Online"]){
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
			if([inModifiedKeys containsObject:@"Away"]){
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
			if([inModifiedKeys containsObject:@"IsIdle"]){
				id newValue = [inObject numberStatusObjectForKey:@"IsIdle" fromAnyContainedObject:NO];
				if([self updateCache:idleCache
							  forKey:@"IsIdle"
							newValue:newValue
						  listObject:inObject
					  performCompare:YES] && !silent){
					NSString	*event = ([newValue boolValue] ? CONTACT_STATUS_IDLE_YES : CONTACT_STATUS_IDLE_NO);
					[[adium contactAlertsController] generateEvent:event
													 forListObject:inObject
														  userInfo:nil];
				}
			}
			if([inModifiedKeys containsObject:@"StatusMessage"]){
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
	id		oldStatus = [cache objectForKey:[inObject internalObjectID]];
	if((newStatus && !oldStatus) ||
	   (oldStatus && !newStatus) ||
	   ((performCompare && newStatus && oldStatus && ![newStatus performSelector:@selector(compare:) withObject:oldStatus] == 0))){
		
		if (newStatus){
			[cache setObject:newStatus forKey:[inObject internalObjectID]];
		}else{
			[cache removeObjectForKey:[inObject internalObjectID]];
		}
		return(YES);
	}else{
		return(NO);
	}
}

@end

//
//  DCMessageContextDisplayPlugin.m
//  Adium
//
//  Created by David Clark on Tuesday, March 23, 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

#import "DCMessageContextDisplayPlugin.h"

@interface DCMessageContextDisplayPlugin (PRIVATE)
- (void)preferencesChanged:(NSNotification *)notification;
- (BOOL)contextShouldBeDisplayed:(NSCalendarDate *)inDate;
@end

@implementation DCMessageContextDisplayPlugin
- (void)installPlugin
{

	isObserving = NO;
	
	//Setup our preferences
    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:CONTEXT_DISPLAY_DEFAULTS
																		forClass:[self class]] 
										  forGroup:PREF_GROUP_CONTEXT_DISPLAY];
    preferences = [[DCMessageContextDisplayPreferences preferencePane] retain];
	
    //Observe preference changes
	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_CONTEXT_DISPLAY];
	
	//Always observe chats closing
	[[adium notificationCenter] addObserver:self
								   selector:@selector(saveContextForObject:)
									   name:Chat_WillClose
									 object:nil];
}

- (void)dealloc
{
    [super dealloc];
}

- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	//Only change our preferences in response to global preference notifications; specific objects use this group as well.
	if(object == nil){
		haveTalkedDays = [[prefDict objectForKey:KEY_HAVE_TALKED_DAYS] intValue];
		haveNotTalkedDays = [[prefDict objectForKey:KEY_HAVE_NOT_TALKED_DAYS] intValue];
		displayMode = [[prefDict objectForKey:KEY_DISPLAY_MODE] intValue];
		
		haveTalkedUnits = [[prefDict objectForKey:KEY_HAVE_TALKED_UNITS] intValue];
		haveNotTalkedUnits = [[prefDict objectForKey:KEY_HAVE_NOT_TALKED_UNITS] intValue];
		
		shouldDisplay = [[prefDict objectForKey:KEY_DISPLAY_CONTEXT] boolValue];
		linesToDisplay = [[prefDict objectForKey:KEY_DISPLAY_LINES] intValue];
		
		dimRecentContext = [[prefDict objectForKey:KEY_DIM_RECENT_CONTEXT] boolValue];
		
		if(shouldDisplay && linesToDisplay > 0 && !isObserving) {
			//Observe new message windows only if we aren't already observing them
			isObserving = YES;
			[[adium notificationCenter] addObserver:self
										   selector:@selector(addContextDisplayToWindow:)
											   name:Chat_DidOpen 
											 object:nil];
			
		}else if(isObserving && (!shouldDisplay || linesToDisplay <= 0)){
			//Remove observer
			isObserving = NO;
			[[adium notificationCenter] removeObserver:self name:Chat_DidOpen object:nil];
			
		}
	}
}

// Save the last few lines of a conversation when it closes
- (void)saveContextForObject:(NSNotification *)notification
{
	int					cnt, prevcnt;
	AIContentObject		*content;
	AIChat				*chat;
	NSMutableDictionary *dict = nil;
	NSDictionary		*contentDict;
	NSDictionary		*previousDict;
	NSEnumerator        *enumerator;
	
	chat = (AIChat *)[notification object];
	
	//Ensure we only save context for one-on-one chats; there must be a [chat listObject] and no name.
	if(chat && [chat listObject] && ![chat name]) {		
		dict = [NSMutableDictionary dictionary];

		enumerator = [[chat contentObjectArray] objectEnumerator];
		
		//Is there already stored context for this person?
		previousDict = [[chat listObject] preferenceForKey:KEY_MESSAGE_CONTEXT group:PREF_GROUP_CONTEXT_DISPLAY];
		
		cnt = 1;
				
		// Only save if we need to save more AND there is still unsaved content available
		while( (cnt <= linesToDisplay) && (content = [enumerator nextObject]) ) {
			
			// Only record actual messages, no status
			if( [content isKindOfClass:[AIContentMessage class]] || [content isKindOfClass:[AIContentContext class]]) {
				contentDict = [self savableContentObject:content];
				[dict setObject:contentDict forKey:[[NSNumber numberWithInt:cnt] stringValue]];
				cnt++;
			}
			
		}
		
		// If there's room left, append the old messages too
		if( cnt <= linesToDisplay && previousDict ) {
			
			unsigned previousDictCount = [previousDict count];
			prevcnt = 1;
			
			while( (cnt <= linesToDisplay+1) && (prevcnt <= previousDictCount) ) {
				[dict setObject:[previousDict objectForKey:[[NSNumber numberWithInt:prevcnt] stringValue]]
						 forKey:[[NSNumber numberWithInt:cnt] stringValue]];
				prevcnt++;
				cnt++;
			}
		}
		
	}
	
	// Did we find anything useful to save? If not, leave it untouched
	if(dict && ([dict count] > 0)) {
		[[chat listObject] setPreference:dict forKey:KEY_MESSAGE_CONTEXT group:PREF_GROUP_CONTEXT_DISPLAY];
	}
	
}

//Returns a dictionary representation of a content object which can be written to disk
//ONLY handles AIContentMessage and AIContentContext objects right now
- (NSDictionary *)savableContentObject:(AIContentObject *)content
{
	NSMutableDictionary	*contentDict = nil;
	AIChat				*chat = [content chat];
	AIListContact		*listContact = [chat listObject];
	
	NSString			*objectID;
	NSNumber			*accountNumber;
	
	contentDict = [NSMutableDictionary dictionary];
	[contentDict setObject:[content type] forKey:@"Type"];
	
	objectID = [listContact internalUniqueObjectID];
	accountNumber = [NSNumber numberWithInt:[[chat account] accountNumber]];
	
	// Outgoing or incoming?
	if ([content isOutgoing]){
		[contentDict setObject:objectID forKey:@"To"];
		[contentDict setObject:accountNumber forKey:@"From"];
	}else{
		[contentDict setObject:accountNumber forKey:@"To"];
		[contentDict setObject:objectID forKey:@"From"];
	}
	
	[contentDict setObject:[NSNumber numberWithBool:[content isOutgoing]] forKey:@"Outgoing"];
	
	// ONLY log AIContentMessage and AIContentContexts right now... no status messages
	[contentDict setObject:[NSNumber numberWithBool:[(AIContentMessage *)content isAutoreply]] forKey:@"Autoreply"];
	[contentDict setObject:[[(AIContentMessage *)content date] description] forKey:@"Date"];
	[contentDict setObject:[[[(AIContentMessage *)content message] safeString] dataRepresentation] forKey:@"Message"];

	return(contentDict);
}


- (void)addContextDisplayToWindow:(NSNotification *)notification
{
	int					cnt;
	AIChat				*chat;
	NSString			*type;
	NSAttributedString  *message;
	AIContentContext	*responseContent;
	id					source;
	id					dest;
	BOOL				isContext = YES;
		
	chat = (AIChat *)[notification object];
		
	NSDictionary	*chatDict = [[chat listObject] preferenceForKey:KEY_MESSAGE_CONTEXT group:PREF_GROUP_CONTEXT_DISPLAY];
	NSDictionary	*messageDict;
	
	if( chatDict && shouldDisplay && linesToDisplay > 0 ) {
		
		//Check if the history fits the date restrictions
		
		NSCalendarDate *mostRecentMessage = [NSDate dateWithNaturalLanguageString:[[chatDict objectForKey:@"1"] objectForKey:@"Date"]];
		
		// find out how long it's been since the context was saved, if we care
		if( !dimRecentContext ) {
			NSTimeInterval timeInterval = -[mostRecentMessage timeIntervalSinceNow];
			isContext = !(timeInterval > -300 && timeInterval < 300);
		}
		
		if( [self contextShouldBeDisplayed:mostRecentMessage] ) {
			
			//Max number of lines to display
			cnt = ([chatDict count] >= linesToDisplay ? linesToDisplay : [chatDict count]);
			
			//Add messages until: we add our max (linesToDisplay) OR we run out of saved messages
			while( (messageDict = [chatDict objectForKey:[[NSNumber numberWithInt:cnt] stringValue]]) && cnt > 0 ) {
				
				cnt--;
				
				type = [messageDict objectForKey:@"Type"];
				
				//Currently, we only add Message or Context content objects
				if( [type isEqualToString:CONTENT_MESSAGE_TYPE] || [type isEqualToString:CONTENT_CONTEXT_TYPE] ) {
					message = [NSAttributedString stringWithData:[messageDict objectForKey:@"Message"]];
					
					NSString *from = [messageDict objectForKey:@"From"];
					NSString *to = [messageDict objectForKey:@"To"];
					
					// The other person is always the one we're chatting with right now
					if( [[messageDict objectForKey:@"Outgoing"] boolValue] ) {
						dest = [chat listObject];
						source = [[adium accountController] accountWithAccountNumber:[from intValue]];
					} else {
						source = [chat listObject];
						dest = [[adium accountController] accountWithAccountNumber:[to intValue]];
					}

					// Make the message response if all is well
					if(message && source && dest) {
						
						// Make the message appear as context if isContext is true or it was a context object
						// last time or if we should always dim recent context. Make a regular message otherwise
						if(isContext || [type isEqualToString:CONTENT_CONTEXT_TYPE] || dimRecentContext) {
							responseContent =[AIContentContext messageInChat:chat
																  withSource:source
																 destination:dest
																		date:[NSDate dateWithNaturalLanguageString:[messageDict objectForKey:@"Date"]]
																	 message:message
																   autoreply:[[messageDict objectForKey:@"Autoreply"] boolValue]];
						} else {	
							responseContent =[AIContentMessage messageInChat:chat
																  withSource:source
																 destination:dest
																		date:[NSDate dateWithNaturalLanguageString:[messageDict objectForKey:@"Date"]]
																	 message:message
																   autoreply:[[messageDict objectForKey:@"Autoreply"] boolValue]];							
							[responseContent setTrackContent:NO];
						}

						if(responseContent)
							[[adium contentController] displayContentObject:responseContent usingContentFilters:YES immediately:YES];

					}
					
				}
				
			}
			
		}
		
	}
	
}

- (BOOL)contextShouldBeDisplayed:(NSCalendarDate *)inDate
{
	BOOL dateIsGood = YES;
	int thresholdDays = 0;
	int thresholdHours = 0;
	
	if( displayMode != MODE_ALWAYS ) {
		
		if( displayMode == MODE_HAVE_TALKED ) {
			if( haveTalkedUnits == UNIT_DAYS )
				thresholdDays = haveTalkedDays;
			else if( haveTalkedUnits == UNIT_HOURS )
				thresholdHours = haveTalkedDays;
			
		} else if( displayMode == MODE_HAVE_NOT_TALKED ) {
			if( haveTalkedUnits == UNIT_DAYS )
				thresholdDays = haveNotTalkedDays;
			else if( haveTalkedUnits == UNIT_HOURS )
				thresholdHours = haveNotTalkedDays;
		}
		
		// Take the most recent message's date, add our limits to it
		// See if the new date is earlier or later than today's date
		NSCalendarDate *newDate = [inDate dateByAddingYears:0 months:0 days:thresholdDays hours:thresholdHours minutes:0 seconds:0];

		NSComparisonResult comparison = [newDate compare:[NSDate date]];
		
		if( ((displayMode == MODE_HAVE_TALKED) && (comparison == NSOrderedAscending)) ||
			((displayMode == MODE_HAVE_NOT_TALKED) && (comparison == NSOrderedDescending)) ) {
			dateIsGood = NO;
		}
	}
	
	return( dateIsGood );
}
@end

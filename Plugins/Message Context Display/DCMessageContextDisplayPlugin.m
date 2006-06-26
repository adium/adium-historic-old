/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "AIContentController.h"
#import "AIPreferenceController.h"
#import "DCMessageContextDisplayPlugin.h"
#import "DCMessageContextDisplayPreferences.h"
#import <AIUtilities/AIDictionaryAdditions.h>
#import <Adium/AIChat.h>
#import <Adium/AIContentContext.h>
//#import "SMSQLiteLoggerPlugin.h"
//#import "AICoreComponentLoader.h"

//Old school
#import <Adium/AIListContact.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import "AIAccountController.h"

@interface DCMessageContextDisplayPlugin (PRIVATE)
- (void)preferencesChanged:(NSNotification *)notification;
- (BOOL)contextShouldBeDisplayed:(NSCalendarDate *)inDate;

- (void)setupOldSchoolHistory;
- (NSArray *)context:(int)inLinesToDisplay inChat:(AIChat *)chat;
- (NSDictionary *)savableContentObject:(AIContentObject *)content;
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
	
	[self setupOldSchoolHistory];
}

- (void)uninstallPlugin
{
	[[adium preferenceController] unregisterPreferenceObserver:self];
	[[adium notificationCenter] removeObserver:self];
}

- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	//Only change our preferences in response to global preference notifications; specific objects use this group as well.
	if (object == nil) {
		haveTalkedDays = [[prefDict objectForKey:KEY_HAVE_TALKED_DAYS] intValue];
		haveNotTalkedDays = [[prefDict objectForKey:KEY_HAVE_NOT_TALKED_DAYS] intValue];
		displayMode = [[prefDict objectForKey:KEY_DISPLAY_MODE] intValue];
		
		haveTalkedUnits = [[prefDict objectForKey:KEY_HAVE_TALKED_UNITS] intValue];
		haveNotTalkedUnits = [[prefDict objectForKey:KEY_HAVE_NOT_TALKED_UNITS] intValue];
		
		shouldDisplay = [[prefDict objectForKey:KEY_DISPLAY_CONTEXT] boolValue];
		linesToDisplay = [[prefDict objectForKey:KEY_DISPLAY_LINES] intValue];
				
		if (shouldDisplay && linesToDisplay > 0 && !isObserving) {
			//Observe new message windows only if we aren't already observing them
			isObserving = YES;
			[[adium notificationCenter] addObserver:self
										   selector:@selector(addContextDisplayToWindow:)
											   name:Chat_DidOpen 
											 object:nil];
			
		} else if (isObserving && (!shouldDisplay || linesToDisplay <= 0)) {
			//Remove observer
			isObserving = NO;
			[[adium notificationCenter] removeObserver:self name:Chat_DidOpen object:nil];
			
		}
	}
}

- (void)addContextDisplayToWindow:(NSNotification *)notification
{
	AIChat	*chat = (AIChat *)[notification object];

	/*
	if(!logger)
		logger = (SMSQLiteLoggerPlugin *)[[[AIObject sharedAdiumInstance] componentLoader] pluginWithClassName:@"SMSQLiteLoggerPlugin"];
	*/
	//NSArray	*context = [logger context:linesToDisplay inChat:chat];
	NSArray	*context = [self context:linesToDisplay inChat:chat];
	
	if (context && [context count] > 0 && shouldDisplay) {
		//Check if the history fits the date restrictions
		
		/*
		NSCalendarDate *mostRecentMessage = [[(AIContentContext *)[context objectAtIndex:0] date] dateWithCalendarFormat:nil timeZone:nil];
		
		if ([self contextShouldBeDisplayed:mostRecentMessage]) {
			
			NSEnumerator * contextEnu = [context reverseObjectEnumerator];
			*/
		//XXXX what is going on here? :)
		NSCalendarDate *mostRecentMessage = [[(AIContentContext *)[context objectAtIndex:[context count]-1] date] dateWithCalendarFormat:nil timeZone:nil];
		if ([self contextShouldBeDisplayed:mostRecentMessage]) {
			NSEnumerator * contextEnu = [context objectEnumerator];
			
			AIContentContext	*contextMessage;
			//Add messages until: we add our max (linesToDisplay) OR we run out of saved messages
			while((contextMessage = [contextEnu nextObject])) {
				/* Don't display immediately, so the message view can aggregate multiple message history items.
				 * As required, we post Content_ChatDidFinishAddingUntrackedContent when finished adding. */
				[contextMessage setDisplayContentImmediately:NO];
				
				[[adium contentController] displayContentObject:contextMessage
											usingContentFilters:YES
													immediately:YES];
			}

		//We finished adding untracked content
		[[adium notificationCenter] postNotificationName:Content_ChatDidFinishAddingUntrackedContent
												  object:chat];

		} /* [self contextShouldBeDisplayed:mostRecentMessage] */
	} /* chatDict && shouldDisplay && linesToDisplay > 0  */
}


- (BOOL)contextShouldBeDisplayed:(NSCalendarDate *)inDate
{
	BOOL dateIsGood = YES;
	int thresholdDays = 0;
	int thresholdHours = 0;
	
	if (displayMode != MODE_ALWAYS) {
		
		if (displayMode == MODE_HAVE_TALKED) {
			if (haveTalkedUnits == UNIT_DAYS)
				thresholdDays = haveTalkedDays;
			
			else if (haveTalkedUnits == UNIT_HOURS)
				thresholdHours = haveTalkedDays;
			
		} else if (displayMode == MODE_HAVE_NOT_TALKED) {
			if ( haveTalkedUnits == UNIT_DAYS )
				thresholdDays = haveNotTalkedDays;
			else if (haveTalkedUnits == UNIT_HOURS)
				thresholdHours = haveNotTalkedDays;
		}
		
		// Take the most recent message's date, add our limits to it
		// See if the new date is earlier or later than today's date
		NSCalendarDate *newDate = [inDate dateByAddingYears:0 months:0 days:thresholdDays hours:thresholdHours minutes:0 seconds:0];

		NSComparisonResult comparison = [newDate compare:[NSDate date]];
		
		if (((displayMode == MODE_HAVE_TALKED) && (comparison == NSOrderedAscending)) ||
			((displayMode == MODE_HAVE_NOT_TALKED) && (comparison == NSOrderedDescending)) ) {
			dateIsGood = NO;
		}
	}
	
	return dateIsGood;
}

#pragma mark Old school
- (void)setupOldSchoolHistory
{
	//Observe chats closing
	[[adium notificationCenter] addObserver:self
								   selector:@selector(saveContextForObject:)
									   name:Chat_WillClose
									 object:nil];
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
	if (chat && ![chat isGroupChat]) {
		dict = [NSMutableDictionary dictionary];
		
		enumerator = [[chat contentObjectArray] objectEnumerator];
		
		//Is there already stored context for this person?
		previousDict = [[chat listObject] preferenceForKey:KEY_MESSAGE_CONTEXT group:PREF_GROUP_CONTEXT_DISPLAY];
		
		cnt = 1;
		
		// Only save if we need to save more AND there is still unsaved content available
		while ((cnt <= linesToDisplay) && (content = [enumerator nextObject])) {
			// Only record actual messages, no status
			if ([content isKindOfClass:[AIContentMessage class]] || [content isKindOfClass:[AIContentContext class]]) {
				contentDict = [self savableContentObject:content];
				[dict setObject:contentDict forKey:[[NSNumber numberWithInt:cnt] stringValue]];
				cnt++;
			}
			
		}
		
		// If there's room left, append the old messages too
		if (cnt <= linesToDisplay && previousDict) {
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
	NSString			*accountNumber;
	
	contentDict = [NSMutableDictionary dictionary];
	[contentDict setObject:[content type] forKey:@"Type"];
	
	objectID = [listContact internalUniqueObjectID];
	accountNumber = [[chat account] internalObjectID];
	
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
	[contentDict setObject:[[[(AIContentMessage *)content message] attributedStringByConvertingAttachmentsToStrings] dataRepresentation] forKey:@"Message"];
	
	return(contentDict);
}


- (NSArray *)context:(int)inLinesToDisplay inChat:(AIChat *)chat
{
	NSString			*type;
	NSAttributedString  *message;
	AIContentContext	*responseContent;
	id					source;
	id					dest;
	BOOL				isContext = YES;
	NSMutableArray		*context = nil;

	NSDictionary	*chatDict = [[chat listObject] preferenceForKey:KEY_MESSAGE_CONTEXT group:PREF_GROUP_CONTEXT_DISPLAY];
	NSDictionary	*messageDict;
	
	if (chatDict && inLinesToDisplay > 0) {
		//Max number of lines to display
		int cnt = (([chatDict count] >= linesToDisplay) ? linesToDisplay : [chatDict count]);
		
		context = [NSMutableArray array];
		//Add messages until: we add our max (linesToDisplay) OR we run out of saved messages
		while ((messageDict = [chatDict objectForKey:[[NSNumber numberWithInt:cnt] stringValue]]) && cnt > 0) {
			cnt--;
			
			type = [messageDict objectForKey:@"Type"];
			
			//Currently, we only add Message or Context content objects
			if( [type isEqualToString:CONTENT_MESSAGE_TYPE] || [type isEqualToString:CONTENT_CONTEXT_TYPE] ) {
				message = [NSAttributedString stringWithData:[messageDict objectForKey:@"Message"]];
				
				// The other person is always the one we're chatting with right now
				if ([[messageDict objectForKey:@"Outgoing"] boolValue]) {
					dest = [chat listObject];
					
					id from = [messageDict objectForKey:@"From"];
					if (![from isKindOfClass:[NSString class]]){
						if ([from respondsToSelector:@selector(stringValue)]){
							from = [from stringValue];
						}else{
							from = nil;
						}
					}
					
					source = [[adium accountController] accountWithInternalObjectID:from];
				} else {
					source = [chat listObject];
					
					id to = [messageDict objectForKey:@"To"];
					if (![to isKindOfClass:[NSString class]]){
						if ([to respondsToSelector:@selector(stringValue)]){
							to = [to stringValue];
						}else{
							to = nil;
						}
					}
					
					dest = [[adium accountController] accountWithInternalObjectID:to];
				}
				
				// Make the message response if all is well
				if(message && source && dest) {
					// Make the message appear as context if isContext is true or it was a context object
					// last time or if we should always dim recent context. Make a regular message otherwise
					if(isContext || [type isEqualToString:CONTENT_CONTEXT_TYPE] || dimRecentContext) {
						responseContent = [AIContentContext messageInChat:chat
															   withSource:source
															  destination:dest
																	 date:[NSDate dateWithNaturalLanguageString:[messageDict objectForKey:@"Date"]]
																  message:message
																autoreply:[[messageDict objectForKey:@"Autoreply"] boolValue]];
					} else {	
						responseContent = [AIContentMessage messageInChat:chat
															   withSource:source
															  destination:dest
																	 date:[NSDate dateWithNaturalLanguageString:[messageDict objectForKey:@"Date"]]
																  message:message
																autoreply:[[messageDict objectForKey:@"Autoreply"] boolValue]];							
						[responseContent setTrackContent:NO];
						[responseContent setPostProcessContent:NO];
					}
					
					if (responseContent){
						[context addObject:responseContent];
					}
				}
			}
		}
	}
	
	return context;
}


@end

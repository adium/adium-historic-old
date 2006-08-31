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

#import <Adium/AIContentControllerProtocol.h>
#import <Adium/AIPreferenceControllerProtocol.h>
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
#import <Adium/AIAccountControllerProtocol.h>

//omg crawsslinkz
#import "AILoggerPlugin.h"

//LMX
#import <LMX/LMXParser.h>
#import <Adium/AIXMLElement.h>
#import <AIUtilities/AIStringAdditions.h>
#import "unistd.h"
#import <AIUtilities/NSCalendarDate+ISO8601Parsing.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIHTMLDecoder.h>

/**
 * @class DCMessageContextDisplayPlugin
 * @brief Component to display in-window message history
 *
 * The amount of history, and criteria of when to display history, are determined in the Advanced->Message History preferences.
 */
@interface DCMessageContextDisplayPlugin (PRIVATE)
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime;
- (BOOL)contextShouldBeDisplayed:(NSCalendarDate *)inDate;
- (NSArray *)contextForChat:(AIChat *)chat;
@end

@implementation DCMessageContextDisplayPlugin

/**
 * @brief Install
 */
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
}

/**
 * @brief Uninstall
 */
- (void)uninstallPlugin
{
	[[adium preferenceController] unregisterPreferenceObserver:self];
	[[adium notificationCenter] removeObserver:self];
}

/**
 * @brief Preferences for when to display history changed
 *
 * Only change our preferences in response to global preference notifications; specific objects use this group as well.
 */
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	if (!object) {
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

/**
 * @brief Retrieve and display in-window message history
 *
 * Called in response to the Chat_DidOpen notification
 */
- (void)addContextDisplayToWindow:(NSNotification *)notification
{
	AIChat	*chat = (AIChat *)[notification object];	
	NSArray	*context = [self contextForChat:chat];

	if (context && [context count] > 0 && shouldDisplay) {
		//Check if the history fits the date restrictions
		
		//The most recent message is what determines whether we have "chatted in the last X days", "not chatted in the last X days", etc.
		NSCalendarDate *mostRecentMessage = [[(AIContentContext *)[context objectAtIndex:[context count]-1] date] dateWithCalendarFormat:nil timeZone:nil];
		if ([self contextShouldBeDisplayed:mostRecentMessage]) {
			NSEnumerator		*enumerator;
			AIContentContext	*contextMessage;

			enumerator = [context objectEnumerator];
			while((contextMessage = [enumerator nextObject])) {
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

		}
	}
}

/**
 * @brief Does a specified date match our criteria for display?
 *
 * The date passed should be the date of the _most recent_ stored message history item
 *
 * @result YES if the mesage history should be displayed
 */
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

/*!
 * @brief Retrieve the message history for a particular chat
 *
 * Asks AILoggerPlugin for the path to the right file, and then uses LMX to parse that file backwards.
 */
- (NSArray *)contextForChat:(AIChat *)chat
{
	//If there's no log there, there's no message history. Bail out.
	NSString *logPath = [AILoggerPlugin pathToNewestLogFileForChat:chat];
	if(!logPath) return nil;
	
	//Create the parser and set ourselves as the delegate
	LMXParser *parser = [LMXParser parser];
	[parser setDelegate:self];
	
	//Initialize the found messages array for us-as-delegate
	foundElements = [NSMutableArray arrayWithCapacity:linesToDisplay];
	elementStack = [NSMutableArray array];

	//Open up the file we need to read from, and seek to the end (this is a *backwards* parser, after all :)
	NSFileHandle *file = [NSFileHandle fileHandleForReadingAtPath:logPath];
	[file seekToEndOfFile];
	NSLog(@"Log path: %@", logPath);
	
	//Set up some more doohickeys and then start the parse loop
	int pageSize = getpagesize();
	unsigned long long offset = [file offsetInFile];
	enum LMXParseResult result = LMXParsedIncomplete;
	int omglooping = 0; //for debugging
	do {
		if (omglooping++) NSLog(@"OMG LOOPING!!!1");
		NSLog(@"Initial offset: %d", offset);
		//Calculate the new offset
		offset = (offset <= pageSize) ? 0 : offset - pageSize;
		NSLog(@"Start reading from offset: %ull", offset);
		
		//Seek to it and read
		[file seekToFileOffset:offset]; 
		NSData *chunk = [file readDataOfLength:pageSize];
		NSLog(@"Chunk as parse (as string): %@", [NSString stringWithData:chunk encoding:NSUTF8StringEncoding]);
		
		//Parse
		result = [parser parseChunk:chunk];
		
		NSLog(@"Done parsing.");
		
	//Continue to parse as long as we need more elements, we have data to read, and LMX doesn't think we're done.
	} while ([foundElements count] < linesToDisplay && offset > 0 && result != LMXParsedCompletely);
	
	NSString *serviceName = [[[[[logPath stringByDeletingLastPathComponent] stringByDeletingLastPathComponent] lastPathComponent] componentsSeparatedByString:@"."] objectAtIndex:0U];
	
	NSMutableArray *foundContentContexts = [NSMutableArray arrayWithCapacity:linesToDisplay]; 
	NSEnumerator *enumerator = [foundElements objectEnumerator];
	AIXMLElement *element = nil;
	while ((element = [enumerator nextObject])) {
		NSDictionary *attributesDictionary = [element attributes];
		NSString *autoreplyAttribute = [[element name] isEqualToString:@"message"] ? [attributesDictionary objectForKey:@"auto"] : nil;
		NSString *sender = [NSString stringWithFormat:@"%@.%@", serviceName, [attributesDictionary objectForKey:@"sender"]];
		AIAccount *account = [chat account];
		NSString *accountID = [NSString stringWithFormat:@"%@.%@", [account serviceID], [account UID]];
		BOOL sentByMe = ([sender isEqualToString:accountID] == NSOrderedSame);
		AIContentContext *message = [AIContentContext messageInChat:chat 
														 withSource:(sentByMe ? account : [[adium contactController] existingListObjectWithUniqueID:sender])
														destination:(sentByMe ? [[adium contactController] existingListObjectWithUniqueID:sender] : account)
															   date:[NSCalendarDate calendarDateWithString:[attributesDictionary objectForKey:@"time"]]
															message:[[AIHTMLDecoder decoder] decodeHTML:[element contentsAsXMLString]]
														  autoreply:(autoreplyAttribute && [autoreplyAttribute caseInsensitiveCompare:@"yes"] == NSOrderedSame)];
		[foundContentContexts addObject:message];
	}
	return foundContentContexts;
}

#pragma mark LMX delegate

- (void)parser:(LMXParser *)parser elementEnded:(NSString *)elementName
{
	if ([elementName isEqualToString:@"message"] || [elementName isEqualToString:@"status"] || [elementName isEqualToString:@"event"]) {
		[elementStack insertObject:[AIXMLElement elementWithName:elementName] atIndex:0U];
		NSLog(@"inserted %@ to stack. stack is now: %@", elementName, elementStack);
	}
	else if ([elementStack count]) {
		AIXMLElement *element = [AIXMLElement elementWithName:elementName];
		[(AIXMLElement *)[elementStack objectAtIndex:0U] insertObject:element atIndex:0U];
		[elementStack insertObject:element atIndex:0U];
		NSLog(@"inserted %@ to stack. stack is now: %@", elementName, elementStack);

	}
}

- (void)parser:(LMXParser *)parser foundCharacters:(NSString *)string
{
	if ([elementStack count])
		[(AIXMLElement *)[elementStack objectAtIndex:0U] addObject:string];
}

- (void)parser:(LMXParser *)parser elementStarted:(NSString *)elementName attributes:(NSDictionary *)attributes
{
	if (![elementName isEqualToString:@"chat"]) {
		AIXMLElement *element = [elementStack objectAtIndex:0U];
		if (attributes) {
			NSLog(@"Setting element %@ to have attributes %@", element, attributes);
			[element setAttributeNames:[attributes allKeys] values:[attributes allValues]];
			NSLog(@"Set!");
		}
		
		if ([elementName isEqualToString:@"message"] || 
			[elementName isEqualToString:@"status"] || 
			([elementName isEqualToString:@"event"] &&
				![[attributes objectForKey:@"type"] isEqualToString:@"windowOpened"] && 
				![[attributes objectForKey:@"type"] isEqualToString:@"windowClosed"]))
		{
			[foundElements insertObject:element atIndex:0U];
		}
		NSLog(@"stack before remove: %@", elementStack);
		[elementStack removeObjectAtIndex:0U];
		NSLog(@"stack after remove: %@", elementStack);
		if ([foundElements count] == linesToDisplay) {
			if ([elementStack count]) [elementStack removeAllObjects];
			[parser abortParsing];
		}
	}
}

@end

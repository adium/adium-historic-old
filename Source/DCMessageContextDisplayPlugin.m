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
		NSCalendarDate *mostRecentMessage = [[(AIContentContext *)[context lastObject] date] dateWithCalendarFormat:nil timeZone:nil];
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

static int linesLeftToFind = 0;
/*!
 * @brief Retrieve the message history for a particular chat
 *
 * Asks AILoggerPlugin for the path to the right file, and then uses LMX to parse that file backwards.
 */
- (NSArray *)contextForChat:(AIChat *)chat
{
	//If there's no log there, there's no message history. Bail out.
	NSArray *logPaths = [AILoggerPlugin sortedArrayOfLogFilesForChat:chat];
	if(!logPaths) return nil;
		
	NSString *logObjectUID = [chat name];
	if (!logObjectUID) logObjectUID = [[chat listObject] UID];
	logObjectUID = [logObjectUID safeFilenameString];

	NSString *baseLogPath = [[AILoggerPlugin logBasePath] stringByAppendingPathComponent:
		[AILoggerPlugin relativePathForLogWithObject:logObjectUID onAccount:[chat account]]];
			
	//Initialize a place to store found messages
	NSMutableArray *outerFoundContentContexts = [NSMutableArray arrayWithCapacity:linesToDisplay]; 

	//Set up the counter variable
	linesLeftToFind = linesToDisplay;

	//Iterate over the elements of the log path array.
	NSEnumerator *pathsEnumerator = [logPaths objectEnumerator];
	NSString *logPath = nil;
	while (linesLeftToFind > 0 && (logPath = [pathsEnumerator nextObject])) {
		//If it's not a .chatlog, ignore it.
		if (![logPath hasSuffix:@".chatlog"])
			continue;
				
		//Stick the base path on to the beginning
		logPath = [baseLogPath stringByAppendingPathComponent:logPath];
		NSLog(@"Message History: Loading log file: %@", logPath);
		
		//Initialize the found messages array and element stack for us-as-delegate
		foundElements = [NSMutableArray arrayWithCapacity:linesToDisplay];
		elementStack = [NSMutableArray array];

		//Initialize a place to store found messages, locally
		NSMutableArray *innerFoundContentContexts = [NSMutableArray arrayWithCapacity:linesLeftToFind]; 

		//Create the parser and set ourselves as the delegate
		LMXParser *parser = [LMXParser parser];
		[parser setDelegate:self];

		//Open up the file we need to read from, and seek to the end (this is a *backwards* parser, after all :)
		NSFileHandle *file = [NSFileHandle fileHandleForReadingAtPath:logPath];
		[file seekToEndOfFile];
		
		//Set up some more doohickeys and then start the parse loop
		int pageSize = getpagesize();
		unsigned long long offset = [file offsetInFile];
		enum LMXParseResult result = LMXParsedIncomplete;
		do {
			//Calculate the new offset
			offset = (offset <= pageSize) ? 0 : offset - pageSize;
			
			//Seek to it and read
			[file seekToFileOffset:offset]; 
			NSData *chunk = [file readDataOfLength:pageSize];
			
			//Parse
			result = [parser parseChunk:chunk];
			
		//Continue to parse as long as we need more elements, we have data to read, and LMX doesn't think we're done.
		} while ([foundElements count] < linesLeftToFind && offset > 0 && result != LMXParsedCompletely);
		//Be a good citizen and close the file
		[file closeFile];
				
		//Get the service name from the path name
		NSString *serviceName = [[[[[logPath stringByDeletingLastPathComponent] stringByDeletingLastPathComponent] lastPathComponent] componentsSeparatedByString:@"."] objectAtIndex:0U];
		
		//Enumerate over the found elements
		NSEnumerator *enumerator = [foundElements objectEnumerator];
		AIXMLElement *element = nil;
		AIListObject *account = [chat account];
		NSString	 *accountID = [NSString stringWithFormat:@"%@.%@", [account serviceID], [account UID]];

		while ((element = [enumerator nextObject])) {
			//Set up some doohickers.
			NSDictionary	*attributesDictionary = [element attributes];
			NSString		*sender = [NSString stringWithFormat:@"%@.%@", serviceName, [attributesDictionary objectForKey:@"sender"]];
			BOOL			sentByMe = ([sender isEqualToString:accountID]);
			NSString		*autoreplyAttribute = [attributesDictionary objectForKey:@"auto"];
			NSString		*timeString = [attributesDictionary objectForKey:@"time"];
			//Create the context object
			//http://www.visualdistortion.org/crash/view.jsp?crash=211821
			if (timeString) {
				NSLog(@"Message Context Display: Parsing message time attribute %@", timeString);
				AIContentContext *message = [AIContentContext messageInChat:chat 
																 withSource:(sentByMe ? account : [chat listObject])
																destination:(sentByMe ? [chat listObject] : account)
																	   date:[NSCalendarDate calendarDateWithString:timeString]
																	message:[[AIHTMLDecoder decoder] decodeHTML:[element contentsAsXMLString]]
																  autoreply:(autoreplyAttribute && [autoreplyAttribute caseInsensitiveCompare:@"true"] == NSOrderedSame)];
				//Don't log this object
				[message setPostProcessContent:NO];
				
				//Add it to the array
				[innerFoundContentContexts addObject:message];
				
				//If we've found enough, stop drop and roll!
				if ([innerFoundContentContexts count] >= linesLeftToFind)
					break;
			} else {
				NSLog(@"Null message context display time for %@",element);
			}
		}

		//Add our locals to the outer array; we're probably looping again.
		[outerFoundContentContexts setArray:[innerFoundContentContexts arrayByAddingObjectsFromArray:outerFoundContentContexts]];
		linesLeftToFind -= [outerFoundContentContexts count];
	}
	return outerFoundContentContexts;
}

#pragma mark LMX delegate

- (void)parser:(LMXParser *)parser elementEnded:(NSString *)elementName
{
	if ([elementName isEqualToString:@"message"]) {
		[elementStack insertObject:[AIXMLElement elementWithName:elementName] atIndex:0U];
	}
	else if ([elementStack count]) {
		AIXMLElement *element = [AIXMLElement elementWithName:elementName];
		[(AIXMLElement *)[elementStack objectAtIndex:0U] insertObject:element atIndex:0U];
		[elementStack insertObject:element atIndex:0U];
	}
}

- (void)parser:(LMXParser *)parser foundCharacters:(NSString *)string
{
	if ([elementStack count])
		[(AIXMLElement *)[elementStack objectAtIndex:0U] insertObject:string atIndex:0U];
}

- (void)parser:(LMXParser *)parser elementStarted:(NSString *)elementName attributes:(NSDictionary *)attributes
{
	if ([elementStack count]) {
		AIXMLElement *element = [elementStack objectAtIndex:0U];
		if (attributes) {
			[element setAttributeNames:[attributes allKeys] values:[attributes allValues]];
		}
		
		if ([elementName isEqualToString:@"message"])
			[foundElements insertObject:element atIndex:0U];

		[elementStack removeObjectAtIndex:0U];
		if ([foundElements count] == linesLeftToFind) {
			if ([elementStack count]) [elementStack removeAllObjects];
			[parser abortParsing];
		}
	}
}

@end

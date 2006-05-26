//
//  AIMDLogViewerWindowController.m
//  Adium
//
//  Created by Evan Schoenberg on 3/1/06.
//

#import "AIMDLogViewerWindowController.h"
#import <AIUtilities/AIArrayAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import "AILoggerPlugin.h"
#import "AILogToGroup.h"
#import "AILogFromGroup.h"
#import "AIChatLog.h"
#import "AIContactController.h"

@implementation AIMDLogViewerWindowController

/*
 * @brief Perform a content search of the indexed logs
 *
 * This uses the 10.4+ asynchronous search functions.
 * Google-like search syntax (phrase, prefix/suffix, boolean, etc. searching) is automatically supported.
 */
- (void)_logContentFilter:(NSString *)searchString searchID:(int)searchID
{
	SKIndexRef			logSearchIndex = [plugin logContentIndex];
	float				largestRankingValue = 0;

	if (currentSearch) {
		SKSearchCancel(currentSearch);
		CFRelease(currentSearch); currentSearch = NULL;
	}

	currentSearch = SKSearchCreate(logSearchIndex,
								   (CFStringRef)searchString,
								   kSKSearchOptionDefault);
	
    Boolean more = true;
    UInt32 totalCount = 0;

	//Retrieve matches as long as more are pending
    while (more && currentSearch) {
#define BATCH_NUMBER 100
        SKDocumentID	foundDocIDs[BATCH_NUMBER];
        float			foundScores[BATCH_NUMBER];
        SKDocumentRef	foundDocRefs[BATCH_NUMBER];

        CFIndex foundCount = 0;
        CFIndex i;
		
        more = SKSearchFindMatches (
									currentSearch,
									BATCH_NUMBER,
									foundDocIDs,
									foundScores,
									0.5, // maximum time before func returns, in seconds
									&foundCount
									);
		
        totalCount += foundCount;
		
        SKIndexCopyDocumentRefsForDocumentIDs (
											   logSearchIndex,
											   foundCount,
											   foundDocIDs,
											   foundDocRefs
											   );
        for (i = 0; ((i < foundCount) && (searchID == activeSearchID)) ; i++) {
			SKDocumentRef	document = foundDocRefs[i];
			CFURLRef		url = SKDocumentCopyURL(document);
			CFStringRef		logPath = CFURLCopyFileSystemPath(url, kCFURLPOSIXPathStyle);
			NSArray			*pathComponents = [(NSString *)logPath pathComponents];
			
			//Don't test for the date now; we'll test once we've found the AIChatLog if we make it that far
			if ([self searchShouldDisplayDocument:document pathComponents:pathComponents testDate:NO]) {
				unsigned int	numPathComponents = [pathComponents count];
				NSString		*toPath = [NSString stringWithFormat:@"%@/%@",
					[pathComponents objectAtIndex:numPathComponents-3],
					[pathComponents objectAtIndex:numPathComponents-2]];
				NSString		*path = [NSString stringWithFormat:@"%@/%@",toPath,[pathComponents objectAtIndex:numPathComponents-1]];
				AIChatLog		*theLog;
				
				/* Add the log - if our index is currently out of date (for example, a log was just deleted) 
				 * we may get a null log, so be careful.
				 */
				theLog = [[logToGroupDict objectForKey:toPath] logAtPath:path];
				[resultsLock lock];
				if ((theLog != nil) &&
					(![currentSearchResults containsObjectIdenticalTo:theLog]) &&
					[self chatLogMatchesDateFilter:theLog]) {
					[theLog setRankingValueOnArbitraryScale:foundScores[i]];
					
					//SearchKit does not normalize ranking scores, so we track the largest we've found and use it as 1.0
					if (foundScores[i] > largestRankingValue) largestRankingValue = foundScores[i];

					[currentSearchResults addObject:theLog];
				} else {
					//Didn't get a valid log, so decrement our totalCount which is tracking how many logs we found
					totalCount--;
				}
				[resultsLock unlock];					
				
			} else {
				//Didn't add this log, so decrement our totalCount which is tracking how many logs we found
				totalCount--;
			}
			
			CFRelease(logPath);
			CFRelease(url);
			CFRelease(document);
        }
		
		//Scale all logs' ranking values to the largest ranking value we've seen thus far
		[resultsLock lock];
		for (i = 0; ((i < totalCount) && (searchID == activeSearchID)); i++) {
			AIChatLog	*theLog = [currentSearchResults objectAtIndex:i];
			[theLog setRankingPercentage:([theLog rankingValueOnArbitraryScale] / largestRankingValue)];
		}
		[resultsLock unlock];

		[self performSelectorOnMainThread:@selector(updateProgressDisplay)
							   withObject:nil
							waitUntilDone:NO];
		
		if (searchID != activeSearchID) {
			more = FALSE;
		}
    }
	
	if (currentSearch) {
		CFRelease(currentSearch);
		currentSearch = NULL;
	}
}

- (void)stopSearching
{	
	if (currentSearch) {
		SKSearchCancel(currentSearch);
		CFRelease(currentSearch); currentSearch = nil;
	}

	[super stopSearching];
}

#pragma mark Date type menu

- (void)configureDateFilter
{
	[super configureDateFilter];
	
	[datePicker setDateValue:[NSDate date]];
}

- (IBAction)selectDate:(id)sender
{
	[filterDate release];
	filterDate = [[[datePicker dateValue] dateWithCalendarFormat:nil timeZone:nil] retain];

	[self startSearchingClearingCurrentResults:YES];
}

- (NSMenu *)dateTypeMenu
{
	NSMenu		*dateTypeMenu = [super dateTypeMenu];
	AIDateType	dateType;
	NSDictionary *dateTypeTitleDict = [NSDictionary dictionaryWithObjectsAndKeys:
		AILocalizedString(@"Exactly", nil), [NSNumber numberWithInt:AIDateTypeExactly],
		AILocalizedString(@"Before", nil), [NSNumber numberWithInt:AIDateTypeBefore],
		AILocalizedString(@"After", nil), [NSNumber numberWithInt:AIDateTypeAfter],
		nil];

	[dateTypeMenu addItem:[NSMenuItem separatorItem]];		

	for (dateType = AIDateTypeExactly; dateType <= AIDateTypeAfter; dateType++) {
		[dateTypeMenu addItem:[self _menuItemForDateType:dateType dict:dateTypeTitleDict]];
	}

	return dateTypeMenu;
}

/*
 * @brief A new date type was selected
 *
 * The date picker will be hidden/revealed as appropriate.
 * This does not start a search
 */ 
- (void)selectedDateType:(AIDateType)dateType
{
	BOOL			showDatePicker = NO;

	[super selectedDateType:dateType];

	switch (dateType) {
		case AIDateTypeExactly:
			filterDateType = AIDateTypeExactly;
			filterDate = [[[datePicker dateValue] dateWithCalendarFormat:nil timeZone:nil] retain];
			showDatePicker = YES;
			break;
			
		case AIDateTypeBefore:
			filterDateType = AIDateTypeBefore;
			filterDate = [[[datePicker dateValue] dateWithCalendarFormat:nil timeZone:nil] retain];
			showDatePicker = YES;
			break;
			
		case AIDateTypeAfter:
			filterDateType = AIDateTypeAfter;
			filterDate = [[[datePicker dateValue] dateWithCalendarFormat:nil timeZone:nil] retain];
			showDatePicker = YES;
			break;
			
		default:
			showDatePicker = NO;
			break;
	}
	
	BOOL updateSize = NO;
	if (showDatePicker && [datePicker isHidden]) {
		[datePicker setHidden:NO];		
		updateSize = YES;
		
	} else if (!showDatePicker && ![datePicker isHidden]) {
		[datePicker setHidden:YES];
		updateSize = YES;
	}
	
	if (updateSize) {
		NSEnumerator *enumerator = [[[[self window] toolbar] items] objectEnumerator];
		NSToolbarItem *toolbarItem;
		while ((toolbarItem = [enumerator nextObject])) {
			if ([[toolbarItem itemIdentifier] isEqualToString:DATE_ITEM_IDENTIFIER]) {
				NSSize newSize = NSMakeSize(([datePicker isHidden] ? 180 : 290), NSHeight([view_DatePicker frame]));
				[toolbarItem setMinSize:newSize];
				[toolbarItem setMaxSize:newSize];
				break;
			}
		}		
	}
}

- (NSString *)dateItemNibName
{
	return @"LogViewerDateFilter";
}

#if 0
/*
 * @brief Return a predicate for searching for a contact, given a key
 *
 * Note that this will work best when accounts are connected, since the contactController only knows about metaContacts while disconnected.
 *
 * @param inString A string which will be searched as (1) the start of a UID and (2) a fragment of a display name. Both are case insensitive
 * @param key The key, such as com_adiumX_chatSource or com_adiumX_chatDestination, on which to base the predicate
 *
 * @result An NSPredicate which ORs together each possible search term for inString, based on Adium's contact information.
 */
- (NSPredicate *)predicateForContactString:(NSString *)inString key:(NSString *)key
{
	NSPredicate		*predicate;
	
	//Use a set to avoid duplicatation of query terms
	NSMutableSet	*searchStrings = [NSMutableSet set];
	NSString		*searchString;
	AIListContact	*contact;

    NSEnumerator	*enumerator = [[[adium contactController] allContactsInGroup:nil subgroups:YES onAccount:nil] objectEnumerator];
    while ((contact = [enumerator nextObject])) {
		if ([[contact displayName] rangeOfString:inString options:NSCaseInsensitiveSearch].location  != NSNotFound) {
			if ([contact isKindOfClass:[AIMetaContact class]]) {
				NSEnumerator	*subEnumerator = [[(AIMetaContact *)contact containedObjects] objectEnumerator];
				AIListContact	*containedContact;
				while ((containedContact = [subEnumerator nextObject])) {
					[searchStrings addObject:[[containedContact UID] compactedString]];
				}
			} else {
				[searchStrings addObject:[[contact UID] compactedString]];
			}
		}
	}
	
	[searchStrings addObject:[NSString stringWithFormat:@"%@*", [inString compactedString]]];

	//NSCompoundPredicate will throw an exception if passed an array of one predicate
	if ([searchStrings count] > 1) {
		NSMutableArray	*predicates = [NSMutableArray array];

		enumerator = [searchStrings objectEnumerator];
		while ((searchString = [enumerator nextObject])) {
			[predicates addObject:[NSPredicateClass predicateWithFormat:@"%K like[c] %@", key, searchString]];
		}
		
		predicate = [NSCompoundPredicateClass orPredicateWithSubpredicates:predicates];
	} else {
		searchString = [searchStrings anyObject];
		predicate = [NSPredicateClass predicateWithFormat:@"%K like[c] %@", key, searchString];
	}
	
	return predicate;
}
#endif

@end

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

//Perform a content search of the indexed logs
- (void)_logContentFilter:(NSString *)searchString searchID:(int)searchID
{
	SKIndexRef			logSearchIndex = [plugin logContentIndex];
	SKSearchRef			search;
	float				largestRankingValue = 0;
	
	search = SKSearchCreate(logSearchIndex,
							(CFStringRef)searchString,
							kSKSearchOptionDefault);
	
    Boolean more = true;
    UInt32 totalCount = 0;

	//Retrieve matches as long as more are pending
    while (more) {
#define BATCH_NUMBER 100
        SKDocumentID	foundDocIDs[BATCH_NUMBER];
        float			foundScores[BATCH_NUMBER];
        SKDocumentRef	foundDocRefs[BATCH_NUMBER];

        CFIndex foundCount = 0;
        CFIndex i;
		
        more = SKSearchFindMatches (
									search,
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
        for (i = 0; i < foundCount; i++) {
			SKDocumentRef	document = foundDocRefs[i];
			CFURLRef		url = SKDocumentCopyURL(document);
			CFStringRef		logPath = CFURLCopyFileSystemPath(url, kCFURLPOSIXPathStyle);
			NSArray			*pathComponents = [(NSString *)logPath pathComponents];
			unsigned int	numPathComponents = [pathComponents count];
			
			NSString	*toPath = [NSString stringWithFormat:@"%@/%@",
				[pathComponents objectAtIndex:numPathComponents-3],
				[pathComponents objectAtIndex:numPathComponents-2]];
			NSString	*path = [NSString stringWithFormat:@"%@/%@",toPath,[pathComponents objectAtIndex:numPathComponents-1]];
			AIChatLog	*theLog;
			
			/*	
				Add the log - if our index is currently out of date (for example, a log was just deleted) 
			 we may get a null log, so be careful.
			 */
			[resultsLock lock];
			theLog = [[logToGroupDict objectForKey:toPath] logAtPath:path];
			if ((theLog != nil) && (![currentSearchResults containsObjectIdenticalTo:theLog])) {
				[theLog setRankingValueOnArbitraryScale:foundScores[i]];
				
				//SearchKit does not normalize ranking scores, so we track the largest we've found and use it as 1.0
				if (foundScores[i] > largestRankingValue) largestRankingValue = foundScores[i];
				
				[currentSearchResults addObject:theLog];

			} else {
				totalCount--;
			}
			[resultsLock unlock];
			
			CFRelease(logPath);
			CFRelease(url);
			CFRelease(document);
        }
		
		//Scale all logs' ranking values to the largest ranking value we've seen thus far
		[resultsLock lock];
		for (i = 0; i < totalCount; i++) {
			AIChatLog	*theLog = [currentSearchResults objectAtIndex:i];
			[theLog setRankingPercentage:([theLog rankingValueOnArbitraryScale] / largestRankingValue)];
		}
		[resultsLock unlock];

		[self performSelectorOnMainThread:@selector(updateProgressDisplay)
							   withObject:nil
							waitUntilDone:NO];
    }
	
	CFRelease(search);	
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
/*
- (NSSet *)selectedItemsInTable:(NSTableView *)tableView basedOnArray:(NSArray *)inArray
{	
	NSMutableSet 	*itemSet = nil;
	id 				item;
	
	//Apple wants us to do some pretty crazy stuff for selections in 10.3
	NSIndexSet *indices = [tableView selectedRowIndexes];
	unsigned int bufSize = [indices count];
	unsigned int *buf = malloc(bufSize + sizeof(unsigned int));
	unsigned int i;
	
	//If the first item ("All") is selected, don't return any items, which means no filtering.
	if ([indices firstIndex] != 0) {
		itemSet = [NSMutableSet set];
		
		NSRange range = NSMakeRange([indices firstIndex], ([indices lastIndex]-[indices firstIndex]) + 1);
		[indices getIndexes:buf maxCount:bufSize inIndexRange:&range];
		
		for (i = 0; i != bufSize; i++) {
			//-1 because the first item in the table is the "All" item
			if ((item = [inArray objectAtIndex:(buf[i]-1)])) {
				[itemSet addObject:item];
			}
		}
	}
	
	free(buf);

	return itemSet;
}
*/

/*
 * @brief Configure to display the logs for a specified contact
 *
 * At present, filters on the contact's UID using the contact browser table
 */
- (void)filterForContact:(AIListContact *)listContact
{
	int contactIndex = [toArray indexOfObject:[listContact UID]];
	if (contactIndex == NSNotFound) {
		contactIndex = [toArray indexOfObject:[[listContact UID] compactedString]];
	}
	
	if (contactIndex != NSNotFound) {		
		//+1 to allow for the All entry at the top
		[tableView_toContacts selectRowIndexes:[NSIndexSet indexSetWithIndex:(contactIndex + 1)]
						  byExtendingSelection:NO];
		[tableView_toContacts scrollRowToVisible:(contactIndex + 1)];
	}
}

#pragma mark Browser table views delegate

- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	if (tableView == tableView_fromAccounts) {
		return ([fromArray count] + 1);
	} else if (tableView == tableView_toContacts) {
		return ([toArray count] + 1);
		
	} else if (tableView == tableView_dates) {
		return 0;
	} else {
		return [super numberOfRowsInTableView:tableView];
	}
}

#define ALL AILocalizedString(@"All", nil)

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	if (tableView == tableView_fromAccounts) {
		if (row == 0) {
			return ALL;
		} else {
			return [fromArray objectAtIndex:row-1];
		}
		
	} else if (tableView == tableView_toContacts) {
		if (row == 0) {
			return ALL;
		} else {
			return [toArray objectAtIndex:row-1];
		}
		
	} else if (tableView == tableView_dates) {
		if (row == 0) {
			return ALL;
		} else {
			return @"";
		}
		
	} else {
		return [super tableView:tableView objectValueForTableColumn:tableColumn row:row];
	}
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
	NSTableView	*tableView = [notification object];

	if ((tableView == tableView_fromAccounts) ||
		(tableView == tableView_toContacts) ||
		(tableView == tableView_dates)) {
		automaticSearch = YES;
		[self startSearchingClearingCurrentResults:YES];

	} else {
		[super tableViewSelectionDidChange:notification];
	}
}

#pragma mark Toolbar
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
    return [NSArray arrayWithObjects:@"delete", NSToolbarFlexibleSpaceItemIdentifier, @"search", nil];
}

@end

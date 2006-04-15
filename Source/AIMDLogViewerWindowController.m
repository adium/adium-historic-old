//
//  AIMDLogViewerWindowController.m
//  Adium
//
//  Created by Evan Schoenberg on 3/1/06.
//

//XXX - when we drop Panther support, the NSClassFromString() uses in here should die. -RAF

#import "AIMDLogViewerWindowController.h"
#import <AIUtilities/AIArrayAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import "AILoggerPlugin.h"
#import "AILogToGroup.h"
#import "AILogFromGroup.h"
#import "AIContactController.h"

#define NSMetadataQueryClass NSClassFromString(@"NSMetadataQuery")
#define NSCompoundPredicateClass NSClassFromString(@"NSCompoundPredicate")
#define NSPredicateClass NSClassFromString(@"NSPredicate")

@implementation AIMDLogViewerWindowController
+ (NSString *)nibName
{
	return @"MDLogViewer";
}

- (void)windowDidLoad
{	
	[super windowDidLoad];

	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(queryGatheringProgress:)
												 name:NSMetadataQueryGatheringProgressNotification
											   object:nil];	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(queryDidFinish:)
												 name:NSMetadataQueryDidFinishGatheringNotification
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(queryUpdate:)
												 name:NSMetadataQueryDidUpdateNotification
											   object:nil];    

	//Localize and center the column headers
	[[[[tableView_fromAccounts tableColumns] objectAtIndex:0] headerCell] setStringValue:ACCOUNT];
	[[[[tableView_fromAccounts tableColumns] objectAtIndex:0] headerCell] setAlignment:NSCenterTextAlignment];
	[[[[tableView_toContacts tableColumns] objectAtIndex:0] headerCell] setStringValue:DESTINATION];
	[[[[tableView_toContacts tableColumns] objectAtIndex:0] headerCell] setAlignment:NSCenterTextAlignment];
	[[[[tableView_dates tableColumns] objectAtIndex:0] headerCell] setStringValue:DATE];
	[[[[tableView_dates tableColumns] objectAtIndex:0] headerCell] setAlignment:NSCenterTextAlignment];
}

- (LogSearchMode)defaultSearchMode
{
	return LOG_SEARCH_CONTENT;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[super dealloc];
}

- (void)stopSearching
{
	if (currentQuery) {
		[currentQuery stopQuery];
		[currentQuery release]; currentQuery = nil;
	}

	[super stopSearching];
}

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

//Begin the current search
- (void)startSearchingClearingCurrentResults:(BOOL)clearCurrentResults
{
	NSMutableArray	*predicatesArray = [NSMutableArray array];

	[super startSearchingClearingCurrentResults:clearCurrentResults];

	currentQuery = [[NSMetadataQueryClass alloc] init];

	//Only search within our log folder
	//XXX need to escape ? and * if they are typed
	[currentQuery setSearchScopes:[NSArray arrayWithObject:[NSURL fileURLWithPath:[AILoggerPlugin logBasePath]]]];

	NSPredicate *queryPredicate;

	//Add the basic predicate for matching the file type
	[predicatesArray addObject:[NSPredicateClass predicateWithFormat:@"((kMDItemContentType = \"com.adiumx.log\") or (kMDItemContentType = \"com.adiumx.htmllog\"))"]];
	
	NSLog(@"Searching in mode %i",searchMode);

	switch (searchMode) {
		case LOG_SEARCH_FROM:
			if ([activeSearchString length]) {
				[predicatesArray addObject:[self predicateForContactString:activeSearchString key:@"com_adiumX_chatSource"]];
			}
			
			break;
		case LOG_SEARCH_TO:
			if ([activeSearchString length]) {
				[predicatesArray addObject:[self predicateForContactString:activeSearchString key:@"com_adiumX_chatDestination"]];
			}
			
			break;
		case LOG_SEARCH_DATE:
		{
			NSDate *searchStringDate = [NSDate dateWithNaturalLanguageString:activeSearchString];

			[predicatesArray addObject:[NSPredicateClass predicateWithFormat:@"kMDItemLastUsedDate like[c] %@",[NSString stringWithFormat:@"*%@*",[searchStringDate descriptionWithCalendarFormat:@"%y-%m-%d"
																																														 timeZone:nil
																																														   locale:nil]]]];
			break;
		}
		case LOG_SEARCH_CONTENT:
			if ([activeSearchString length]) {
				[predicatesArray addObject:[NSPredicateClass predicateWithFormat:@"kMDItemTextContent like[c] %@",[NSString stringWithFormat:@"*%@*",activeSearchString]]];
			}
			break;
	}

	NSEnumerator *enumerator;
	NSString	 *item;

	//Restrict to exact (case insensitive) matches on any selected accounts
	enumerator = [[self selectedItemsInTable:tableView_fromAccounts basedOnArray:fromArray] objectEnumerator];
	while ((item = [enumerator nextObject])) {
		[predicatesArray addObject:[NSPredicateClass predicateWithFormat:@"%K like[c] %@", @"com_adiumX_chatSource", item]];
	}

	//Restrict to exact (case insensitive) matches on any selected contacts
	enumerator = [[self selectedItemsInTable:tableView_toContacts basedOnArray:toArray] objectEnumerator];
	while ((item = [enumerator nextObject])) {
		[predicatesArray addObject:[NSPredicateClass predicateWithFormat:@"%K like[c] %@", @"com_adiumX_chatDestination", item]];
	}

	//Update the table periodically while the logs load.
	[refreshResultsTimer invalidate]; [refreshResultsTimer release];
	
	if ([predicatesArray count] > 1) {
		queryPredicate = [NSClassFromString(@"NSCompoundPredicate") andPredicateWithSubpredicates:predicatesArray];

		NSLog(@"Predicate is %@",queryPredicate);
		[currentQuery setPredicate:queryPredicate];
		
		//Presort the results... (?)
		//[currentQuery setSortDescriptors:[self sortDescriptors]];
		
		lastResult = 0;
		[currentQuery startQuery];
		
		refreshResultsTimer = [[NSTimer scheduledTimerWithTimeInterval:REFRESH_RESULTS_INTERVAL
																target:self
															  selector:@selector(refreshResults)
															  userInfo:nil
															   repeats:YES] retain];
	} else {
		//Just looking for any log...
		[NSThread detachNewThreadSelector:@selector(loadAllLogs:)
								 toTarget:self
							   withObject:[NSNumber numberWithInt:activeSearchID]];		
		
		refreshResultsTimer = [[NSTimer scheduledTimerWithTimeInterval:REFRESH_RESULTS_INTERVAL
																target:self
															  selector:@selector(refreshResultsAndSort)
															  userInfo:nil
															   repeats:YES] retain];		
	}
}

/*
 * @brief Process updates to our query, adding its new results to the currentSearchResults
 *
 * May be called from any thread.  Caller is responsible for actually updating the display at some point.
 */
- (void)processQueryUpdates:(NSNumber *)inSearchID
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSMetadataQuery *myQuery = [currentQuery retain];
	//+1 for the trailing slash
	unsigned logBaseLength = [[AILoggerPlugin logBasePath] length] + 1;
	int searchID = [inSearchID intValue];

	//Process the results

	unsigned count = [myQuery resultCount];
	int i = 0;
	while ((i < count) && (searchID == activeSearchID)) {
		NSString		*path = [[myQuery resultAtIndex:/*lastResult*/i++] valueForAttribute:(NSString *)kMDItemPath];
		//Path is a full path; we want everything after the base path since the old logging system used relative paths
		path = [path substringFromIndex:logBaseLength];
		
		NSString		*toPath = [path stringByDeletingLastPathComponent];
		AIChatLog		*theLog;

		[resultsLock lock];
		theLog = [[logToGroupDict objectForKey:toPath] logAtPath:path];
		if ((theLog != nil) && (![currentSearchResults containsObjectIdenticalTo:theLog]) && (searchID == activeSearchID)) {
			//			[theLog setRankingPercentage:outScoresArray[i]];
			//			NSLog(@"relevance is %@",[NSMetadataQueryResultContentRelevanceAttribute);
			[currentSearchResults addObject:theLog];
		}
		[resultsLock unlock];
	}
	
	NSLog(@"Processing complete...");

	[myQuery enableUpdates];
	[myQuery release];
	
	[self performSelectorOnMainThread:@selector(refreshResultsAndSort)
						   withObject:nil
						waitUntilDone:NO];
	[pool release];
}

- (void)processQueryUpdatesAndSort:(NSNumber *)inSearchID
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	[self processQueryUpdates:inSearchID];
	[self performSelectorOnMainThread:@selector(resortLogs)
						   withObject:nil
						waitUntilDone:NO];

	[pool release];
}

/*
 * @brief Called if our query updates after queryDidFinish: is called.
 *
 * Such updates will be small changes; we can handle them on the main thread.
 */
- (void)queryUpdate:(NSNotification *)inNotification
{
	NSLog(@"Query update...");
//	[self processQueryUpdates:[NSNumber numberWithInt:activeSearchID]];
//	[self searchComplete];
	[currentQuery disableUpdates];

	[NSThread detachNewThreadSelector:@selector(processQueryUpdatesAndSort:)
							 toTarget:self
						   withObject:[NSNumber numberWithInt:activeSearchID]];		
}

/*
 * @brief Called repeatedly in the initial gathering phase
 */
- (void)queryGatheringProgress:(NSNotification *)inNotification
{
	NSLog(@"Gathering progress...");
	[currentQuery disableUpdates];

	[NSThread detachNewThreadSelector:@selector(processQueryUpdates:)
							 toTarget:self
						   withObject:[NSNumber numberWithInt:activeSearchID]];	
}
/*
 * @brief Called when the search is 'complete' - that is, all existing items have been found
 */
- (void)queryDidFinish:(NSNotification *)inNotification
{
	NSLog(@"Complete!");
	[self searchComplete];
}

//Overridden from superclass...
- (void)refreshResultsSearchIsComplete:(BOOL)searchIsComplete
{
	[self resortLogs];	

#if 0
	if (searchIsComplete) {
		//Sort the logs correctly which will also reload the table
		[self resortLogs];	
	} else {
		//Otherwise just reload
		[tableView_results reloadData];
	}
#endif
	if (searchIsComplete && automaticSearch) {
		//If search is complete, select the first log if requested and possible
		[self selectFirstLog];
		
	} else {
		BOOL oldAutomaticSearch = automaticSearch;
		
		//Re-select displayed log, or display another one
		[self selectDisplayedLog];
		
		//We don't want the above re-selection to change our automaticSearch tracking
		//(The only reason automaticSearch should change is in response to user action)
		automaticSearch = oldAutomaticSearch;
	}

    //Update status
    [self updateProgressDisplay];
}

- (void)refreshResultsAndSort
{
	[self refreshResults];
	[self resortLogs];
	[self updateProgressDisplay];
}

//Faster, manual loading of all logs...
- (void)loadAllLogs:(NSString *)inSearchID
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSEnumerator        *fromEnumerator, *toEnumerator, *logEnumerator;
    AILogToGroup        *toGroup;
    AILogFromGroup      *fromGroup;
    AIChatLog			*theLog;
    UInt32				lastUpdate = TickCount();
    int					searchID = [inSearchID intValue];
	
    //Walk through every 'from' group
    fromEnumerator = [logFromGroupDict objectEnumerator];
    while ((fromGroup = [fromEnumerator nextObject]) && (searchID == activeSearchID)) {		
		/*
		 When searching in LOG_SEARCH_FROM, we only proceed into matching groups
		 For all other search modes, we always proceed here so long as either:
		 a) We are not filtering for the account name or
		 b) The account name matches
		 */
		/*
		if ((!filterForAccountName || ([[fromGroup fromUID] caseInsensitiveCompare:filterForAccountName] == NSOrderedSame)) &&
			((mode != LOG_SEARCH_FROM) ||
			 (!searchString) || 
			 ([[fromGroup fromUID] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound))) {
		*/	
			//Walk through every 'to' group
			toEnumerator = [[fromGroup toGroupArray] objectEnumerator];
			while ((toGroup = [toEnumerator nextObject]) && (searchID == activeSearchID)) {
				
				/*
				 When searching in LOG_SEARCH_TO, we only proceed into matching groups
				 For all other search modes, we always proceed here so long as either:
				 a) We are not filtering for the contact name or
				 b) The contact name matches
				 */
				/*
				if ((!filterForContactName || ([[toGroup to] caseInsensitiveCompare:filterForContactName] == NSOrderedSame)) &&
					((mode != LOG_SEARCH_TO) ||
					 (!searchString) || 
					 ([[toGroup to] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound))) {
				*/	
					//Walk through every log
					[resultsLock lock];

					logEnumerator = [toGroup logEnumerator];
					while ((theLog = [logEnumerator nextObject]) && (searchID == activeSearchID)) {
						
						//When searching in LOG_SEARCH_DATE, we must have matching dates
						//For all other search modes, we always proceed here
						if (/*(mode != LOG_SEARCH_DATE) ||
							(!searchString) ||
							(searchStringDate && [theLog isFromSameDayAsDate:searchStringDate])*/ TRUE) {
							
							//Add the log
							[currentSearchResults addObject:theLog];
							
							//Update our status
							if (lastUpdate == 0 || TickCount() > lastUpdate + LOG_SEARCH_STATUS_INTERVAL) {
								//[self updateProgressDisplay];
								lastUpdate = TickCount();
							}
						}
					}
					[resultsLock unlock];
				}
    }
	
	[self performSelectorOnMainThread:@selector(searchComplete)
						   withObject:nil
						waitUntilDone:NO];
	[pool release];
}

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

- (void)determineToAndFromGroupDicts
{
	[super determineToAndFromGroupDicts];
	
	[tableView_fromAccounts reloadData];
	[tableView_toContacts reloadData];
	[tableView_dates reloadData];
}

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

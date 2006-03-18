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
#import "AIContactController.h"

#define	REFRESH_RESULTS_INTERVAL		0.5 //Interval between results refreshes while searching

@implementation AIMDLogViewerWindowController
- (void)windowDidLoad
{	
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

	[super windowDidLoad];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[super dealloc];
}

- (NSArray *)sortDescriptors
{
	NSMutableArray	*sortDescriptors = [NSMutableArray array];

	NSString *identifier = [selectedColumn identifier];

	if ([identifier isEqualToString:@"Date"]) {
		[sortDescriptors addObject:[[[NSSortDescriptor alloc] initWithKey:(NSString *)kMDItemLastUsedDate ascending:!sortDirection] autorelease]];
		[sortDescriptors addObject:[[[NSSortDescriptor alloc] initWithKey:@"com_adiumX_chatDestination" ascending:sortDirection] autorelease]];

	} else {
		if ([identifier isEqualToString:@"To"]) {
			[sortDescriptors addObject:[[[NSSortDescriptor alloc] initWithKey:@"com_adiumX_chatDestination" ascending:sortDirection] autorelease]];
			
		} else if ([identifier isEqualToString:@"From"]) {
			[sortDescriptors addObject:[[[NSSortDescriptor alloc] initWithKey:@"com_adiumX_chatSource" ascending:sortDirection] autorelease]];
			
		}

		[sortDescriptors addObject:[[[NSSortDescriptor alloc] initWithKey:(NSString *)kMDItemLastUsedDate ascending:sortDirection] autorelease]];
	}

	return sortDescriptors;
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
			[predicates addObject:[NSPredicate predicateWithFormat:@"%K like[c] %@", key, searchString]];
		}
		
		predicate = [NSCompoundPredicate orPredicateWithSubpredicates:predicates];
	} else {
		searchString = [searchStrings anyObject];
		predicate = [NSPredicate predicateWithFormat:@"%K like[c] %@", key, searchString];
	}
	
	return predicate;
}


//Begin the current search
- (void)startSearchingClearingCurrentResults:(BOOL)clearCurrentResults
{
	NSMutableArray	*predicatesArray = [NSMutableArray array];

	[self stopSearching];

	currentQuery = [[NSMetadataQuery alloc] init];
	
	//Once all searches have exited, we can start a new one
	if (clearCurrentResults) {
		[resultsLock lock];
		[selectedLogArray release]; selectedLogArray = [[NSMutableArray alloc] init];
		[resultsLock unlock];
	}
	
	//Only search within our log folder
	//XXX need to escape ? and * if they are typed
	[currentQuery setSearchScopes:[NSArray arrayWithObject:[NSURL fileURLWithPath:[AILoggerPlugin logBasePath]]]];
	NSPredicate *queryPredicate;

	[predicatesArray addObject:[NSPredicate predicateWithFormat:@"((kMDItemContentType = \"com.adiumx.log\") or (kMDItemContentType = \"com.adiumx.htmllog\"))"]];

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

			[predicatesArray addObject:[NSPredicate predicateWithFormat:@"kMDItemLastUsedDate like[c] %@",[NSString stringWithFormat:@"*%@*",[searchStringDate descriptionWithCalendarFormat:@"%y-%m-%d"
																																											   timeZone:nil 
																																												  locale:nil]]]];
			break;
		}
		case LOG_SEARCH_CONTENT:
			if ([activeSearchString length]) {
				[predicatesArray addObject:[NSPredicate predicateWithFormat:@"kMDItemTextContent like[c] %@",[NSString stringWithFormat:@"*%@*",activeSearchString]]];
			}
			break;
	}

	
	//Note: filterForContactName an filterForAccountName are 'safe filename strings' - they shouldn't be once we're using data from outside the file name (e.g. an xml log)
	if (filterForAccountName) {
		[predicatesArray addObject:[self predicateForContactString:filterForAccountName key:@"com_adiumX_chatSource"]];
	}
	
	if (filterForContactName) {
		[predicatesArray addObject:[self predicateForContactString:filterForContactName key:@"com_adiumX_chatDestination"]];
	}
	//Update the table periodically while the logs load.
	[refreshResultsTimer invalidate]; [refreshResultsTimer release];
	
	if ([predicatesArray count] > 1) {
		queryPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicatesArray];

		NSLog(@"Predicate is %@",queryPredicate);
		[currentQuery setPredicate:queryPredicate];
		
		//Presort the results...
		[currentQuery setSortDescriptors:[self sortDescriptors]];
		
		lastResult = 0;
		[currentQuery startQuery];
		
		refreshResultsTimer = [[NSTimer scheduledTimerWithTimeInterval:REFRESH_RESULTS_INTERVAL
																target:self
															  selector:@selector(refreshResults)
															  userInfo:nil
															   repeats:YES] retain];
	} else {
		//Just looking for any log...
		//		queryPredicate = contentTypePredicate;

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
 * @brief Process updates to our query, adding its new results to the selectedLogArray
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
	NSLog(@"Query 0 is %@:",[myQuery resultAtIndex:0]);

	/*
	[resultsLock lock];
	[selectedLogArray removeAllObjects];
	[resultsLock unlock];
	*/

	unsigned count = [myQuery resultCount];
	int i = 0;
//	while ((lastResult < count) && (searchID == activeSearchID)) {
	while ((i < count) && (searchID == activeSearchID)) {
		NSString		*path = [[myQuery resultAtIndex:/*lastResult*/i++] valueForAttribute:(NSString *)kMDItemPath];
		//Path is a full path; we want everything after the base path since the old logging system used relative paths
		path = [path substringFromIndex:logBaseLength];
		
		NSString		*toPath = [path stringByDeletingLastPathComponent];
		AIChatLog		*theLog;

		[resultsLock lock];
		theLog = [[logToGroupDict objectForKey:toPath] logAtPath:path];
		if ((theLog != nil) && (![selectedLogArray containsObjectIdenticalTo:theLog]) && (searchID == activeSearchID)) {
			//			[theLog setRankingPercentage:outScoresArray[i]];
			//			NSLog(@"relevance is %@",[NSMetadataQueryResultContentRelevanceAttribute);
			[selectedLogArray addObject:theLog];
		}
		[resultsLock unlock];
	}
	
	NSLog(@"Processing complete...");

	[myQuery enableUpdates];
	[myQuery release];
	
	[self performSelectorOnMainThread:@selector(refreshResults)
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
}

//Faster, manual loading of all logs...
- (void)loadAllLogs:(NSString *)inSearchID
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[self _logFilter:nil searchID:[inSearchID intValue] mode:LOG_SEARCH_TO];

	[self performSelectorOnMainThread:@selector(searchComplete)
						   withObject:nil
						waitUntilDone:NO];
	[pool release];
}


@end

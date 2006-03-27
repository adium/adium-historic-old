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

#import "AIAccountController.h"
#import "AIChatLog.h"
#import "AIContentController.h"
#import "AILogFromGroup.h"
#import "AILogToGroup.h"
#import "AILogViewerWindowController.h"
#import "AILoggerPlugin.h"
#import "AIPreferenceController.h"
#import "ESRankingCell.h" 
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIFileManagerAdditions.h>
#import <AIUtilities/AITextAttributes.h>
#import <AIUtilities/AIArrayAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AIApplicationAdditions.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIToolbarUtilities.h>

#import <Adium/AIHTMLDecoder.h>
#import <Adium/AIListContact.h>
#import <Adium/AIMetaContact.h>
#import <Adium/AIServiceIcons.h>
#import "KFTypeSelectTableView.h"

#define KEY_LOG_VIEWER_WINDOW_FRAME		@"Log Viewer Frame"
#define	PREF_GROUP_CONTACT_LIST			@"Contact List"
#define KEY_LOG_VIEWER_GROUP_STATE		@"Log Viewer Group State"	//Expand/Collapse state of groups

#define LOG_CONTENT_SEARCH_MAX_RESULTS	10000	//Max results allowed from a search
#define LOG_RESULT_CLUMP_SIZE			10	//Number of logs to fetch at a time

@interface AILogViewerWindowController (PRIVATE)
- (void)_logContentFilter:(NSString *)searchString searchID:(int)searchID;
- (void)updateRankColumnVisibility;
@end

@implementation AILogViewerWindowController

/* A total logs count in the drawer would be nice too, but counting them defeats the lazy nature of Log Viewer right now and running through NSFileManager and eliminating all for a count isn't necesarily good either. If you come up with an efficient method go ahead though :) */

//Open the log viewer window
static NSString	*staticFilterForAccountName = nil ;	//Account name to restrictively match content searches
static NSString	*staticFilterForContactName = nil;	//Contact name to restrictively match content searches

+ (NSString *)nibName
{
	return @"LogViewer";
}

//init
- (id)initWithWindowNibName:(NSString *)windowNibName plugin:(id)inPlugin
{
	if ((self = [super initWithWindowNibName:windowNibName])) {
		activeSearchStringEncoded = nil;
		aggregateLogIndexProgressTimer = nil;
	}

    return self;
}

//dealloc
- (void)dealloc
{
    [activeSearchStringEncoded release];
    [activeSearchString release];

    //toolbarItems?
    //aggregateLogIndexProgressTimer?
    
    [filterForContactName release]; filterForContactName = nil;
    [staticFilterForContactName release]; staticFilterForContactName = nil;

    [filterForAccountName release]; filterForAccountName = nil;
    [staticFilterForAccountName release]; staticFilterForAccountName = nil;

    [super dealloc];
}

/*
 * @brief After calling super's implementation, build the contact and account table arrays
 */
- (void)determineToAndFromGroupDicts
{
	[super determineToAndFromGroupDicts];

	[textField_totalAccounts setStringValue:[NSString stringWithFormat:
		AILocalizedString(@"%i Accounts",nil),
		[fromArray count]]];
	[textField_totalContacts setStringValue:[NSString stringWithFormat:
		AILocalizedString(@"%i Contacts",nil),
		[toArray count]]];

	[[adium notificationCenter] postNotificationName:LOG_VIEWER_DID_UPDATE_LOG_ARRAYS
											  object:nil];
}

//
- (NSString *)adiumFrameAutosaveName
{
	return KEY_LOG_VIEWER_WINDOW_FRAME;
}

//Setup the window before it is displayed
- (void)windowDidLoad
{
	[super windowDidLoad];

    //Prepare indexing and filter searching
    [plugin prepareLogContentSearching];
	
    //Configure drawer
    if ([[[adium preferenceController] preferenceForKey:KEY_LOG_VIEWER_DRAWER_STATE
                                                  group:PREF_GROUP_LOGGING] boolValue]) {
            [drawer_contacts open];
    } else {
            [drawer_contacts close];
    }
    [drawer_contacts setContentSize:NSMakeSize([[[adium preferenceController] preferenceForKey:KEY_LOG_VIEWER_DRAWER_SIZE
                                                                                         group:PREF_GROUP_LOGGING] floatValue], 0)];
	[drawer_contacts setMinContentSize:NSMakeSize(100.0, 0)];
}


//This is less than ideal for performance, but it's very simple and I don't see purge logs as being particularly performance critical.
- (IBAction)deleteAllLogs:(id)sender
{
	NSAlert * alert = [[NSAlert alloc] init];
	[alert setMessageText:AILocalizedString(@"Delete Logs?",nil)];
	[alert setInformativeText:AILocalizedString(@"Warning: Are you sure you want to delete the selected logs? This operation cannot be undone.",nil)];
	[alert addButtonWithTitle:DELETE]; 
	[alert addButtonWithTitle:AILocalizedString(@"Cancel",nil)];
	if ([alert runModal] == NSAlertFirstButtonReturn)
	{
		int row = [[tableView_results dataSource] numberOfRowsInTableView:tableView_results];
		//We utilize the logIndexAccessLock so we have exclusive access to the logs
		NSLock              *logAccessLock = [plugin logAccessLock];
		
		//Remember that this locks and unlocks the logAccessLock
		SKIndexRef          logSearchIndex = [plugin logContentIndex];
		SKDocumentRef       document;
		for (; row >= 0; row--)
		{
			AIChatLog   *theLog = nil;
			[resultsLock lock];
			if (row >= 0 && row < [currentSearchResults count]) {
				theLog = [currentSearchResults objectAtIndex:row];
				sameSelection = (row - 1);
			}
			[resultsLock unlock];
			
			if (theLog) {
				useSame = YES;
				[theLog retain];
				
				[resultsLock lock];
				[currentSearchResults removeObjectAtIndex:row];
				[resultsLock unlock];
				
				[[NSFileManager defaultManager] trashFileAtPath:[[AILoggerPlugin logBasePath] stringByAppendingPathComponent:[theLog path]]];
				
				[logAccessLock lock];
				document = SKDocumentCreate((CFStringRef)@"file", NULL, (CFStringRef)[theLog path]);
				SKIndexRemoveDocument(logSearchIndex, document);
				CFRelease(document);
				[logAccessLock unlock];
				
				[theLog release];
			}
		}
		//Update the log index
		[logAccessLock lock];

		SKIndexFlush(logSearchIndex);
		[logAccessLock unlock];
		
		//Rebuild the 'global' log indexes
		[self rebuildIndices];
		
		[self updateProgressDisplay];
	}	
}

//Delete selected logs
- (IBAction)deleteSelectedLog:(id)sender
{
    AIChatLog   *theLog = nil;
	int row = [tableView_results selectedRow];
	[resultsLock lock];
	if (row >= 0 && row < [currentSearchResults count]) {
		theLog = [currentSearchResults objectAtIndex:row];
		sameSelection = (row - 1);
	}
	[resultsLock unlock];
	
	if (theLog) {
		//We utilize the logIndexAccessLock so we have exclusive access to the logs
		NSLock              *logAccessLock = [plugin logAccessLock];
		
		//Remember that this locks and unlocks the logAccessLock
		SKIndexRef          logSearchIndex = [plugin logContentIndex];
		SKDocumentRef       document;
		
		useSame = YES;
		[theLog retain];
		
		[resultsLock lock];
		[currentSearchResults removeObjectAtIndex:row];
		[resultsLock unlock];
		
		[[NSFileManager defaultManager] trashFileAtPath:[[AILoggerPlugin logBasePath] stringByAppendingPathComponent:[theLog path]]];
		
		//Update the log index
		[logAccessLock lock];
		document = SKDocumentCreate((CFStringRef)@"file", NULL, (CFStringRef)[theLog path]);
		SKIndexRemoveDocument(logSearchIndex, document);
		CFRelease(document);
		SKIndexFlush(logSearchIndex);
		[logAccessLock unlock];
		
		//Rebuild the 'global' log indexes
		[self rebuildIndices];
		
		[self updateProgressDisplay];
		
		[theLog release];
	}
}

-(void)rebuildIndices
{
    //Rebuild the 'global' log indexes
    [logFromGroupDict release]; logFromGroupDict = [[NSMutableDictionary alloc] init];
    [toArray removeAllObjects]; //note: even if there are no logs, the name will remain [bug or feature?]
    [toServiceArray removeAllObjects];
    [fromArray removeAllObjects];
    [fromServiceArray removeAllObjects];
    
    [self determineToAndFromGroupDicts];
    
    [tableView_results reloadData];
    [self selectDisplayedLog];
}

//Called as the window closes
- (void)windowWillClose:(id)sender
{
	[super windowWillClose:sender];
	
	//Determine and save the current state of the drawer
	int		drawerState = [drawer_contacts state];
	NSNumber	*drawerIsOpen = nil;
	
	switch (drawerState) {
		case NSDrawerOpeningState:
		case NSDrawerOpenState:
			drawerIsOpen = [NSNumber numberWithBool:YES];
			break;
		case NSDrawerClosingState:
		case NSDrawerClosedState:
			drawerIsOpen = [NSNumber numberWithBool:NO];
			break;
	}
	
	[[adium preferenceController] setPreference:drawerIsOpen
										 forKey:KEY_LOG_VIEWER_DRAWER_STATE
										  group:PREF_GROUP_LOGGING];
	
	//Set preference for drawer size
	[[adium preferenceController] setPreference:[NSNumber numberWithFloat:[drawer_contacts contentSize].width]
										 forKey:KEY_LOG_VIEWER_DRAWER_SIZE
										  group:PREF_GROUP_LOGGING];       

    //Abort any in-progress searching and indexing, and wait for their completion
    [plugin cleanUpLogContentSearching];

    //Clean up
	[aggregateLogIndexProgressTimer invalidate];
	[aggregateLogIndexProgressTimer release]; aggregateLogIndexProgressTimer = nil;
	
	//Reset our column widths if needed
	[activeSearchString release]; activeSearchString = nil;
	[self updateRankColumnVisibility];	
}


#pragma mark Array access
//Array access ----------------------------------------

//Return our handy dandy accounts list
- (NSMutableArray *)fromArray{
    return fromArray;
}

//Return our handy dandy services list to match above
- (NSMutableArray *)fromServiceArray{
    return fromServiceArray;
}

//Return our handy dandy services list to match above
- (NSMutableArray *)toServiceArray{
    return toServiceArray;
}

//Return our handy dandy services list to match above
- (NSMutableArray *)toArray{
    return toArray;
}


//Display --------------------------------------------------------------------------------------------------------------
#pragma mark Display
//Update log viewer progress string to reflect current status
- (NSMutableString *)progressString
{
	int					indexComplete, indexTotal;
    BOOL				indexing;
	NSMutableString		*progress = [super progressString];

    //Append indexing progress
    if ((indexing = [plugin getIndexingProgress:&indexComplete outOf:&indexTotal])) {
		[progress appendString:[NSString stringWithFormat:AILocalizedString(@" - Indexing %i of %i",nil),indexComplete, indexTotal]];
    }

	//Enable/disable the searching animation
    if (searching || indexing) {
		[progressIndicator startAnimation:nil];
    } else {
		[progressIndicator stopAnimation:nil];
    }
	
	return progress;
}

//The plugin is informing us that the log indexing changed
- (void)logIndexingProgressUpdate
{
	//Don't do anything if the window is already closing
	if (!windowIsClosing) {
		[self updateProgressDisplay];
		
		//If we are searching by content, we should re-search without clearing our current results so the
		//the newly-indexed logs can be added without blanking the current table contents.
		//We set an NSNumber with our current activeSearchID so we will only refresh if we haven't done a new search
		//between the timer being set and firing.
		if (searchMode == LOG_SEARCH_CONTENT && (activeSearchString != nil)) {
			if (!aggregateLogIndexProgressTimer) {
				aggregateLogIndexProgressTimer = [[NSTimer scheduledTimerWithTimeInterval:7.0
																				   target:self
																				 selector:@selector(aggregatedLogIndexingProgressUpdate:)
																				 userInfo:[NSNumber numberWithInt:activeSearchID]
																				  repeats:NO] retain];
			}
		}
	}
}

- (void)aggregatedLogIndexingProgressUpdate:(NSTimer *)inTimer
{
	NSNumber	*oldActiveSearchID = [aggregateLogIndexProgressTimer userInfo];

	//If the search is still a content search and hasn't changed since the timer was made, update our results
	if ((searchMode == LOG_SEARCH_CONTENT) && ([oldActiveSearchID intValue] == activeSearchID)) {
		[self startSearchingClearingCurrentResults:NO];
	}

	[aggregateLogIndexProgressTimer invalidate];
	[aggregateLogIndexProgressTimer release]; aggregateLogIndexProgressTimer = nil;
}

//Searching ------------------------------------------------------------------------------------------------------------
#pragma mark Searching
//(Jaguar only?) Change search string
- (void)controlTextDidChange:(NSNotification *)notification
{
	NSLog(@"Control text changed");
    if (searchMode != LOG_SEARCH_CONTENT) {
		[self updateSearch:nil];
    }
}

//Begin the current search
- (void)startSearchingClearingCurrentResults:(BOOL)clearCurrentResults
{
    NSDictionary    *searchDict;

	[super startSearchingClearingCurrentResults:clearCurrentResults];

    searchDict = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithInt:activeSearchID], @"ID",
		[NSNumber numberWithInt:searchMode], @"Mode",
		activeSearchString, @"String",
		activeSearchStringEncoded, @"StringEncoded",
		nil];
    [NSThread detachNewThreadSelector:@selector(filterLogsWithSearch:) toTarget:self withObject:searchDict];
    
	//Update the table periodically while the logs load.
	[refreshResultsTimer invalidate]; [refreshResultsTimer release];
	refreshResultsTimer = [[NSTimer scheduledTimerWithTimeInterval:REFRESH_RESULTS_INTERVAL
                                                                target:self
                                                              selector:@selector(refreshResults)
                                                              userInfo:nil
                                                               repeats:YES] retain];
}

//Abort any active searches
- (void)stopSearching
{
	[super stopSearching];

	//If the plugin is in the middle of indexing, and we are content searching, we could be autoupdating a search.
	//Be sure to invalidate the timer.
	[aggregateLogIndexProgressTimer invalidate];
	[aggregateLogIndexProgressTimer release]; aggregateLogIndexProgressTimer = nil;
}


- (void)updateRankColumnVisibility
{
	NSTableColumn	*resultsColumn = [tableView_results tableColumnWithIdentifier:@"Rank"];
	NSArray		*tableColumns;
	NSTableColumn	*nextDoorNeighbor;
	
	if ((searchMode == LOG_SEARCH_CONTENT) && ([activeSearchString length])) {
		//Add the resultsColumn and resize if it should be shown but is not at present
		if (!resultsColumn) {			
			//Set up the results column
			resultsColumn = [[NSTableColumn alloc] initWithIdentifier:@"Rank"];
			[[resultsColumn headerCell] setTitle:AILocalizedString(@"Rank",nil)];
			[resultsColumn setDataCell:[[[ESRankingCell alloc] init] autorelease]];
			
			//Add it to the table
			[tableView_results addTableColumn:resultsColumn];

			//Make it half again as large as the desired width from the @"Rank" header title
			[resultsColumn sizeToFit];
			[resultsColumn setWidth:([resultsColumn width] * 1.5)];
			
			//Adjust the column to the results column's left so results is now visible
			tableColumns = [tableView_results tableColumns];
			nextDoorNeighbor = [tableColumns objectAtIndex:([tableColumns indexOfObject:resultsColumn] - 1)];
			[nextDoorNeighbor setWidth:[nextDoorNeighbor width]-[resultsColumn width]];
		}
	} else {
		//Remove the resultsColumn and resize if it should not be shown but is at present
		if (resultsColumn) {
			//Adjust the column to the results column's left to take up the space again
			tableColumns = [tableView_results tableColumns];
			nextDoorNeighbor = [tableColumns objectAtIndex:([tableColumns indexOfObject:resultsColumn] - 1)];
			[nextDoorNeighbor setWidth:[nextDoorNeighbor width]+[resultsColumn width]];

			//Remove it
			[tableView_results removeTableColumn:resultsColumn];
		}
	}
}

- (void)setSearchMode:(LogSearchMode)inMode
{
	if (inMode == LOG_SEARCH_FROM) {
		[filterForAccountName release]; filterForAccountName = nil;
	} else if (inMode == LOG_SEARCH_TO) {
		[filterForAccountName release]; filterForAccountName = nil;
	}

	[super setSearchMode:inMode];

	[self updateRankColumnVisibility];	
}

//Set the active search string (Does not invoke a search)
- (void)setSearchString:(NSString *)inString
{
	[super setSearchString:inString];
	
	//Our logs are stored as HTML.  Non-ASCII characters are therefore HTML-encoded.  We need to have an
	//encoded version of our search string with which to search when doing a content-based search, as that's
	//how they are on disk.
	if (searchMode == LOG_SEARCH_CONTENT) {
		[activeSearchStringEncoded release];
		activeSearchStringEncoded = [[AIHTMLDecoder encodeHTML:[[[NSAttributedString alloc] initWithString:activeSearchString] autorelease]
													   headers:NO 
													  fontTags:NO 
											includingColorTags:NO
												 closeFontTags:NO 
													 styleTags:NO
									closeStyleTagsOnFontChange:NO
												encodeNonASCII:YES 
												  encodeSpaces:NO
													imagesPath:nil 
											 attachmentsAsText:YES 
									 onlyIncludeOutgoingImages:NO 
												simpleTagsOnly:NO
												bodyBackground:NO] retain];
		AILog(@"Search will be on %@",activeSearchStringEncoded);
	} else {
		[activeSearchStringEncoded release]; activeSearchStringEncoded = nil;
	}

	[self updateRankColumnVisibility];
}

#pragma mark Table view

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	if (tableView == tableView_results) {
		NSString	*identifier = [tableColumn identifier];
		
		if ([identifier isEqualToString:@"Rank"] && row >= 0 && row < [currentSearchResults count]) {
			AIChatLog       *theLog = [currentSearchResults objectAtIndex:row];
			
			[aCell setPercentage:[theLog rankingPercentage]];
		}
	}
}

//Threaded filter/search methods ---------------------------------------------------------------------------------------
#pragma mark Threaded filter/search methods
//Search the logs, filtering out any matching logs into the currentSearchResults
- (void)filterLogsWithSearch:(NSDictionary *)searchInfoDict
{
    NSAutoreleasePool       *pool = [[NSAutoreleasePool alloc] init];
    int                     mode = [[searchInfoDict objectForKey:@"Mode"] intValue];
    int                     searchID = [[searchInfoDict objectForKey:@"ID"] intValue];
    NSString                *searchString = [searchInfoDict objectForKey:@"String"];
    NSString                *searchStringEncoded = [searchInfoDict objectForKey:@"StringEncoded"]; 

    //Lock down new thread creation until this thread is complete
    //We must be careful not to wait on performing any main thread selectors when this lock is set!!
    [searchingLock lock];
    if (searchID == activeSearchID) { //If we're still supposed to go
		searching = YES;
		
		//Search
		if (searchString && [searchString length]) {
			switch (mode) {
				case LOG_SEARCH_FROM:
				case LOG_SEARCH_TO:
				case LOG_SEARCH_DATE:
					[self _logFilter:searchString
							searchID:searchID
								mode:mode];
					break;
				case LOG_SEARCH_CONTENT:
					[self _logContentFilter:searchStringEncoded
								   searchID:searchID];
					break;
			}
		} else {
			[self _logFilter:nil
					searchID:searchID
						mode:mode];
		}
		
		//Refresh
		searching = NO;
		[self performSelectorOnMainThread:@selector(searchComplete) withObject:nil waitUntilDone:NO];
    }
	
    //Re-allow thread creation
    //We must be careful not to wait on performing any main thread selectors when this lock is set!!
    [searchingLock unlock];	
    
    //Cleanup
    [pool release];
}

//Perform a filter search based on source name, destination name, or date
- (void)_logFilter:(NSString *)searchString searchID:(int)searchID mode:(LogSearchMode)mode
{
    NSEnumerator        *fromEnumerator, *toEnumerator, *logEnumerator;
    AILogToGroup        *toGroup;
    AILogFromGroup      *fromGroup;
    AIChatLog			*theLog;
    UInt32		lastUpdate = TickCount();
    
    NSCalendarDate	*searchStringDate = nil;
	
	if ((mode == LOG_SEARCH_DATE) && (searchString != nil)) {
		searchStringDate = [[NSDate dateWithNaturalLanguageString:searchString]  dateWithCalendarFormat:nil timeZone:nil];
	}
	
    //Walk through every 'from' group
    fromEnumerator = [logFromGroupDict objectEnumerator];
    while ((fromGroup = [fromEnumerator nextObject]) && (searchID == activeSearchID)) {
		
		/*
		 When searching in LOG_SEARCH_FROM, we only proceed into matching groups
		 For all other search modes, we always proceed here so long as either:
			a) We are not filtering for the account name or
			b) The account name matches
		 */
		if ((!filterForAccountName || ([[fromGroup fromUID] caseInsensitiveCompare:filterForAccountName] == NSOrderedSame)) &&
		   ((mode != LOG_SEARCH_FROM) ||
		   (!searchString) || 
		   ([[fromGroup fromUID] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound))) {
			
			//Walk through every 'to' group
			toEnumerator = [[fromGroup toGroupArray] objectEnumerator];
			while ((toGroup = [toEnumerator nextObject]) && (searchID == activeSearchID)) {
				
				/*
				 When searching in LOG_SEARCH_TO, we only proceed into matching groups
				 For all other search modes, we always proceed here so long as either:
					a) We are not filtering for the contact name or
					b) The contact name matches
				 */
				if ((!filterForContactName || ([[toGroup to] caseInsensitiveCompare:filterForContactName] == NSOrderedSame)) &&
				   ((mode != LOG_SEARCH_TO) ||
				   (!searchString) || 
				   ([[toGroup to] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound))) {
					
					//Walk through every log
					logEnumerator = [toGroup logEnumerator];
					while ((theLog = [logEnumerator nextObject]) && (searchID == activeSearchID)) {
						
						//When searching in LOG_SEARCH_DATE, we must have matching dates
						//For all other search modes, we always proceed here
						if ((mode != LOG_SEARCH_DATE) ||
						   (!searchString) ||
						   (searchStringDate && [theLog isFromSameDayAsDate:searchStringDate])) {

							//Add the log
							[resultsLock lock];
							[currentSearchResults addObject:theLog];
							[resultsLock unlock];

							//Update our status
							if (lastUpdate == 0 || TickCount() > lastUpdate + LOG_SEARCH_STATUS_INTERVAL) {
								[self updateProgressDisplay];
								lastUpdate = TickCount();
							}
						}
						
					}
				}
			}	    
		}
    }
}

- (void)filterForContactName:(NSString *)inContactName
{
	[filterForContactName release]; filterForContactName = nil;
	[filterForAccountName release]; filterForAccountName = nil;
	[staticFilterForContactName release]; staticFilterForContactName = nil;
	[staticFilterForAccountName release]; staticFilterForAccountName = nil;

	filterForContactName = [[inContactName safeFilenameString] retain];
	staticFilterForContactName = [filterForContactName retain];

	//If the search mode is currently the TO field, switch it to content, which is what it should now intuitively do
	if (searchMode == LOG_SEARCH_TO) {
		[self setSearchMode:LOG_SEARCH_CONTENT];
	}

	//Update our search string; now that we may be on LOG_SEARCH_CONTENT the encoded string is needed,
	//and we also want the rank column visibility to be updated
	[self setSearchString:activeSearchString];
	
    [self startSearchingClearingCurrentResults:YES];
}

- (void)filterForContact:(AIListContact *)listContact
{
	NSString	*contactName;
	
	if ([listContact isKindOfClass:[AIMetaContact class]]) {
		contactName = [[(AIMetaContact *)listContact preferredContact] UID];
	} else {
		contactName = [listContact UID];
	}
	
	[self filterForContactName:contactName];
}

- (void)filterForAccountName:(NSString *)inAccountName
{
	[filterForContactName release]; filterForContactName = nil;
	[filterForAccountName release]; filterForAccountName = nil;
	[staticFilterForContactName release]; staticFilterForContactName = nil;
	[staticFilterForAccountName release]; staticFilterForAccountName = nil;
	
	filterForAccountName = [[inAccountName safeFilenameString] retain];
	staticFilterForAccountName = [filterForAccountName retain];

	//If the search mode is currently the FROM field, switch it to content, which is what it should now intuitively do
	if (searchMode == LOG_SEARCH_FROM) {
		[self setSearchMode:LOG_SEARCH_CONTENT];
	}

	//Update our search string; now that we may be on LOG_SEARCH_CONTENT the encoded string is needed,
	//and we also want the rank column visibility to be updated
	[self setSearchString:activeSearchString];
	
    [self startSearchingClearingCurrentResults:YES];	
}

- (NSDictionary *)logToGroupDict
{
	return logToGroupDict;
}

- (NSDictionary *)logFromGroupDict
{
	return logFromGroupDict;
}

Boolean ContentResultsFilter (SKIndexRef     inIndex,
                              SKDocumentRef     inDocument,
                              void      *inContext)
{
	if (staticFilterForContactName) {
		//Searching for a specific contact
		NSString		*path = (NSString *)SKDocumentGetName(inDocument);
		NSString		*toPath = [path stringByDeletingLastPathComponent];
		AILogToGroup	*toGroup = [[(AILogViewerWindowController *)inContext logToGroupDict] objectForKey:toPath];

		return [[toGroup to] caseInsensitiveCompare:staticFilterForContactName] == NSOrderedSame;

	} else if (staticFilterForAccountName) {
		//Searching for a specific account
		NSString		*path = (NSString *)SKDocumentGetName(inDocument);
		NSString		*toPath = [path stringByDeletingLastPathComponent];
		NSString		*fromPath = [toPath stringByDeletingLastPathComponent];
		AILogFromGroup	*fromGroup = [[(AILogViewerWindowController *)inContext logFromGroupDict] objectForKey:fromPath];

		return [[fromGroup fromUID] caseInsensitiveCompare:staticFilterForAccountName] == NSOrderedSame;

	} else {
		return true; //Boolean, not BOOL
	}
}

//Perform a content search of the indexed logs
- (void)_logContentFilter:(NSString *)searchString searchID:(int)searchID
{
	SKIndexRef			logSearchIndex = [plugin logContentIndex];
	SKSearchGroupRef	searchGroup;
	CFArrayRef			indexArray;
	SKSearchResultsRef	searchResults;
	int					resultCount;    
	UInt32				lastUpdate = TickCount();
	void				*indexPtr = &logSearchIndex;
	
	//We utilize the logIndexAccessLock so we have exclusive access to the logs
	NSLock			*logAccessLock = [plugin logAccessLock];

	//Perform the content search
	[logAccessLock lock];
	indexArray = CFArrayCreate(NULL, indexPtr, 1, &kCFTypeArrayCallBacks);
	searchGroup = SKSearchGroupCreate(indexArray);

	searchResults = SKSearchResultsCreateWithQuery(
												   searchGroup,
												   (CFStringRef)searchString,
												   kSKSearchRanked,
												   LOG_CONTENT_SEARCH_MAX_RESULTS,
												   (void *)self,	/* Must have a context for the ContentResultsFilter */
												   &ContentResultsFilter	/* Determines if a given document should be included */
												   );

	//Process the results
	if ((resultCount = SKSearchResultsGetCount(searchResults))) {
		SKDocumentRef   *outDocumentsArray = malloc(sizeof(SKDocumentRef) * LOG_RESULT_CLUMP_SIZE);
		float		*outScoresArray = malloc(sizeof(float) * LOG_RESULT_CLUMP_SIZE);
		NSRange		resultRange = NSMakeRange(0, resultCount);
		
		//Read the results in LOG_RESULT_CLUMP_SIZE at a time
		while (resultRange.location < resultCount && (searchID == activeSearchID)) {
			int		count;
			int		i;
			
			//Get the next LOG_RESULT_CLUMP_SIZE results
			count = SKSearchResultsGetInfoInRange(searchResults,
												  CFRangeMake(resultRange.location, LOG_RESULT_CLUMP_SIZE),
												  outDocumentsArray,
												  NULL,
												  outScoresArray);
			
			//Process the results
			for (i = 0; (i < count) && (searchID == activeSearchID); i++) {
				NSString		*path = (NSString *)SKDocumentGetName(outDocumentsArray[i]);
				NSString		*toPath = [path stringByDeletingLastPathComponent];
				AIChatLog		*theLog;
				
				/*	
				 Add the log - if our index is currently out of date (for example, a log was just deleted) 
				 we may get a null log, so be careful.
				 */
				[resultsLock lock];
				theLog = [[logToGroupDict objectForKey:toPath] logAtPath:path];
				if ((theLog != nil) && (![currentSearchResults containsObjectIdenticalTo:theLog])) {
					[theLog setRankingPercentage:outScoresArray[i]];
					[currentSearchResults addObject:theLog];
				}
				[resultsLock unlock];
			}	 
			
			//Update our status
			if (lastUpdate == 0 || TickCount() > lastUpdate + LOG_SEARCH_STATUS_INTERVAL) {
				[self updateProgressDisplay];
				lastUpdate = TickCount();
			}
			
			resultRange.location += LOG_RESULT_CLUMP_SIZE;
			resultRange.length -= LOG_RESULT_CLUMP_SIZE;
		}
		
		free(outDocumentsArray);
		free(outScoresArray);
	}

	CFRelease(indexArray);
	CFRelease(searchGroup);
	CFRelease(searchResults);

	//Release the logsLock so the plugin can return to regularly scheduled programming
	[logAccessLock unlock];
}


- (IBAction)toggleDrawer:(id)sender
{

    [drawer_contacts toggle:sender];
}


#pragma mark Toolbar
- (void)installToolbar
{
	[super installToolbar];

	//Toggle Drawer
	[AIToolbarUtilities addToolbarItemToDictionary:toolbarItems
									withIdentifier:@"toggledrawer"
											 label:AILocalizedString(@"Contacts",nil)
									  paletteLabel:AILocalizedString(@"Contacts Drawer",nil)
										   toolTip:AILocalizedString(@"Show/Hide the Contacts Drawer",nil)
											target:self
								   settingSelector:@selector(setImage:)
									   itemContent:[NSImage imageNamed:@"showdrawer" forClass:[self class]]
											action:@selector(toggleDrawer:)
											  menu:nil];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
    return [NSArray arrayWithObjects:@"delete", NSToolbarFlexibleSpaceItemIdentifier, @"search", NSToolbarSeparatorItemIdentifier, @"toggledrawer", nil];
}

@end


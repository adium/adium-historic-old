/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2004, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
 | This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 | General Public License as published by the Free Software Foundation; either version 2 of the License,
 | or (at your option) any later version.
 |
 | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 | Public License for more details.
 |
 | You should have received a copy of the GNU General Public License along with this program; if not,
 | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 \------------------------------------------------------------------------------------------------------ */

#import "AILogViewerWindowController.h"
#import "AILoggerPlugin.h"
#import "AILog.h"
#import "AILogFromGroup.h"
#import "AILogToGroup.h"
#import "ESRankingCell.h"

#define LOG_VIEWER_NIB                          @"LogViewer"
#define LOG_VIEWER_JAG_NIB			@"LogViewerJag"
#define KEY_LOG_VIEWER_WINDOW_FRAME             @"Log Viewer Frame"
#define	PREF_GROUP_CONTACT_LIST			@"Contact List"
#define KEY_LOG_VIEWER_GROUP_STATE		@"Log Viewer Group State"	//Expand/Collapse state of groups
#define TOOLBAR_LOG_VIEWER			@"Log Viewer Toolbar"

#define MAX_LOGS_TO_SORT_WHILE_SEARCHING	3000	//Max number of logs we will live sort while searching
#define LOG_SEARCH_STATUS_INTERVAL		20	//1/60ths of a second to wait before refreshing search status

#define LOG_CONTENT_SEARCH_MAX_RESULTS		10000	//Max results allowed from a search
#define LOG_RESULT_CLUMP_SIZE			10	//Number of logs to fetch at a time

#define SEARCH_MENU                             AILocalizedString(@"Search Menu",nil)
#define FROM                                    AILocalizedString(@"From",nil)
#define TO                                      AILocalizedString(@"To",nil)
#define DATE                                    AILocalizedString(@"Date",nil)
#define CONTENT                                 AILocalizedString(@"Content",nil)

#define HIDE_EMOTICONS				AILocalizedString(@"Hide Emoticons",nil)
#define SHOW_EMOTICONS				AILocalizedString(@"Show Emoticons",nil)

#define IMAGE_EMOTICONS_OFF			@"emoticonsOff"
#define IMAGE_EMOTICONS_ON			@"emoticonsOn"

#define	REFRESH_RESULTS_INTERVAL                0.5 //Interval between results refreshes while searching

@interface AILogViewerWindowController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName plugin:(id)inPlugin;
- (void)initLogFiltering;
- (void)updateProgressDisplay;
- (void)refreshResults;
- (void)refreshResultsSearchIsComplete:(BOOL)searchIsComplete;
- (void)displayLog:(AILog *)log;
- (void)selectFirstLog;
- (void)selectDisplayedLog;
- (NSAttributedString *)hilightOccurrencesOfString:(NSString *)littleString inString:(NSAttributedString *)bigString firstOccurrence:(NSRange *)outRange;
- (void)sortSelectedLogArrayForTableColumn:(NSTableColumn *)tableColumn direction:(BOOL)direction;
- (void)startSearchingClearingCurrentResults:(BOOL)clearCurrentResults;
- (void)stopSearching;
- (void)buildSearchMenu;
- (NSMenuItem *)_menuItemWithTitle:(NSString *)title forSearchMode:(LogSearchMode)mode;
- (void)_logFilter:(NSString *)searchString searchID:(int)searchID mode:(LogSearchMode)mode;
- (void)_logContentFilter:(NSString *)searchString searchID:(int)searchID;
- (void)installToolbar;
- (void)updateRankColumnVisibility;
@end

int _sortStringWithKey(id objectA, id objectB, void *key);
int _sortStringWithKeyBackwards(id objectA, id objectB, void *key);
int _sortDateWithKey(id objectA, id objectB, void *key);
int _sortDateWithKeyBackwards(id objectA, id objectB, void *key);

@implementation AILogViewerWindowController

/* A total logs count in the drawer would be nice too, but counting them defeats the lazy nature of Log Viewer right now and running through NSFileManager and eliminating all for a count isn't necesarily good either. If you come up with an efficient method go ahead though :) */

//Open the log viewer window
static AILogViewerWindowController          *sharedLogViewerInstance = nil;
static NSTimer                              *refreshResultsTimer = nil;
static NSMutableDictionary                  *logFromGroupDict = nil;
static NSMutableDictionary                  *logToGroupDict = nil;
static NSString                             *filterForAccountName = nil;	//Account name to restrictively match content searches
static NSString                             *filterForContactName = nil;	//Contact name to restrictively match content searches

+ (id)openForPlugin:(id)inPlugin
{
    if(!sharedLogViewerInstance) sharedLogViewerInstance = [[self alloc] initWithWindowNibName:([NSApp isOnPantherOrBetter] ? LOG_VIEWER_NIB : LOG_VIEWER_JAG_NIB) plugin:inPlugin];
    [sharedLogViewerInstance showWindow:nil];
    
	return(sharedLogViewerInstance);
}

//Open the log viewer window to a specific contact's logs
+ (id)openForContact:(AIListContact *)inContact plugin:(id)inPlugin
{
    [self openForPlugin:inPlugin];
    
	if(inContact){
		NSString	*searchString;
		
		if ([inContact isKindOfClass:[AIMetaContact class]]){
			searchString = [[(AIMetaContact *)inContact preferredContact] UID];
		}else{
			searchString = [inContact UID];
		}
		
		[sharedLogViewerInstance setSearchString:searchString mode:LOG_SEARCH_TO];
	}
	
    return(sharedLogViewerInstance);
}

//Returns the window controller if one exists
+ (id)existingWindowController
{
    return(sharedLogViewerInstance);
}

//Close the log viewer window
+ (void)closeSharedInstance
{
    if(sharedLogViewerInstance){
        [sharedLogViewerInstance closeWindow:nil];
    }
}

//init
- (id)initWithWindowNibName:(NSString *)windowNibName plugin:(id)inPlugin
{
    //init
    plugin = inPlugin;
    selectedColumn = nil;
    activeSearchID = 0;
    searching = NO;
    automaticSearch = YES;
    showEmoticons = NO;
    activeSearchString = nil;
    activeSearchStringEncoded = nil;
    displayedLog = nil;
    aggregateLogIndexProgressTimer = nil;
    windowIsClosing = NO;
	
    blankImage = [[NSImage alloc] initWithSize:NSMakeSize(16,16)];

    sortDirection = YES;
    searchMode = LOG_SEARCH_TO;
    dateFormatter = [[NSDateFormatter alloc] initWithDateFormat:[[NSUserDefaults standardUserDefaults] stringForKey:NSDateFormatString] allowNaturalLanguage:YES];
    selectedLogArray = [[NSMutableArray alloc] init];
    fromArray = [[NSMutableArray alloc] init];
    fromServiceArray = [[NSMutableArray alloc] init];
    logFromGroupDict = [[NSMutableDictionary alloc] init];
    toArray = [[NSMutableArray alloc] init];
    toServiceArray = [[NSMutableArray alloc] init];
    logToGroupDict = [[NSMutableDictionary alloc] init];
    resultsLock = [[NSLock alloc] init];
    searchingLock = [[NSLock alloc] init];

    [super initWithWindowNibName:windowNibName];
	
    return(self);
}

//dealloc
- (void)dealloc
{
    [resultsLock release];
    [searchingLock release];
    [fromArray release];
    [fromServiceArray release];
    [toArray release];
    [toServiceArray release];
    [availableLogArray release];
    [selectedLogArray release];
    [selectedColumn release];
    [dateFormatter release];
    [displayedLog release];
    [blankImage release];
    
    [filterForContactName release]; filterForContactName = nil;
    [filterForAccountName release]; filterForAccountName = nil;

    [super dealloc];
}

//Init our log filtering tree
- (void)initLogFiltering
{
    NSEnumerator			*enumerator;
    NSString				*folderName;
    NSMutableDictionary                 *toDict = [NSMutableDictionary dictionary];
    NSString				*basePath = [AILoggerPlugin logBasePath];
    NSString				*fromUID, *serviceClass;

    //Process each account folder (/Logs/SERVICE.ACCOUNT_NAME/) - sorting by compare: will result in an ordered list
	//first by service, then by account name.
	enumerator = [[[[NSFileManager defaultManager] directoryContentsAtPath:basePath] sortedArrayUsingSelector:@selector(compare:)] objectEnumerator];
    while((folderName = [enumerator nextObject])){
		if(![folderName isEqualToString:@".DS_Store"]) { // avoid the directory info
			NSEnumerator    *toEnum;
			AILogToGroup    *currentToGroup;			
			AILogFromGroup  *logFromGroup;
			NSMutableSet	*toSetForThisService;
			NSArray         *serviceAndFromUIDArray;
			
			//Determine the service and fromUID - should be SERVICE.ACCOUNT_NAME
			//Check against count to guard in case of old, malformed or otherwise odd folders & whatnot sitting in log base
			serviceAndFromUIDArray = [folderName componentsSeparatedByString:@"."];

			if([serviceAndFromUIDArray count] >= 2){
				serviceClass = [serviceAndFromUIDArray objectAtIndex:0];

				//Use substringFromIndex so we include the rest of the string in the case of a UID with a . in it
				fromUID = [folderName substringFromIndex:([serviceClass length] + 1)]; //One off for the '.'
			}else{
				//Fallback: blank non-nil serviceClass; folderName as the fromUID
				serviceClass = @"";
				fromUID = folderName;
			}

			logFromGroup = [[AILogFromGroup alloc] initWithPath:folderName fromUID:fromUID serviceClass:serviceClass];

			//Store logFromGroup on a key in the form "SERVICE.ACCOUNT_NAME"
			[logFromGroupDict setObject:logFromGroup forKey:folderName];

			//Table access is easiest from an array
			[fromArray addObject:fromUID];
			[fromServiceArray addObject:serviceClass];

			//To processing
			if (!(toSetForThisService = [toDict objectForKey:serviceClass])){
				toSetForThisService = [NSMutableSet set];
				[toDict setObject:toSetForThisService
						   forKey:serviceClass];
			}

			//Add the 'to' for each grouping on this account
			toEnum = [[logFromGroup toGroupArray] objectEnumerator];
			while(currentToGroup = [toEnum nextObject]){
				NSString	*currentTo = [currentToGroup to];
				if(![currentTo isEqual:@".DS_Store"]){
					[toSetForThisService addObject:currentTo];

					//Store currentToGroup on a key in the form "SERVICE.ACCOUNT_NAME/TARGET_CONTACT"
					[logToGroupDict setObject:currentToGroup forKey:[currentToGroup path]];
				}
			}

			[logFromGroup release];
		}
	}
	
	//Table access is easiest from an array; sort and add the just-created to groups to our table arrays
	enumerator = [toDict keyEnumerator];
	while (serviceClass = [enumerator nextObject]){
		NSSet		*toSetForThisService = [toDict objectForKey:serviceClass];
		unsigned	i;
		unsigned	count = [toSetForThisService count];
		
		[toArray addObjectsFromArray:[[toSetForThisService allObjects] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]];
		//Add service to the toServiceArray for each of these objects
		for (i=0 ; i < count ; i++){
			[toServiceArray addObject:serviceClass];
		}
	}
        [textField_totalAccounts setIntValue:[fromArray count]];
        [textField_totalContacts setIntValue:[toArray count]];
}

//
- (NSString *)adiumFrameAutosaveName
{
	return(KEY_LOG_VIEWER_WINDOW_FRAME);
}

//Setup the window before it is displayed
- (void)windowDidLoad
{
	[super windowDidLoad];

	//Toolbar
	[self installToolbar];

	//Localize tableView_results column headers
	[[[tableView_results tableColumnWithIdentifier:@"To"] headerCell] setStringValue:AILocalizedString(@"To",nil)];
	[[[tableView_results tableColumnWithIdentifier:@"From"] headerCell] setStringValue:AILocalizedString(@"From",nil)];
	[[[tableView_results tableColumnWithIdentifier:@"Date"] headerCell] setStringValue:AILocalizedString(@"Date",nil)];

    //Prepare the search controls
    [self buildSearchMenu];
    if([textView_content respondsToSelector:@selector(setUsesFindPanel:)]){
		[textView_content setUsesFindPanel:YES];
    }

    //Sort by date
    selectedColumn = [[tableView_results tableColumnWithIdentifier:@"Date"] retain];

    //Prepare indexing and filter searching
    [self initLogFiltering];
    [plugin prepareLogContentSearching];

    //Begin our initial search
    [searchField_logs setStringValue:(activeSearchString ? activeSearchString : @"")];
    [self startSearchingClearingCurrentResults:YES];
	
    //Configure drawer
    if ([[[adium preferenceController] preferenceForKey:KEY_LOG_VIEWER_DRAWER_STATE
                                                  group:PREF_GROUP_LOGGING] boolValue]){
            [drawer_contacts open];
    }else{
            [drawer_contacts close];
    }
    [drawer_contacts setContentSize:NSMakeSize([[[adium preferenceController] preferenceForKey:KEY_LOG_VIEWER_DRAWER_SIZE
                                                                                         group:PREF_GROUP_LOGGING] floatValue], 0)];
}

//Delete selected log
- (IBAction)deleteSelectedLogs:(id)sender
{
    AILog   *theLog = nil;
    int     row = [tableView_results selectedRow];

    [resultsLock lock];
    if(row >= 0 && row < [selectedLogArray count]){
        theLog = [selectedLogArray objectAtIndex:row];
        sameSelection = (row - 1);
    }
	[resultsLock unlock];
	
	if (theLog){
		//We utilize the logIndexAccessLock so we have exclusive access to the logs
		NSLock              *logAccessLock = [plugin logAccessLock];
		
		//Remember that this locks and unlocks the logAccessLock
		SKIndexRef          logSearchIndex = [plugin logContentIndex];
		SKDocumentRef       document;
		
                useSame = YES;
		[theLog retain];

		[resultsLock lock];
		[selectedLogArray removeObjectAtIndex:row];
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
		[logFromGroupDict release]; logFromGroupDict = [[NSMutableDictionary alloc] init];
		[toArray removeAllObjects]; //note: even if there are no logs, the name will remain [bug or feature?]
		[toServiceArray removeAllObjects];
		[fromArray removeAllObjects];
		[fromServiceArray removeAllObjects];
	
		[self initLogFiltering];

		[tableView_results reloadData];
		[self updateProgressDisplay];
		[self selectDisplayedLog];

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
    
    [self initLogFiltering];
    
    [tableView_results reloadData];
    [self selectDisplayedLog];    
}

//Close the window
- (IBAction)closeWindow:(id)sender
{
    if([self windowShouldClose:nil]){
        [[self window] close];
    }
}

//Called as the window closes
- (BOOL)windowShouldClose:(id)sender
{
	//Determine and save the current state of the drawer
	int		drawerState = [drawer_contacts state];
	NSNumber	*drawerIsOpen = nil;
	
	switch(drawerState){
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
        
        // set preference for drawer size
        [[adium preferenceController] setPreference:[NSNumber numberWithFloat:[drawer_contacts contentSize].width]
                                             forKey:KEY_LOG_VIEWER_DRAWER_SIZE
                                              group:PREF_GROUP_LOGGING];        

    //Disable the search field.  If we don't disable the search field, it will often try to call its target action
    //after the window has closed (and we are gone).  I'm not sure why this happens, but disabling the field
    //before we close the window down seems to prevent the crash.
    [searchField_logs setEnabled:NO];
	
	//Note that the window is closing so we don't take behaviors which could cause messages to the window after
	//it was gone, like responding to a logIndexUpdated message
	windowIsClosing = YES;

    //Abort any in-progress searching and indexing, and wait for their completion
    [self stopSearching];
    [plugin cleanUpLogContentSearching];
	
	[super windowShouldClose:sender];

    //Clean up
	[aggregateLogIndexProgressTimer invalidate];
	[aggregateLogIndexProgressTimer release]; aggregateLogIndexProgressTimer = nil;
	
	//Reset our column widths if needed
	[activeSearchString release]; activeSearchString = nil;
	[self updateRankColumnVisibility];
	
    [sharedLogViewerInstance autorelease]; sharedLogViewerInstance = nil;
	[toolbarItems release];
	
    return(YES);
}

//Prevent the system from moving our window around
- (BOOL)shouldCascadeWindows
{
    return(NO);
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
- (void)updateProgressDisplay
{
    NSMutableString     *progress;
    int			indexComplete, indexTotal;
    BOOL		indexing;

    //We always convey the number of logs being displayed
    [resultsLock lock];
    if(activeSearchString && [activeSearchString length]){
		progress = [NSMutableString stringWithFormat:AILocalizedString(@"Found %i matches for search",nil),[selectedLogArray count]];
    }else if(searching){
		progress = [NSMutableString stringWithString:AILocalizedString(@"Opening logs...",nil)];
    }else{
		progress = [NSMutableString stringWithFormat:AILocalizedString(@"%i logs",nil),[selectedLogArray count]];
    }
    [resultsLock unlock];

    //Append search progress
    if(searching && activeSearchString && [activeSearchString length]){
		[progress appendString:[NSString stringWithFormat:AILocalizedString(@" - Searching for '%@'",nil),activeSearchString]];

		if (filterForAccountName && [filterForAccountName length]){
			[progress appendString:[NSString stringWithFormat:AILocalizedString(@" in chats on %@",nil),filterForAccountName]];
		}else if (filterForContactName && [filterForContactName length]){
			[progress appendString:[NSString stringWithFormat:AILocalizedString(@" in chats with %@",nil),filterForContactName]];
		}
    }

    //Append indexing progress
    if(indexing = [plugin getIndexingProgress:&indexComplete outOf:&indexTotal]){
		[progress appendString:[NSString stringWithFormat:AILocalizedString(@" - Indexing %i of %i",nil),indexComplete, indexTotal]];
    }
    
    //Enable/disable the searching animation
    if(searching || indexing){
		[progressIndicator startAnimation:nil];
    }else{
		[progressIndicator stopAnimation:nil];
    }
    
    [textField_progress setStringValue:progress];
}

//The plugin is informing us that the log indexing changed
- (void)logIndexingProgressUpdate
{
	//Don't do anything if the window is already closing
	if (!windowIsClosing){
		[self updateProgressDisplay];
		
		//If we are searching by content, we should re-search without clearing our current results so the
		//the newly-indexed logs can be added without blanking the current table contents.
		//We set an NSNumber with our current activeSearchID so we will only refresh if we haven't done a new search
		//between the timer being set and firing.
		if (searchMode == LOG_SEARCH_CONTENT){
			if (!aggregateLogIndexProgressTimer){
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
	if ((searchMode == LOG_SEARCH_CONTENT) && ([oldActiveSearchID intValue] == activeSearchID)){
		[self startSearchingClearingCurrentResults:NO];
	}

	[aggregateLogIndexProgressTimer invalidate];
	[aggregateLogIndexProgressTimer release]; aggregateLogIndexProgressTimer = nil;
}

//Refresh the results table
- (void)refreshResults
{
	[self updateProgressDisplay];

	[self refreshResultsSearchIsComplete:NO];
}

- (void)refreshResultsSearchIsComplete:(BOOL)searchIsComplete
{
    [resultsLock lock];
    int count = [selectedLogArray count];
    [resultsLock unlock];
	
    if(!searching || count <= MAX_LOGS_TO_SORT_WHILE_SEARCHING){
		//Sort the logs correctly
		[self sortSelectedLogArrayForTableColumn:selectedColumn direction:sortDirection];
		
		//Refresh the table
		[tableView_results reloadData];

		if (searchIsComplete && automaticSearch){
			//If search is complete, select the first log if requestead and possible
			[self selectFirstLog];
			
		}else{
			BOOL oldAutomaticSearch = automaticSearch;

			//Re-select displayed log, or display another one
			[self selectDisplayedLog];
			
			//We don't want the above re-selection to change our automaticSearch tracking
			//(The only reason automaticSearch should change is in response to user action)
			automaticSearch = oldAutomaticSearch;
		}
    }

    //Update status
    [self updateProgressDisplay];
}

- (void)searchComplete
{
	[refreshResultsTimer invalidate]; [refreshResultsTimer release]; refreshResultsTimer = nil;
	[self refreshResultsSearchIsComplete:YES];
}

//Displays the contents of the specified log in our window
- (void)displayLog:(AILog *)theLog
{
    NSAttributedString	*logText = nil;
    NSString		*logFileText = nil;
	
    if(displayedLog != theLog){
		[displayedLog release];
		displayedLog = [theLog retain];
		
		if(theLog){	    
			//Open the log
			logFileText = [NSString stringWithContentsOfFile:[[AILoggerPlugin logBasePath] stringByAppendingPathComponent:[theLog path]]];                
			
			if(logFileText && [logFileText length]){
				if([[theLog path] hasSuffix:@".html"] || [[theLog path] hasSuffix:@".html.bak"]) {
					logText = [[[NSAttributedString alloc] initWithAttributedString:[AIHTMLDecoder decodeHTML:logFileText]] autorelease];
				}else{
					AITextAttributes *textAttributes = [AITextAttributes textAttributesWithFontFamily:@"Helvetica" traits:0 size:12];
					logText = [[[NSAttributedString alloc] initWithString:logFileText attributes:[textAttributes dictionary]] autorelease];
				}
				
				if(logText && [logText length]){
					//Add pretty formatting to links
					logText = [logText stringByAddingFormattingForLinks];

					//Filter emoticons
					if(showEmoticons){
						logText = [[adium contentController] filterAttributedString:logText
																	usingFilterType:AIFilterMessageDisplay
																		  direction:AIFilterOutgoing
																			context:nil];
					}
					
					NSRange     scrollRange = NSMakeRange([logText length],0);

					//If we are searching by content, highlight the search results
					if(searchMode == LOG_SEARCH_CONTENT){
						NSEnumerator    *enumerator;
						NSString	*searchWord;
						
						enumerator = [[activeSearchString componentsSeparatedByString:@" "] objectEnumerator];
						while(searchWord = [enumerator nextObject]){
							NSRange     occurrence;
							
							logText = [self hilightOccurrencesOfString:searchWord inString:logText firstOccurrence:&occurrence];
							if(occurrence.location < scrollRange.location){
								scrollRange = occurrence;
							}
						}
					}
					
					//Set this string and scroll to the top/bottom/occurrence
					[[textView_content textStorage] setAttributedString:logText];
					if((searchMode == LOG_SEARCH_CONTENT) || automaticSearch){
						[textView_content scrollRangeToVisible:scrollRange];
					}else{
						[textView_content scrollRangeToVisible:NSMakeRange(0,0)];
					}		
				}
			}
		}
		
		//No log selected, empty the view
		if(!logFileText){
			[textView_content setString:@""];
		}
    }
}

//Reselect the displayed log (Or another log if not possible)
- (void)selectDisplayedLog
{
    int     index = NSNotFound;
    
    //Is the log we had selected still in the table?
    //(When performing an automatic search, we ignore the previous selection.  This ensures that we always
    // end up with the newest log selected, even when a search takes multiple passes/refreshes to complete).
    if(!automaticSearch){
		[resultsLock lock];
		index = [selectedLogArray indexOfObject:displayedLog];
		[resultsLock unlock];
    }
	
    if(index != NSNotFound){
		//If our selected log is still around, re-select it
		[tableView_results selectRow:index byExtendingSelection:NO];
		[tableView_results scrollRowToVisible:index];
		
    }
    else{
        if(useSame == YES && sameSelection > 0)
        {
            [tableView_results selectRow:sameSelection byExtendingSelection:NO];
        }
        else
        {   
            [self selectFirstLog];
        }
    }    
    useSame = NO;
}

- (void)selectFirstLog
{
	AILog   *theLog = nil;
	
	//If our selected log is no more, select the first one in the list
	[resultsLock lock];
	if([selectedLogArray count] != 0){
		theLog = [selectedLogArray objectAtIndex:0];
	}
	[resultsLock unlock];
	
	//Change the table selection to this new log
	//We need a little trickery here.  When we change the row, the table view will call our tableViewSelectionDidChange: method.
	//This method will clear the automaticSearch flag, and break any scroll-to-bottom behavior we have going on for the custom
	//search.  As a quick hack, I've added an ignoreSelectionChange flag that can be set to inform our selectionDidChange method
	//that we instanciated this selection change, and not the user.
	ignoreSelectionChange = YES;
	[tableView_results selectRow:0 byExtendingSelection:NO];
	[tableView_results scrollRowToVisible:0];
	ignoreSelectionChange = NO;
	[self displayLog:theLog];  //Manually update the displayed log
}

//Highlight the occurences of a search string within a displayed log
- (NSAttributedString *)hilightOccurrencesOfString:(NSString *)littleString inString:(NSAttributedString *)bigString firstOccurrence:(NSRange *)outRange
{
    NSMutableAttributedString   *outString = [bigString mutableCopy];
    NSString                    *plainBigString = [bigString string];
    NSFont                      *boldFont = [NSFont boldSystemFontOfSize:14];
    int                         location = 0;
    NSRange                     searchRange, foundRange;
	
    outRange->location = NSNotFound;

    //Search for the little string in the big string
    while(location != NSNotFound && location < [plainBigString length]){
        searchRange = NSMakeRange(location, [plainBigString length]-location);
        foundRange = [plainBigString rangeOfString:littleString options:NSCaseInsensitiveSearch range:searchRange];
		
		//Bold and color this match
        if(foundRange.location != NSNotFound){
			if(outRange->location == NSNotFound) *outRange = foundRange;
			
            [outString addAttribute:NSFontAttributeName value:boldFont range:foundRange];
            [outString addAttribute:NSBackgroundColorAttributeName value:[NSColor yellowColor] range:foundRange];
        }
		
        location = NSMaxRange(foundRange);
    }
    
    return([outString autorelease]);
}


//Sorting --------------------------------------------------------------------------------------------------------------
#pragma mark Sorting
//Sorts the selected log array and adjusts the selected column
- (void)sortSelectedLogArrayForTableColumn:(NSTableColumn *)tableColumn direction:(BOOL)direction
{
    NSString	*identifier;
    
    //If there already was a sorted column, remove the indicator image from it.
    if(selectedColumn && selectedColumn != tableColumn){
        [tableView_results setIndicatorImage:nil inTableColumn:selectedColumn];
    }
    
    //Set the indicator image in the newly selected column
    [tableView_results setIndicatorImage:[NSImage imageNamed:(direction ? @"NSDescendingSortIndicator" : @"NSAscendingSortIndicator")]
                           inTableColumn:tableColumn];
    
    //Set the highlighted table column.
    [tableView_results setHighlightedTableColumn:tableColumn];
    [selectedColumn release]; selectedColumn = [tableColumn retain];
    sortDirection = direction;
	
    //Resort the data
    [resultsLock lock];
    identifier = [selectedColumn identifier];
    if([identifier isEqualToString:@"To"]){
		[selectedLogArray sortUsingSelector:(sortDirection ? @selector(compareToReverse:) : @selector(compareTo:))];
		
    }else if([identifier isEqualToString:@"From"]){
        [selectedLogArray sortUsingSelector:(sortDirection ? @selector(compareFromReverse:) : @selector(compareFrom:))];
		
    }else if([identifier isEqualToString:@"Date"]){
        [selectedLogArray sortUsingSelector:(sortDirection ? @selector(compareDateReverse:) : @selector(compareDate:))];
		
    }else if([identifier isEqualToString:@"Rank"]){
	    [selectedLogArray sortUsingSelector:(sortDirection ? @selector(compareRankReverse:) : @selector(compareRank:))];
	}
	
    [resultsLock unlock];
    
    //Reload the data
    [tableView_results reloadData];
    
    //Reapply the selection
    [self selectDisplayedLog];
}

int _sortStringWithKey(id objectA, id objectB, void *key){
    NSString	*stringA = [objectA objectForKey:key];
    NSString	*stringB = [objectB objectForKey:key];
    
    return([stringA compare:stringB]);
}
int _sortStringWithKeyBackwards(id objectA, id objectB, void *key){
    NSString	*stringA = [objectA objectForKey:key];
    NSString	*stringB = [objectB objectForKey:key];
    
    return([stringB compare:stringA]);
}
int _sortDateWithKey(id objectA, id objectB, void *key){
    NSDate	*stringA = [objectA objectForKey:key];
    NSDate	*stringB = [objectB objectForKey:key];
    
    return([stringB compare:stringA]);
}
int _sortDateWithKeyBackwards(id objectA, id objectB, void *key){
    NSDate	*stringA = [objectA objectForKey:key];
    NSDate	*stringB = [objectB objectForKey:key];
    
    return([stringA compare:stringB]);
}


//Searching ------------------------------------------------------------------------------------------------------------
#pragma mark Searching
//(Jag)Change search string
- (void)controlTextDidChange:(NSNotification *)notification
{
    if(searchMode != LOG_SEARCH_CONTENT){
		[self updateSearch:nil];
    }
}

//Change search string (Called by searchfield)
- (IBAction)updateSearch:(id)sender
{
    automaticSearch = NO;
    [self setSearchString:[searchField_logs stringValue]];
    [self startSearchingClearingCurrentResults:YES];
}

//Change search mode (Called by mode menu)
- (IBAction)selectSearchType:(id)sender
{
    automaticSearch = NO;
    [self setSearchMode:[sender tag]];
    [self startSearchingClearingCurrentResults:YES];
}

//Begin a specific search
- (void)setSearchString:(NSString *)inString mode:(LogSearchMode)inMode
{
    automaticSearch = YES;
    [self setSearchString:inString];
    [self setSearchMode:inMode];
    [self startSearchingClearingCurrentResults:YES];
}

//Begin the current search
- (void)startSearchingClearingCurrentResults:(BOOL)clearCurrentResults
{
    NSDictionary    *searchDict;
    
    //Stop any existing searches
    [self stopSearching];
    	
    //Once all searches have exited, we can start a new one
	if(clearCurrentResults){
		[resultsLock lock];
		[selectedLogArray release]; selectedLogArray = [[NSMutableArray alloc] init];
		[resultsLock unlock];
	}
	
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
	
    [searchingLock unlock];
}

//Abort any active searches
- (void)stopSearching
{
    //Increase the active search ID so any existing searches stop, and then
    //wait for any active searches to finish and release the lock
    activeSearchID++;
    [searchingLock lock]; [searchingLock unlock];
	
	//If the plugin is in the middle of indexing, and we are content searching, we could be autoupdating a search.
	//Be sure to invalidate the timer.
	[aggregateLogIndexProgressTimer invalidate];
	[aggregateLogIndexProgressTimer release]; aggregateLogIndexProgressTimer = nil;
}

//Set the active search mode (Does not invoke a search)
- (void)setSearchMode:(LogSearchMode)inMode
{
    searchMode = inMode;
	
	//Clear any filter from the table if it's the current mode, as well
	switch(searchMode){
		case LOG_SEARCH_FROM:
			[filterForAccountName release]; filterForAccountName = nil;
			break;
		case LOG_SEARCH_TO:
			[filterForContactName release]; filterForContactName = nil;
			break;
			
		//Take no action for date and content searching
		case LOG_SEARCH_DATE:
		case LOG_SEARCH_CONTENT:
			break;
	}

	[self updateRankColumnVisibility];
    [self buildSearchMenu];
}

- (void)updateRankColumnVisibility
{
	NSTableColumn	*resultsColumn = [tableView_results tableColumnWithIdentifier:@"Rank"];
	NSArray		*tableColumns;
	NSTableColumn	*nextDoorNeighbor;
	
	if ((searchMode == LOG_SEARCH_CONTENT) && ([activeSearchString length])){
		//Add the resultsColumn and resize if it should be shown but is not at present
		if (!resultsColumn){			
			//Set up the results column
			resultsColumn = [[NSTableColumn alloc] initWithIdentifier:@"Rank"];
			[[resultsColumn headerCell] setStringValue:AILocalizedString(@"Rank",nil)];
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
	}else{
		//Remove the resultsColumn and resize if it should not be shown but is at present
		if (resultsColumn){
			//Adjust the column to the results column's left to take up the space again
			tableColumns = [tableView_results tableColumns];
			nextDoorNeighbor = [tableColumns objectAtIndex:([tableColumns indexOfObject:resultsColumn] - 1)];
			[nextDoorNeighbor setWidth:[nextDoorNeighbor width]+[resultsColumn width]];

			//Remove it
			[tableView_results removeTableColumn:resultsColumn];
		}
	}
}

//Set the active search string (Does not invoke a search)
- (void)setSearchString:(NSString *)inString
{
    if(![[searchField_logs stringValue] isEqualToString:inString]){
		[searchField_logs setStringValue:(inString ? inString : @"")];
    }
    [activeSearchString release]; activeSearchString = [[searchField_logs stringValue] copy];
	
	//Our logs are stored as HTML.  Non-ASCII characters are therefore HTML-encoded.  We need to have an
	//encoded version of our search string with which to search when doing a content-based search, as that's
	//how they are on disk.
	if(searchMode == LOG_SEARCH_CONTENT){
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
                                         attachmentImagesOnlyForSending:NO 
                                                         simpleTagsOnly:NO] retain];
		AILog(@"Search will be on %@",activeSearchStringEncoded);
	}else{
		[activeSearchStringEncoded release]; activeSearchStringEncoded = nil;
	}

	[self updateRankColumnVisibility];
}

//Build the search mode menu
- (void)buildSearchMenu
{
    NSMenu  *cellMenu = [[[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:SEARCH_MENU] autorelease];
    [cellMenu addItem:[self _menuItemWithTitle:FROM forSearchMode:LOG_SEARCH_FROM]];
    [cellMenu addItem:[self _menuItemWithTitle:TO forSearchMode:LOG_SEARCH_TO]];
    [cellMenu addItem:[self _menuItemWithTitle:DATE forSearchMode:LOG_SEARCH_DATE]];
    if(!popUp_jagSearchMode) [cellMenu addItem:[self _menuItemWithTitle:CONTENT forSearchMode:LOG_SEARCH_CONTENT]]; //Not in jag
    
    //In 10.2 we use a popup button here, later we use the search field's embedded menu
    if(popUp_jagSearchMode){
		[popUp_jagSearchMode setMenu:cellMenu];
		[popUp_jagSearchMode selectItem:[cellMenu itemWithTag:searchMode]];
    }else{
		[[searchField_logs cell] setSearchMenuTemplate:cellMenu];
    }
}

//Returns a menu item for the search mode menu
- (NSMenuItem *)_menuItemWithTitle:(NSString *)title forSearchMode:(LogSearchMode)mode
{
    NSMenuItem  *menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:title 
																				 action:@selector(selectSearchType:) 
																		  keyEquivalent:@""];
    [menuItem setTag:mode];
    [menuItem setState:(mode == searchMode ? NSOnState : NSOffState)];
    
    return([menuItem autorelease]);
}


//Threaded filter/search methods ---------------------------------------------------------------------------------------
#pragma mark Threaded filter/search methods
//Search the logs, filtering out any matching logs into the selectedLogArray
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
    if(searchID == activeSearchID){ //If we're still supposed to go
		searching = YES;
		
		//Search
		if (searchString && [searchString length]){
			switch(mode){
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
		}else{
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
    AILog               *theLog;
    UInt32		lastUpdate = TickCount();
    
    NSCalendarDate	*searchStringDate = nil;
	
	if ((mode == LOG_SEARCH_DATE) && (searchString != nil)){
		searchStringDate = [[NSDate dateWithNaturalLanguageString:searchString]  dateWithCalendarFormat:nil timeZone:nil];
	}
	
    //Walk through every 'from' group
    fromEnumerator = [logFromGroupDict objectEnumerator];
    while((fromGroup = [fromEnumerator nextObject]) && (searchID == activeSearchID)){
		
		/*
		 When searching in LOG_SEARCH_FROM, we only proceed into matching groups
		 For all other search modes, we always proceed here so long as either:
			a) We are not filtering for the account name or
			b) The account name matches
		 */
		if((!filterForAccountName || ([[fromGroup fromUID] caseInsensitiveCompare:filterForAccountName] == NSOrderedSame)) &&
		   ((mode != LOG_SEARCH_FROM) ||
		   (!searchString) || 
		   ([[fromGroup fromUID] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound))){
			
			//Walk through every 'to' group
			toEnumerator = [[fromGroup toGroupArray] objectEnumerator];
			while((toGroup = [toEnumerator nextObject]) && (searchID == activeSearchID)){
				
				/*
				 When searching in LOG_SEARCH_TO, we only proceed into matching groups
				 For all other search modes, we always proceed here so long as either:
					a) We are not filtering for the contact name or
					b) The contact name matches
				 */
				if((!filterForContactName || ([[toGroup to] caseInsensitiveCompare:filterForContactName] == NSOrderedSame)) &&
				   ((mode != LOG_SEARCH_TO) ||
				   (!searchString) || 
				   ([[toGroup to] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound))){
					
					//Walk through every log
					logEnumerator = [toGroup logEnumerator];
					while((theLog = [logEnumerator nextObject]) && (searchID == activeSearchID)){
						
						//When searching in LOG_SEARCH_DATE, we must have matching dates
						//For all other search modes, we always proceed here
						if((mode != LOG_SEARCH_DATE) ||
						   (!searchString) ||
						   (searchStringDate && [theLog isFromSameDayAsDate:searchStringDate])){
							
							//Add the log
							[resultsLock lock];
							[selectedLogArray addObject:theLog];
							[resultsLock unlock];
							
							//Update our status
							if(lastUpdate == 0 || TickCount() > lastUpdate + LOG_SEARCH_STATUS_INTERVAL){
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
	
	filterForContactName = [inContactName retain];
	
	//If the search mode is currently the TO field, switch it to content, which is what it should now intuitively do
	if (searchMode == LOG_SEARCH_TO){
		[self setSearchMode:LOG_SEARCH_CONTENT];
	}
	
    [self startSearchingClearingCurrentResults:YES];
}

- (void)filterForAccountName:(NSString *)inAccountName
{
	[filterForContactName release]; filterForContactName = nil;
	[filterForAccountName release]; filterForAccountName = nil;

	filterForAccountName = [inAccountName retain];

	//If the search mode is currently the FROM field, switch it to content, which is what it should now intuitively do
	if (searchMode == LOG_SEARCH_FROM){
		[self setSearchMode:LOG_SEARCH_CONTENT];
	}

    [self startSearchingClearingCurrentResults:YES];	
}

Boolean ContentResultsFilter (SKIndexRef     inIndex,
                              SKDocumentRef     inDocument,
                              void      *inContext)
{
	if(filterForContactName){
		//Searching for a specific contact
		NSString		*path = (NSString *)SKDocumentGetName(inDocument);
		NSString		*toPath = [path stringByDeletingLastPathComponent];
		AILogToGroup            *toGroup = [logToGroupDict objectForKey:toPath];
		
		return([[toGroup to] caseInsensitiveCompare:filterForContactName] == NSOrderedSame);

	}else if(filterForAccountName){
		//Searching for a specific account
		NSString		*path = (NSString *)SKDocumentGetName(inDocument);
		NSString		*toPath = [path stringByDeletingLastPathComponent];
		NSString		*fromPath = [toPath stringByDeletingLastPathComponent];
		AILogFromGroup          *fromGroup = [logFromGroupDict objectForKey:fromPath];

		return([[fromGroup fromUID] caseInsensitiveCompare:filterForAccountName] == NSOrderedSame);
		
	}else{
		return(true);
	}
}


//Perform a content search of the indexed logs
- (void)_logContentFilter:(NSString *)searchString searchID:(int)searchID
{
	SKIndexRef		logSearchIndex = [plugin logContentIndex];
	SKSearchGroupRef        searchGroup;
	CFArrayRef		indexArray;
	SKSearchResultsRef      searchResults;
	int			resultCount;    
	UInt32			lastUpdate = TickCount();
	void			*indexPtr = &logSearchIndex;
	
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
	[logAccessLock unlock];
	
	//Process the results
	[logAccessLock lock];
	
	if(resultCount = SKSearchResultsGetCount(searchResults)){
		SKDocumentRef   *outDocumentsArray = malloc(sizeof(SKDocumentRef) * LOG_RESULT_CLUMP_SIZE);
		float		*outScoresArray = malloc(sizeof(float) * LOG_RESULT_CLUMP_SIZE);
		NSRange		resultRange = NSMakeRange(0, resultCount);
		
		//Read the results in LOG_RESULT_CLUMP_SIZE at a time
		while(resultRange.location < resultCount && (searchID == activeSearchID)){
			int		count;
			int		i;
			
			//Get the next LOG_RESULT_CLUMP_SIZE results
			count = SKSearchResultsGetInfoInRange(searchResults,
                                                              CFRangeMake(resultRange.location, LOG_RESULT_CLUMP_SIZE),
                                                              outDocumentsArray,
                                                              NULL,
                                                              outScoresArray);
			
			//Process the results
			for(i = 0; (i < count) && (searchID == activeSearchID); i++){
				NSString		*path = (NSString *)SKDocumentGetName(outDocumentsArray[i]);
				NSString		*toPath = [path stringByDeletingLastPathComponent];
				AILog			*theLog;
				
				/*	
					Add the log - if our index is currently out of date (for example, a log was just deleted) 
				 we may get a null log, so be careful.
				 */
				[resultsLock lock];
				theLog = [[logToGroupDict objectForKey:toPath] logAtPath:path];
				if(theLog && ![selectedLogArray containsObjectIdenticalTo:theLog]){
					[theLog setRankingPercentage:outScoresArray[i]];
					[selectedLogArray addObject:theLog];
				}
				[resultsLock unlock];
			}	 
			
			//Update our status
			if(lastUpdate == 0 || TickCount() > lastUpdate + LOG_SEARCH_STATUS_INTERVAL){
				[self updateProgressDisplay];
				lastUpdate = TickCount();
			}
			
			resultRange.location += LOG_RESULT_CLUMP_SIZE;
			resultRange.length -= LOG_RESULT_CLUMP_SIZE;
		}
	}
	
	CFRelease(indexArray);
	CFRelease(searchGroup);
	CFRelease(searchResults);
	
	//Release the logsLock so the plugin can return to regularly scheduled programming if it wants to
	[logAccessLock unlock];
}


//Search results table view --------------------------------------------------------------------------------------------
#pragma mark Search results table view
//Since this table view's source data will be accessed from within other threads, we need to lock before
//accessing it.  We also must be very sure that an incorrect row request is handled silently, since this
//can occur if the array size is changed during the reload.
- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
    int count;
    
    [resultsLock lock];
    count = [selectedLogArray count];
    [resultsLock unlock];
    
    return(count);
}


- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    NSString	*identifier = [tableColumn identifier];

	if([identifier isEqualToString:@"Rank"] && row >= 0 && row < [selectedLogArray count]){
		AILog       *theLog = [selectedLogArray objectAtIndex:row];
		
		[aCell setPercentage:[theLog rankingPercentage]];
	}
}

//
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    NSString	*identifier = [tableColumn identifier];
    id          value = nil;
    
    [resultsLock lock];
    if(row < 0 || row >= [selectedLogArray count]){
		if([identifier isEqualToString:@"Service"]){
			value = blankImage;
		}else{
			value = @"";
		}
		
	}else{
		AILog       *theLog = [selectedLogArray objectAtIndex:row];

		if([identifier isEqualToString:@"To"]){
			value = [theLog to]; 
			
		}else if([identifier isEqualToString:@"From"]){
			value = [theLog from];
			
		}else if([identifier isEqualToString:@"Date"]){
			value = [dateFormatter stringForObjectValue:[theLog date]];
			
		}else if([identifier isEqualToString:@"Service"]){
			NSString	*serviceClass;
			NSImage		*image;
			
			serviceClass = [theLog serviceClass];
			image = [AIServiceIcons serviceIconForService:[[adium accountController] firstServiceWithServiceID:serviceClass]
													 type:AIServiceIconSmall
												direction:AIIconNormal];
			value = (image ? image : blankImage);
		}
    }
    [resultsLock unlock];
    
    return(value);
}

//
- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    if(!ignoreSelectionChange){
		AILog   *theLog = nil;
		int     row = [tableView_results selectedRow];
		
		//Update the displayed log
		automaticSearch = NO;
		
		[resultsLock lock];
		if(row >= 0 && row < [selectedLogArray count]){
			theLog = [selectedLogArray objectAtIndex:row];
		}
		[resultsLock unlock];
		
		[self displayLog:theLog];
    }
}

//Sort the log array & reflect the new column
- (void)tableView:(NSTableView*)tableView didClickTableColumn:(NSTableColumn *)tableColumn
{    
    [self sortSelectedLogArrayForTableColumn:tableColumn
                                   direction:(selectedColumn == tableColumn ? !sortDirection : sortDirection)];
}

- (void)tableViewDeleteSelectedRows:(NSTableView *)tableView
{
    [self deleteSelectedLogs:nil];
}

- (IBAction)toggleDrawer:(id)sender
{
    [drawer_contacts toggle:sender];
}

- (IBAction)toggleEmoticonFiltering:(id)sender
{
	AILog	*log = displayedLog;
	
	showEmoticons = !showEmoticons;
	[sender setLabel:(showEmoticons ? HIDE_EMOTICONS : SHOW_EMOTICONS)];
	[sender setImage:[NSImage imageNamed:(showEmoticons ? IMAGE_EMOTICONS_ON : IMAGE_EMOTICONS_OFF) forClass:[self class]]];
	
	//Refresh the displayed log
	[displayedLog autorelease]; displayedLog = nil;
	[self displayLog:log];
}


//Window Toolbar -------------------------------------------------------------------------------------------------------
#pragma mark Window Toolbar
- (void)installToolbar
{	
    NSToolbar 		*toolbar = [[[NSToolbar alloc] initWithIdentifier:TOOLBAR_LOG_VIEWER] autorelease];
    NSToolbarItem	*toolbarItem;
	
    [toolbar setDelegate:self];
    [toolbar setDisplayMode:NSToolbarDisplayModeIconAndLabel];
    [toolbar setSizeMode:NSToolbarSizeModeRegular];
    [toolbar setVisible:YES];
    [toolbar setAllowsUserCustomization:YES];
    [toolbar setAutosavesConfiguration:YES];
    toolbarItems = [[NSMutableDictionary alloc] init];

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
	//Delete Logs
	[AIToolbarUtilities addToolbarItemToDictionary:toolbarItems
                                        withIdentifier:@"delete"
                                                 label:AILocalizedString(@"Delete",nil)
                                          paletteLabel:AILocalizedString(@"Delete",nil)
                                               toolTip:AILocalizedString(@"Delete selected log",nil)
                                                target:self
                                       settingSelector:@selector(setImage:)
                                           itemContent:[NSImage imageNamed:@"remove" forClass:[self class]]
                                                action:@selector(deleteSelectedLogs:)
                                                  menu:nil];
	//Search
	[self window]; //Ensure the window is loaded, since we're pulling the search view from our nib
	toolbarItem = [AIToolbarUtilities toolbarItemWithIdentifier:@"search"
                                                              label:AILocalizedString(@"Search",nil)
                                                       paletteLabel:AILocalizedString(@"Search",nil)
                                                            toolTip:AILocalizedString(@"Search or filter logs",nil)
                                                             target:self
                                                    settingSelector:@selector(setView:)
                                                        itemContent:view_SearchField
                                                            action:@selector(updateSearch:)
                                                               menu:nil];
	[toolbarItem setMinSize:NSMakeSize(150, NSHeight([view_SearchField frame]))];
	[toolbarItem setMaxSize:NSMakeSize(230, NSHeight([view_SearchField frame]))];
	[toolbarItems setObject:toolbarItem forKey:[toolbarItem itemIdentifier]];

	//Toggle Emoticons
	[AIToolbarUtilities addToolbarItemToDictionary:toolbarItems
                                        withIdentifier:@"toggleemoticons"
                                                 label:(showEmoticons ? HIDE_EMOTICONS : SHOW_EMOTICONS)
                                          paletteLabel:AILocalizedString(@"Show/Hide Emoticons",nil)
                                               toolTip:AILocalizedString(@"Show or hide emoticons in logs",nil)
                                                target:self
                                       settingSelector:@selector(setImage:)
                                           itemContent:[NSImage imageNamed:(showEmoticons ? IMAGE_EMOTICONS_ON : IMAGE_EMOTICONS_OFF) forClass:[self class]]
                                                action:@selector(toggleEmoticonFiltering:)
                                                  menu:nil];

	[[self window] setToolbar:toolbar];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    return([AIToolbarUtilities toolbarItemFromDictionary:toolbarItems withIdentifier:itemIdentifier]);
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
    return([NSArray arrayWithObjects:@"delete", @"toggleemoticons", NSToolbarFlexibleSpaceItemIdentifier, @"search", NSToolbarSeparatorItemIdentifier, @"toggledrawer", nil]);
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
    return([[toolbarItems allKeys] arrayByAddingObjectsFromArray:
		[NSArray arrayWithObjects:NSToolbarSeparatorItemIdentifier,
			NSToolbarSpaceItemIdentifier,
			NSToolbarFlexibleSpaceItemIdentifier,
			NSToolbarCustomizeToolbarItemIdentifier, nil]]);
}

@end


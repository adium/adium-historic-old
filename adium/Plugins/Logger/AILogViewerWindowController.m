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

#define LOG_VIEWER_NIB				@"LogViewer"
#define LOG_VIEWER_JAG_NIB			@"LogViewerJag"
#define KEY_LOG_VIEWER_WINDOW_FRAME		@"Log Viewer Frame"
#define	PREF_GROUP_CONTACT_LIST			@"Contact List"
#define KEY_LOG_VIEWER_GROUP_STATE		@"Log Viewer Group State"	//Expand/Collapse state of groups

#define MAX_LOGS_TO_SORT_WHILE_SEARCHING	1000	//Max number of logs we will live sort while searching
#define LOG_SEARCH_STATUS_INTERVAL		20      //1/60ths of a second to wait before refreshing search status

#define LOG_CONTENT_SEARCH_MAX_RESULTS		10000   //Max results allowed from a search
#define LOG_RESULT_CLUMP_SIZE			10      //Number of logs to fetch at a time

#define SEARCH_MENU     AILocalizedString(@"Search Menu",nil)
#define FROM		AILocalizedString(@"From",nil)
#define TO		AILocalizedString(@"To",nil)
#define DATE		AILocalizedString(@"Date",nil)
#define CONTENT		AILocalizedString(@"Content",nil)

@interface AILogViewerWindowController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName plugin:(id)inPlugin;
- (void)initLogFiltering;
- (void)updateProgressDisplay;
- (void)refreshResults;
- (void)displayLog:(AILog *)log;
- (void)selectDisplayedLog;
- (NSAttributedString *)hilightOccurrencesOfString:(NSString *)littleString inString:(NSAttributedString *)bigString firstOccurrence:(NSRange *)outRange;
- (void)sortSelectedLogArrayForTableColumn:(NSTableColumn *)tableColumn direction:(BOOL)direction;
- (void)setSearchString:(NSString *)inString mode:(LogSearchMode)inMode;
- (void)startSearching;
- (void)stopSearching;
- (void)setSearchMode:(LogSearchMode)inMode;
- (void)setSearchString:(NSString *)inString;
- (void)buildSearchMenu;
- (NSMenuItem *)_menuItemWithTitle:(NSString *)title forSearchMode:(LogSearchMode)mode;
- (void)_logFilter:(NSString *)searchString searchID:(int)searchID mode:(LogSearchMode)mode;
- (void)_logContentFilter:(NSString *)searchString searchID:(int)searchID;
@end

int _sortStringWithKey(id objectA, id objectB, void *key);
int _sortStringWithKeyBackwards(id objectA, id objectB, void *key);
int _sortDateWithKey(id objectA, id objectB, void *key);
int _sortDateWithKeyBackwards(id objectA, id objectB, void *key);

@implementation AILogViewerWindowController

//Open the log viewer window
static AILogViewerWindowController *sharedLogViewerInstance = nil;
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
    if(inContact) [sharedLogViewerInstance setSearchString:[inContact UID] mode:LOG_SEARCH_TO];
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
    automaticSearch = NO;
    activeSearchString = nil;
    displayedLog = nil;
    
    sortDirection = YES;
    searchMode = LOG_SEARCH_TO;
    dateFormatter = [[NSDateFormatter alloc] initWithDateFormat:[[NSUserDefaults standardUserDefaults] stringForKey:NSDateFormatString] allowNaturalLanguage:YES];
    availableLogArray = [[NSMutableArray alloc] init];
    selectedLogArray = [[NSMutableArray alloc] init];
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
    [availableLogArray release];
    [selectedLogArray release];
    [selectedColumn release];
    [dateFormatter release];
    [displayedLog release];
    
    [super dealloc];
}

//Init our log filtering tree
- (void)initLogFiltering
{
    NSString		*logFolderPath;
    NSEnumerator	*enumerator;
    NSString		*folderName;

    //Process each account folder (/Logs/SERVICE.ACCOUNT_NAME/)
    logFolderPath = [[[[adium loginController] userDirectory] stringByAppendingPathComponent:PATH_LOGS] stringByExpandingTildeInPath];
    enumerator = [[[NSFileManager defaultManager] directoryContentsAtPath:[AILoggerPlugin logBasePath]] objectEnumerator];
    while((folderName = [enumerator nextObject])){
		AILogFromGroup  *logFromGroup = [[AILogFromGroup alloc] initWithPath:folderName from:folderName];
		
		[availableLogArray addObject:logFromGroup];
		[logFromGroup release];
    }
}

//Setup the window before it is displayed
- (void)windowDidLoad
{
    NSString	*savedFrame;

    //Restore the window position
    savedFrame = [[[adium preferenceController] preferencesForGroup:PREF_GROUP_WINDOW_POSITIONS] objectForKey:KEY_LOG_VIEWER_WINDOW_FRAME];
    if(savedFrame){
        [[self window] setFrameFromString:savedFrame];
    }else{
        [[self window] center];
    }

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
    if(activeSearchString) [searchField_logs setStringValue:activeSearchString];
    [self updateSearch:nil];
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
    //Disable the search field.  If we don't disable the search field, it will often try to call it's target action
    //after the window has closed (and we are gone).  I'm not sure why this happens, but disabling the field
    //before we close the window down seems to prevent the crash.
    [searchField_logs setEnabled:NO];
    
    //Abort any in-progress searching and indexing, and wait for their completion
    [self stopSearching];
    [plugin cleanUpLogContentSearching];
    
    //Save the window position
    [[adium preferenceController] setPreference:[[self window] stringWithSavedFrame]
                                         forKey:KEY_LOG_VIEWER_WINDOW_FRAME
                                          group:PREF_GROUP_WINDOW_POSITIONS];

    //Clean up
    [sharedLogViewerInstance autorelease]; sharedLogViewerInstance = nil;
    
    return(YES);
}

//Prevent the system from moving our window around
- (BOOL)shouldCascadeWindows
{
    return(NO);
}


//Display ----------------------------------------------------------------------------------------------------
//Update log viewer progress string to reflect current status
- (void)updateProgressDisplay
{
    NSMutableString     *progress;
    int			indexComplete, indexTotal;
    BOOL		indexing;
	
    //We always convey the number of logs being displayed
    [resultsLock lock];
    if(activeSearchString && [activeSearchString length]){
		progress = [NSMutableString stringWithFormat:@"Found %i matches for search",[selectedLogArray count]];
    }else if(searching){
		progress = [NSMutableString stringWithString:@"Opening logs..."];
    }else{
		progress = [NSMutableString stringWithFormat:@"%i logs",[selectedLogArray count]];
    }
    [resultsLock unlock];
    
    //Append search progress
    if(searching && activeSearchString && [activeSearchString length]){
		[progress appendString:[NSString stringWithFormat:@" - Searching for '%@'",activeSearchString]];
    }
    
    //Append indexing progress
    if(indexing = [plugin getIndexingProgress:&indexComplete outOf:&indexTotal]){
		[progress appendString:[NSString stringWithFormat:@" - Indexing %i of %i",indexComplete, indexTotal]];
    }
    
    //Enable/disable the searching animation
    if(searching || indexing){
		[progressIndicator startAnimation:nil];
    }else{
		[progressIndicator stopAnimation:nil];
    }
    
    [textField_progress setStringValue:progress];
}

//Refresh the results table
- (void)refreshResults
{
    [resultsLock lock];
    int count = [selectedLogArray count];
    [resultsLock unlock];
	
    if(!searching || count < MAX_LOGS_TO_SORT_WHILE_SEARCHING){
		//Sort the logs correctly
		[self sortSelectedLogArrayForTableColumn:selectedColumn direction:sortDirection];
		
		//Refresh the table
		[tableView_results reloadData];
		
		//Re-select displayed log, or display another one
		[self selectDisplayedLog];
    }
    
    //Update status
    [self updateProgressDisplay];
}

//Displays the contents of the specified log in our window
- (void)displayLog:(AILog *)theLog
{
    NSAttributedString	*logText = nil;
    NSString			*logFileText = nil;

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
					NSRange     scrollRange = NSMakeRange([logText length],0);
					
					//Add pretty formatting to links
					logText = [logText stringByAddingFormattingForLinks];
					
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
		
    }else{
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
}

//Highlight the occurences of a search string within a displayed log
- (NSAttributedString *)hilightOccurrencesOfString:(NSString *)littleString inString:(NSAttributedString *)bigString firstOccurrence:(NSRange *)outRange
{
    NSMutableAttributedString  *outString = [bigString mutableCopy];
    NSString	*plainBigString = [bigString string];
    NSFont		*boldFont = [NSFont boldSystemFontOfSize:14];
    int			location = 0;
    NSRange		searchRange, foundRange;
	
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


//Sorting ----------------------------------------------------------------------------------------------------
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
    if([identifier compare:@"To"] == 0){
	[selectedLogArray sortUsingSelector:(sortDirection ? @selector(compareToReverse:) : @selector(compareTo:))];
	
    }else if([identifier compare:@"From"] == 0){
        [selectedLogArray sortUsingSelector:(sortDirection ? @selector(compareFromReverse:) : @selector(compareFrom:))];
	
    }else if([identifier compare:@"Date"] == 0){
        [selectedLogArray sortUsingSelector:(sortDirection ? @selector(compareDateReverse:) : @selector(compareDate:))];

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


//Searching ----------------------------------------------------------------------------------------------------
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
    [self startSearching];
}

//Change search mode (Called by mode menu)
- (IBAction)selectSearchType:(id)sender
{
    automaticSearch = NO;
    [self setSearchMode:[sender tag]];
    [self startSearching];
}

//Begin a specific search
- (void)setSearchString:(NSString *)inString mode:(LogSearchMode)inMode
{
    automaticSearch = YES;
    [self setSearchString:inString];
    [self setSearchMode:inMode];
    [self startSearching];
}

//Begin the current search
- (void)startSearching
{
    NSDictionary    *searchDict;
    
    //Stop any existing searches
    [self stopSearching];
    
    NSLog(@"startSearching");

    //Once all searches have exited, we can start a new one
    [resultsLock lock];
    [selectedLogArray release]; selectedLogArray = [[NSMutableArray alloc] init];
    [resultsLock unlock];
    searchDict = [NSDictionary dictionaryWithObjectsAndKeys:
	[NSNumber numberWithInt:activeSearchID], @"ID",
	[NSNumber numberWithInt:searchMode], @"Mode",
	activeSearchString, @"String",
	nil];
    [NSThread detachNewThreadSelector:@selector(filterLogsWithSearch:) toTarget:self withObject:searchDict];
    
    [searchingLock unlock];
}

//Abort any active searches
- (void)stopSearching
{
    //Increase the active search ID so any existing searches stop, and then
    //wait for any active searches to finish and release the lock
    activeSearchID++;
    [searchingLock lock]; [searchingLock unlock];
}

//Set the active search mode (Does not invoke a search)
- (void)setSearchMode:(LogSearchMode)inMode
{
    searchMode = inMode;
    [self buildSearchMenu];
}

//Set the active search string (Does not invoke a search)
- (void)setSearchString:(NSString *)inString
{
    if([[searchField_logs stringValue] compare:inString] != 0){
	[searchField_logs setStringValue:inString];
    }
    [activeSearchString release]; activeSearchString = [[searchField_logs stringValue] copy];
}

//Build the search mode menu
- (void)buildSearchMenu
{
    NSMenu  *cellMenu = [[[NSMenu alloc] initWithTitle:SEARCH_MENU] autorelease];
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
    NSMenuItem  *menuItem = [[NSMenuItem alloc] initWithTitle:title action:@selector(selectSearchType:) keyEquivalent:@""];
    [menuItem setTag:mode];
    [menuItem setState:(mode == searchMode ? NSOnState : NSOffState)];
    
    return([menuItem autorelease]);
}


//Threaded filter/search methods ------------------------------------------------------------------------------------------
//Search the logs, filtering out any matching logs into the selectedLogArray
- (void)filterLogsWithSearch:(NSDictionary *)searchInfoDict
{
    NSAutoreleasePool   *pool = [[NSAutoreleasePool alloc] init];
    int			mode = [[searchInfoDict objectForKey:@"Mode"] intValue];
    int			searchID = [[searchInfoDict objectForKey:@"ID"] intValue];
    NSString		*searchString = [searchInfoDict objectForKey:@"String"];
    
    //Lock down new thread creation until this thread is complete
    //We must be careful not to wait on performing any main thread selectors when this lock is set!!
    [searchingLock lock];
    if(searchID == activeSearchID){ //If we're still supposed to go
	searching = YES;
	
	//Search
	if(searchString && [searchString length]){
	    switch(mode){
		case LOG_SEARCH_FROM:
		case LOG_SEARCH_TO:
		case LOG_SEARCH_DATE:
		    [self _logFilter:searchString searchID:searchID mode:mode];
		break;
		case LOG_SEARCH_CONTENT:
		    [self _logContentFilter:searchString searchID:searchID];
		break;
	    }
	}else{
	    [self _logFilter:nil searchID:searchID mode:mode];
	}
    
	//Refresh
	searching = NO;
	[self performSelectorOnMainThread:@selector(refreshResults) withObject:nil waitUntilDone:NO];
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
    NSEnumerator    *fromEnumerator, *toEnumerator, *logEnumerator;
    AILogToGroup    *toGroup;
    AILogFromGroup  *fromGroup;
    AILog			*theLog;
    UInt32			lastUpdate = TickCount();
    
    //Walk through every 'from' group
    fromEnumerator = [availableLogArray objectEnumerator];
    while((fromGroup = [fromEnumerator nextObject]) && (searchID == activeSearchID)){
		
		//When searching in LOG_SEARCH_FROM, we only proceed into matching groups
		//For all other search modes, we always proceed here
		if((mode != LOG_SEARCH_FROM) ||
		   (!searchString) || 
		   ([[fromGroup from] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound)){
			
			//Walk through every 'to' group
			toEnumerator = [[fromGroup toGroupArray] objectEnumerator];
			while((toGroup = [toEnumerator nextObject]) && (searchID == activeSearchID)){
				
				//When searching in LOG_SEARCH_TO, we only proceed into matching groups
				//For all other search modes, we always proceed here
				if((mode != LOG_SEARCH_TO) ||
				   (!searchString) || 
				   ([[toGroup to] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound)){
					
					//Walk through every log
					logEnumerator = [[toGroup logArray] objectEnumerator];
					while((theLog = [logEnumerator nextObject]) && (searchID == activeSearchID)){
						
						//When searching in LOG_SEARCH_DATE, we must have matching dates
						//For all other search modes, we always proceed here
						if((mode != LOG_SEARCH_DATE) ||
						   (!searchString) ||
						   ([[theLog dateSearchString] rangeOfString:searchString 
															 options:NSCaseInsensitiveSearch].location != NSNotFound)){
							
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

//Perform a content search of the indexed logs
- (void)_logContentFilter:(NSString *)searchString searchID:(int)searchID
{
    SKSearchGroupRef    searchGroup;
    CFArrayRef			indexArray;
    SKSearchResultsRef  searchResults;
    int					resultCount;    
    UInt32				lastUpdate = TickCount();
    SKIndexRef			logSearchIndex = [plugin logContentIndex];
    void				*indexPtr = &logSearchIndex;
	
    //Perform the content search
    indexArray = CFArrayCreate(NULL, indexPtr, 1, &kCFTypeArrayCallBacks);
    searchGroup = SKSearchGroupCreate(indexArray);
    searchResults = SKSearchResultsCreateWithQuery(searchGroup,
												   (CFStringRef)searchString,
												   kSKSearchRanked,
												   LOG_CONTENT_SEARCH_MAX_RESULTS,
												   NULL,
												   NULL);
    
    //Process the results
    if(resultCount = SKSearchResultsGetCount(searchResults)){
		SKDocumentRef   *outDocumentsArray = malloc(sizeof(SKDocumentRef) * LOG_RESULT_CLUMP_SIZE);
		float		*outScoresArray = malloc(sizeof(float) * LOG_RESULT_CLUMP_SIZE);
		NSRange		resultRange = NSMakeRange(0, resultCount);
		
		//Read the results in 10 at a time
		while(resultRange.location < resultCount && (searchID == activeSearchID)){
			int		count;
			int		i;
			
			//Get the next 10 results
			count = SKSearchResultsGetInfoInRange(searchResults,
												  CFRangeMake(resultRange.location, LOG_RESULT_CLUMP_SIZE),
												  outDocumentsArray,
												  NULL,
												  outScoresArray);
			
			//Process the results
			for(i = 0; (i < count) && (searchID == activeSearchID); i++){
				NSString	*path = (NSString *)SKDocumentGetName(outDocumentsArray[i]);
				NSString	*toPath = [path stringByDeletingLastPathComponent];
				NSString	*fromPath = [toPath stringByDeletingLastPathComponent];
				
				AILog		*theLog = [[AILog alloc] initWithPath:path
														 from:[fromPath lastPathComponent]
														   to:[toPath lastPathComponent]
														 date:[AILog dateFromFileName:[path lastPathComponent]]];
				
				//Add the log
				[resultsLock lock];
				[selectedLogArray addObject:theLog];
				[resultsLock unlock];
				
				[theLog release];
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
}


//Search results table view --------------------------------------------------------------------------------------
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

//
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    NSString	*identifier = [tableColumn identifier];
    NSString	*value = nil;
    
    [resultsLock lock];
    if(row < 0 || row >= [selectedLogArray count]){
		value = @"";
    }else{
		AILog   *theLog = [selectedLogArray objectAtIndex:row];
		
		if([identifier compare:@"To"] == 0){
			value = [theLog to];
		}else if([identifier compare:@"From"] == 0){
			value = [theLog from];
		}else if([identifier compare:@"Date"] == 0){
			value = [dateFormatter stringForObjectValue:[theLog date]];
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

@end


//
//  AIAbstractLogViewerWindowController.m
//  Adium
//
//  Created by Evan Schoenberg on 3/24/06.
//

#import "AIAbstractLogViewerWindowController.h"
#import <Adium/AIListContact.h>
#import "AILoggerPlugin.h"
#import <Adium/AIHTMLDecoder.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AITextAttributes.h>
#import <AIUtilities/AIToolbarUtilities.h>
#import "AIContentController.h"
#import <Adium/KFTypeSelectTableView.h>

#import "AIAccountController.h"
#import "AILogToGroup.h"
#import "AILogFromGroup.h"
#import "AIChatLog.h"

#define MAX_LOGS_TO_SORT_WHILE_SEARCHING	3000	//Max number of logs we will live sort while searching

#define TOOLBAR_LOG_VIEWER				@"Log Viewer Toolbar"
#define KEY_LOG_VIEWER_SELECTED_COLUMN		@"Log Viewer Selected Column Identifier"

static AIAbstractLogViewerWindowController	*sharedLogViewerInstance = nil;

@interface AIAbstractLogViewerWindowController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName plugin:(id)inPlugin;
- (void)filterForContact:(AIListContact *)listContact;
- (void)buildSearchMenu;
- (void)sortSelectedLogArrayForTableColumn:(NSTableColumn *)tableColumn direction:(BOOL)direction;
- (NSAttributedString *)hilightOccurrencesOfString:(NSString *)littleString inString:(NSAttributedString *)bigString firstOccurrence:(NSRange *)outRange;
@end

@implementation AIAbstractLogViewerWindowController

+ (NSString *)nibName
{
	return nil;
}

+ (id)openForPlugin:(id)inPlugin
{
    if (!sharedLogViewerInstance) {
		sharedLogViewerInstance = [[self alloc] initWithWindowNibName:[self nibName] plugin:inPlugin];
	}
	
    [sharedLogViewerInstance showWindow:nil];
    
	return sharedLogViewerInstance;
}

//Open the log viewer window to a specific contact's logs
+ (id)openForContact:(AIListContact *)inContact plugin:(id)inPlugin
{
    [self openForPlugin:inPlugin];

	[sharedLogViewerInstance filterForContact:inContact];

    return sharedLogViewerInstance;
}

//init
- (id)initWithWindowNibName:(NSString *)windowNibName plugin:(id)inPlugin
{
	if ((self = [super initWithWindowNibName:windowNibName])) {
		//init
		plugin = inPlugin;
		selectedColumn = nil;
		activeSearchID = 0;
		searching = NO;
		automaticSearch = YES;
		activeSearchString = nil;
		displayedLog = nil;
		windowIsClosing = NO;
	
		blankImage = [[NSImage alloc] initWithSize:NSMakeSize(16,16)];
			
		dateFormatter = [[NSDateFormatter alloc] initWithDateFormat:[[NSUserDefaults standardUserDefaults] stringForKey:NSDateFormatString] allowNaturalLanguage:YES];

		sortDirection = YES;
		searchMode = LOG_SEARCH_TO;
		selectedLogArray = [[NSMutableArray alloc] init];
		fromArray = [[NSMutableArray alloc] init];
		fromServiceArray = [[NSMutableArray alloc] init];
		logFromGroupDict = [[NSMutableDictionary alloc] init];
		toArray = [[NSMutableArray alloc] init];
		toServiceArray = [[NSMutableArray alloc] init];
		logToGroupDict = [[NSMutableDictionary alloc] init];
		resultsLock = [[NSLock alloc] init];
		searchingLock = [[NSLock alloc] init];		
	}
	
	return self;
}

//Returns the window controller if one exists
+ (id)existingWindowController
{
    return sharedLogViewerInstance;
}

//Close the log viewer window
+ (void)closeSharedInstance
{
    if (sharedLogViewerInstance) {
        [sharedLogViewerInstance closeWindow:nil];
    }
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
    //[availableLogArray release];
    [selectedLogArray release];
    [selectedColumn release];
    [dateFormatter release];
    [displayedLog release];
    [blankImage release];

	[logFromGroupDict release]; logFromGroupDict = nil;
	[logToGroupDict release]; logToGroupDict = nil;

	[super dealloc];
}
	
- (void)windowDidLoad
{
	[self determineToAndFromGroupDicts];

	[[self window] setTitle:AILocalizedString(@"Log Viewer",nil)];
	
	//Toolbar
	[self installToolbar];
	
	//Localize tableView_results column headers
	[[[tableView_results tableColumnWithIdentifier:@"To"] headerCell] setStringValue:DESTINATION];
	[[[tableView_results tableColumnWithIdentifier:@"From"] headerCell] setStringValue:ACCOUNT];
	[[[tableView_results tableColumnWithIdentifier:@"Date"] headerCell] setStringValue:DATE];
	
	
    //Prepare the search controls
    [self buildSearchMenu];
    if ([textView_content respondsToSelector:@selector(setUsesFindPanel:)]) {
		[textView_content setUsesFindPanel:YES];
    }
	
    //Sort by preference, defaulting to sorting by date
	NSString	*selectedTableColumnPref;
	if ((selectedTableColumnPref = [[adium preferenceController] preferenceForKey:KEY_LOG_VIEWER_SELECTED_COLUMN
																			group:PREF_GROUP_LOGGING])) {
		selectedColumn = [[tableView_results tableColumnWithIdentifier:selectedTableColumnPref] retain];
	}
	if (!selectedColumn) {
		selectedColumn = [[tableView_results tableColumnWithIdentifier:@"Date"] retain];
	}
	[self sortSelectedLogArrayForTableColumn:selectedColumn direction:YES];
	
	//Begin our initial search
	[self setSearchMode:LOG_SEARCH_TO];
	
    [searchField_logs setStringValue:(activeSearchString ? activeSearchString : @"")];
    [self startSearchingClearingCurrentResults:YES];	
}

#pragma mark Refreshing results

- (NSMutableString *)progressString
{
	NSMutableString     *progress;
	
    //We always convey the number of logs being displayed
    [resultsLock lock];
    if (activeSearchString && [activeSearchString length]) {
		unsigned count = [selectedLogArray count];
		progress = [NSMutableString stringWithFormat:((count != 1) ? 
													  AILocalizedString(@"Found %i matches",nil) :
													  AILocalizedString(@"Found 1 match",nil)),count];
    } else if (searching) {
		progress = [[AILocalizedString(@"Opening logs",nil) stringByAppendingEllipsis] mutableCopy];
		
    } else {
		unsigned count = [selectedLogArray count];
		progress = [NSMutableString stringWithFormat:((count != 1) ?
													  AILocalizedString(@"%i logs",nil) :
													  AILocalizedString(@"1 log",nil)),count];
    }
    [resultsLock unlock];
	
	if (filterForAccountName && [filterForAccountName length]) {
		[progress appendString:[NSString stringWithFormat:AILocalizedString(@" of chats on %@",nil),filterForAccountName]];
	} else if (filterForContactName && [filterForContactName length]) {
		[progress appendString:[NSString stringWithFormat:AILocalizedString(@" of chats with %@",nil),filterForContactName]];
	}
	
    //Append search progress
    if (activeSearchString && [activeSearchString length]) {
		if (searching) {
			[progress appendString:[NSString stringWithFormat:AILocalizedString(@" - Searching for '%@'",nil),activeSearchString]];
		} else {
			[progress appendString:[NSString stringWithFormat:AILocalizedString(@" containing '%@'",nil),activeSearchString]];			
		}
	}
	
	return progress;
}

- (void)updateProgressDisplay
{
    [textField_progress setStringValue:[self progressString]];
}

//Refresh the results table
- (void)refreshResults
{
	[self refreshResultsSearchIsComplete:NO];
}

- (void)refreshResultsSearchIsComplete:(BOOL)searchIsComplete
{
    [resultsLock lock];
    int count = [selectedLogArray count];
    [resultsLock unlock];
	
    if (!searching || count <= MAX_LOGS_TO_SORT_WHILE_SEARCHING) {
		//Sort the logs correctly which will also reload the table
		[self resortLogs];
		
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
    }
	
    //Update status
    [self updateProgressDisplay];
}

- (void)searchComplete
{
	[refreshResultsTimer invalidate]; [refreshResultsTimer release]; refreshResultsTimer = nil;
	[self refreshResultsSearchIsComplete:YES];
}

#pragma mark Searching

//Begin the current search
- (void)startSearchingClearingCurrentResults:(BOOL)clearCurrentResults
{
    //Stop any existing searches
    [self stopSearching];
	
    //Once all searches have exited, we can start a new one
	if (clearCurrentResults) {
		[resultsLock lock];
		[selectedLogArray release]; selectedLogArray = [[NSMutableArray alloc] init];
		[resultsLock unlock];
	}
}

//Set the active search string (Does not invoke a search)
- (void)setSearchString:(NSString *)inString
{
    if (![[searchField_logs stringValue] isEqualToString:inString]) {
		[searchField_logs setStringValue:(inString ? inString : @"")];
    }

	//Use autorelease so activeSearchString can be passed back to here
	if (activeSearchString != inString) {
		[activeSearchString release];
		activeSearchString = [inString retain];
	}
}

//Change search string (Called by searchfield)
- (IBAction)updateSearch:(id)sender
{
    automaticSearch = NO;
    [self setSearchString:[[[searchField_logs stringValue] copy] autorelease]];
    [self startSearchingClearingCurrentResults:YES];
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
	//Get the NSTextFieldCell and use it only if it responds to setPlaceholderString: (10.3 and above)
	NSTextFieldCell	*cell = [searchField_logs cell];
	if (![cell respondsToSelector:@selector(setPlaceholderString:)]) cell = nil;
	
    searchMode = inMode;
	
	//Clear any filter from the table if it's the current mode, as well
	switch (searchMode) {
		case LOG_SEARCH_FROM:
			[cell setPlaceholderString:AILocalizedString(@"Search From","Placeholder for searching logs from an account")];
			break;

		case LOG_SEARCH_TO:
			[cell setPlaceholderString:AILocalizedString(@"Search To","Placeholder for searching logs with/to a contact")];
			break;
			
		case LOG_SEARCH_DATE:
			[cell setPlaceholderString:AILocalizedString(@"Search by Date","Placeholder for searching logs by date")];
			break;
			
		case LOG_SEARCH_CONTENT:
			[cell setPlaceholderString:AILocalizedString(@"Search Content","Placeholder for searching logs by content")];
			break;
	}
	
    [self buildSearchMenu];
}

/*
 * @brief Build the logToGroupDict and logFromGroupDicts dictionaries
 *
 * logFromGroupDict contains all AILogFromGroup objects, one for each source account keyed to the path to its logs relative to the logging base 
 * logToGroupDict contains all AILogToGroup objects (one for each source account->contact pair), keyed by the path to its logs relative to the log base
 */
- (void)determineToAndFromGroupDicts
{
    NSEnumerator			*enumerator;
    NSString				*folderName;
    NSMutableDictionary		*toDict = [NSMutableDictionary dictionary];
    NSString				*basePath = [AILoggerPlugin logBasePath];
    NSString				*fromUID, *serviceClass;
	
    //Process each account folder (/Logs/SERVICE.ACCOUNT_NAME/) - sorting by compare: will result in an ordered list
	//first by service, then by account name.
	enumerator = [[[[NSFileManager defaultManager] directoryContentsAtPath:basePath] sortedArrayUsingSelector:@selector(compare:)] objectEnumerator];
    while ((folderName = [enumerator nextObject])) {
		if (![folderName isEqualToString:@".DS_Store"]) { // avoid the directory info
			NSEnumerator    *toEnum;
			AILogToGroup    *currentToGroup;			
			AILogFromGroup  *logFromGroup;
			NSMutableSet	*toSetForThisService;
			NSArray         *serviceAndFromUIDArray;
			
			//Determine the service and fromUID - should be SERVICE.ACCOUNT_NAME
			//Check against count to guard in case of old, malformed or otherwise odd folders & whatnot sitting in log base
			serviceAndFromUIDArray = [folderName componentsSeparatedByString:@"."];
			
			if ([serviceAndFromUIDArray count] >= 2) {
				serviceClass = [serviceAndFromUIDArray objectAtIndex:0];
				
				//Use substringFromIndex so we include the rest of the string in the case of a UID with a . in it
				fromUID = [folderName substringFromIndex:([serviceClass length] + 1)]; //One off for the '.'
			} else {
				//Fallback: blank non-nil serviceClass; folderName as the fromUID
				serviceClass = @"";
				fromUID = folderName;
			}
			
			logFromGroup = [[AILogFromGroup alloc] initWithPath:folderName fromUID:fromUID serviceClass:serviceClass];
			
			//Store logFromGroup on a key in the form "SERVICE.ACCOUNT_NAME"
			[logFromGroupDict setObject:logFromGroup forKey:folderName];
			
			//Build an array of the account names for constant-order access
			[fromArray addObject:fromUID];
			[fromServiceArray addObject:serviceClass];
			
			//To processing
			if (!(toSetForThisService = [toDict objectForKey:serviceClass])) {
				toSetForThisService = [NSMutableSet set];
				[toDict setObject:toSetForThisService
						   forKey:serviceClass];
			}
			
			//Add the 'to' for each grouping on this account
			toEnum = [[logFromGroup toGroupArray] objectEnumerator];
			while ((currentToGroup = [toEnum nextObject])) {
				NSString	*currentTo = [currentToGroup to];
				[toSetForThisService addObject:currentTo];
				
				//Store currentToGroup on a key in the form "SERVICE.ACCOUNT_NAME/TARGET_CONTACT"
				[logToGroupDict setObject:currentToGroup forKey:[currentToGroup path]];
			}
			
			[logFromGroup release];
		}
	}
	
	//Build an array of the contact names for constant-order access
	enumerator = [toDict keyEnumerator];
	while ((serviceClass = [enumerator nextObject])) {
		NSSet		*toSetForThisService = [toDict objectForKey:serviceClass];
		unsigned	i;
		unsigned	count = [toSetForThisService count];
		
		[toArray addObjectsFromArray:[[toSetForThisService allObjects] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]];
		//Add service to the toServiceArray for each of these objects
		for (i=0 ; i < count ; i++) {
			[toServiceArray addObject:serviceClass];
		}
	}
}

#pragma mark Displaying a log
//Displays the contents of the specified log in our window
- (void)displayLog:(AIChatLog *)theLog
{
    NSAttributedString	*logText = nil;
    NSString		*logFileText = nil;
	
    if (displayedLog != theLog) {
		[displayedLog release];
		displayedLog = [theLog retain];
		
		if (theLog) {	    
			//Open the log
			logFileText = [NSString stringWithContentsOfFile:[[AILoggerPlugin logBasePath] stringByAppendingPathComponent:[theLog path]]];

			if (logFileText && [logFileText length]) {
				if ([[theLog path] hasSuffix:@".AdiumHTMLLog"] || [[theLog path] hasSuffix:@".html"] || [[theLog path] hasSuffix:@".html.bak"]) {
					logText = [[[NSAttributedString alloc] initWithAttributedString:[AIHTMLDecoder decodeHTML:logFileText]] autorelease];
				} else {
					AITextAttributes *textAttributes = [AITextAttributes textAttributesWithFontFamily:@"Helvetica" traits:0 size:12];
					logText = [[[NSAttributedString alloc] initWithString:logFileText attributes:[textAttributes dictionary]] autorelease];
				}
				
				if (logText && [logText length]) {
					logText = [[adium contentController] filterAttributedString:logText
																usingFilterType:AIFilterMessageDisplay
																	  direction:AIFilterOutgoing
																		context:nil];
					NSRange     scrollRange = NSMakeRange([logText length],0);
					
					//If we are searching by content, highlight the search results
					if (searchMode == LOG_SEARCH_CONTENT) {
						NSEnumerator    *enumerator;
						NSString	*searchWord;
						
						enumerator = [[activeSearchString componentsSeparatedByString:@" "] objectEnumerator];
						while ((searchWord = [enumerator nextObject])) {
							NSRange     occurrence;
							
							logText = [self hilightOccurrencesOfString:searchWord inString:logText firstOccurrence:&occurrence];
							if (occurrence.location < scrollRange.location) {
								scrollRange = occurrence;
							}
						}
					}
					
					//Set this string and scroll to the top/bottom/occurrence
					[[textView_content textStorage] setAttributedString:logText];
					if ((searchMode == LOG_SEARCH_CONTENT) || automaticSearch) {
						[textView_content scrollRangeToVisible:scrollRange];
					} else {
						[textView_content scrollRangeToVisible:NSMakeRange(0,0)];
					}		
				}
			}
		}
		
		//No log selected, empty the view
		if (!logFileText) {
			[textView_content setString:@""];
		}
    }
}

#pragma mark Selected log

//Reselect the displayed log (Or another log if not possible)
- (void)selectDisplayedLog
{
    int     index = NSNotFound;
    
    //Is the log we had selected still in the table?
    //(When performing an automatic search, we ignore the previous selection.  This ensures that we always
    // end up with the newest log selected, even when a search takes multiple passes/refreshes to complete).
    if (!automaticSearch) {
		[resultsLock lock];
		index = [selectedLogArray indexOfObject:displayedLog];
		[resultsLock unlock];
    }
	
    if (index != NSNotFound) {
		//If our selected log is still around, re-select it
		[tableView_results selectRow:index byExtendingSelection:NO];
		[tableView_results scrollRowToVisible:index];
		
    } else {
        if (useSame == YES && sameSelection > 0) {
            [tableView_results selectRow:sameSelection byExtendingSelection:NO];
        } else {   
            [self selectFirstLog];
        }
    }    
    useSame = NO;
}

- (void)selectFirstLog
{
	AIChatLog   *theLog = nil;
	
	//If our selected log is no more, select the first one in the list
	[resultsLock lock];
	if ([selectedLogArray count] != 0) {
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
    while (location != NSNotFound && location < [plainBigString length]) {
        searchRange = NSMakeRange(location, [plainBigString length]-location);
        foundRange = [plainBigString rangeOfString:littleString options:NSCaseInsensitiveSearch range:searchRange];
		
		//Bold and color this match
        if (foundRange.location != NSNotFound) {
			if (outRange->location == NSNotFound) *outRange = foundRange;
			
            [outString addAttribute:NSFontAttributeName value:boldFont range:foundRange];
            [outString addAttribute:NSBackgroundColorAttributeName value:[NSColor yellowColor] range:foundRange];
        }
		
        location = NSMaxRange(foundRange);
    }
    
    return [outString autorelease];
}


//Sorting --------------------------------------------------------------------------------------------------------------
#pragma mark Sorting
- (void)resortLogs
{
	NSString *identifier = [selectedColumn identifier];
	
    //Resort the data
	[resultsLock lock];
    if ([identifier isEqualToString:@"To"]) {
		[selectedLogArray sortUsingSelector:(sortDirection ? @selector(compareToReverse:) : @selector(compareTo:))];
		
    } else if ([identifier isEqualToString:@"From"]) {
        [selectedLogArray sortUsingSelector:(sortDirection ? @selector(compareFromReverse:) : @selector(compareFrom:))];
		
    } else if ([identifier isEqualToString:@"Date"]) {
        [selectedLogArray sortUsingSelector:(sortDirection ? @selector(compareDateReverse:) : @selector(compareDate:))];
		
    } else if ([identifier isEqualToString:@"Rank"]) {
	    [selectedLogArray sortUsingSelector:(sortDirection ? @selector(compareRankReverse:) : @selector(compareRank:))];
	}
	
    [resultsLock unlock];
	
    //Reload the data
    [tableView_results reloadData];
	
    //Reapply the selection
    [self selectDisplayedLog];	
}

//Sorts the selected log array and adjusts the selected column
- (void)sortSelectedLogArrayForTableColumn:(NSTableColumn *)tableColumn direction:(BOOL)direction
{
    //If there already was a sorted column, remove the indicator image from it.
    if (selectedColumn && selectedColumn != tableColumn) {
        [tableView_results setIndicatorImage:nil inTableColumn:selectedColumn];
    }
    
    //Set the indicator image in the newly selected column
    [tableView_results setIndicatorImage:[NSImage imageNamed:(direction ? @"NSDescendingSortIndicator" : @"NSAscendingSortIndicator")]
                           inTableColumn:tableColumn];
    
    //Set the highlighted table column.
    [tableView_results setHighlightedTableColumn:tableColumn];
    [selectedColumn release]; selectedColumn = [tableColumn retain];
    sortDirection = direction;
	
	[self resortLogs];
}

- (void)filterForContact:(AIListContact *)listContact
{
	
}

//Search results table view --------------------------------------------------------------------------------------------
#pragma mark Search results table view
//Since this table view's source data will be accessed from within other threads, we need to lock before
//accessing it.  We also must be very sure that an incorrect row request is handled silently, since this
//can occur if the array size is changed during the reload.
- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	if (tableView == tableView_results) {
		int count;
		
		[resultsLock lock];
		count = [selectedLogArray count];
		[resultsLock unlock];
		
		return count;
	} else {
		return 0;
	}
}

//
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	if (tableView == tableView_results) {
		NSString	*identifier = [tableColumn identifier];
		id          value = nil;
		
		[resultsLock lock];
		if (row < 0 || row >= [selectedLogArray count]) {
			if ([identifier isEqualToString:@"Service"]) {
				value = blankImage;
			} else {
				value = @"";
			}
			
		} else {
			AIChatLog       *theLog = [selectedLogArray objectAtIndex:row];
			
			if ([identifier isEqualToString:@"To"]) {
				value = [theLog to]; 
				
			} else if ([identifier isEqualToString:@"From"]) {
				value = [theLog from];
				
			} else if ([identifier isEqualToString:@"Date"]) {
				value = [dateFormatter stringForObjectValue:[theLog date]];
				
			} else if ([identifier isEqualToString:@"Service"]) {
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
		
		return value;
	} else {
		return nil;
	}
}

//
- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
	if ([notification object] == tableView_results) {
		if (!ignoreSelectionChange) {
			AIChatLog   *theLog = nil;
			int     row = [tableView_results selectedRow];
			
			//Update the displayed log
			automaticSearch = NO;
			
			[resultsLock lock];
			if (row >= 0 && row < [selectedLogArray count]) {
				theLog = [selectedLogArray objectAtIndex:row];
			}
			[resultsLock unlock];
			
			[self displayLog:theLog];
		}
	}
}

//Sort the log array & reflect the new column
- (void)tableView:(NSTableView*)tableView didClickTableColumn:(NSTableColumn *)tableColumn
{
	if (tableView == tableView_results) {
		[self sortSelectedLogArrayForTableColumn:tableColumn
									   direction:(selectedColumn == tableColumn ? !sortDirection : sortDirection)];
	}
}

//Delete selected logs
- (IBAction)deleteSelectedLog:(id)sender
{
	NSLog(@"deleteSelectedLog: Should be implemented by AIAbstractLogViewerWindowController subclass");
}

- (void)tableViewDeleteSelectedRows:(NSTableView *)tableView
{
	if (tableView == tableView_results) {
		[self deleteSelectedLog:nil];
	}
}

- (void)configureTypeSelectTableView:(KFTypeSelectTableView *)tableView
{
	if (tableView == tableView_results) {
		[tableView setSearchColumnIdentifiers:[NSSet setWithObjects:@"To", @"From", nil]];
	}
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
	
	//Delete Logs
	[AIToolbarUtilities addToolbarItemToDictionary:toolbarItems
									withIdentifier:@"delete"
											 label:DELETE
									  paletteLabel:DELETE
										   toolTip:AILocalizedString(@"Delete selected log",nil)
											target:self
								   settingSelector:@selector(setImage:)
									   itemContent:[NSImage imageNamed:@"remove" forClass:[self class]]
											action:@selector(deleteSelectedLog:)
											  menu:nil];
	
	//Delete All Logs
	[AIToolbarUtilities addToolbarItemToDictionary:toolbarItems
									withIdentifier:@"deleteall"
											 label:DELETEALL
									  paletteLabel:DELETEALL
										   toolTip:AILocalizedString(@"Delete all logs",nil)
											target:self
								   settingSelector:@selector(setImage:)
									   itemContent:[NSImage imageNamed:@"remove" forClass:[self class]]
											action:@selector(deleteAllLogs:)
											  menu:nil];
	
	//Search
	[self window]; //Ensure the window is loaded, since we're pulling the search view from our nib
	toolbarItem = [AIToolbarUtilities toolbarItemWithIdentifier:@"search"
														  label:SEARCH
												   paletteLabel:SEARCH
														toolTip:AILocalizedString(@"Search or filter logs",nil)
														 target:self
												settingSelector:@selector(setView:)
													itemContent:view_SearchField
														 action:@selector(updateSearch:)
														   menu:nil];
	
	[toolbarItem setMinSize:NSMakeSize(150, NSHeight([view_SearchField frame]))];
	[toolbarItem setMaxSize:NSMakeSize(230, NSHeight([view_SearchField frame]))];
	[toolbarItems setObject:toolbarItem forKey:[toolbarItem itemIdentifier]];

	[[self window] setToolbar:toolbar];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    return [AIToolbarUtilities toolbarItemFromDictionary:toolbarItems withIdentifier:itemIdentifier];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
	return nil;
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
    return [[toolbarItems allKeys] arrayByAddingObjectsFromArray:
		[NSArray arrayWithObjects:NSToolbarSeparatorItemIdentifier,
			NSToolbarSpaceItemIdentifier,
			NSToolbarFlexibleSpaceItemIdentifier,
			NSToolbarCustomizeToolbarItemIdentifier, nil]];
}

//Called as the window closes
- (void)windowWillClose:(id)sender
{
	[super windowWillClose:sender];

	//Set preference for selected column
	[[adium preferenceController] setPreference:[selectedColumn identifier]
										 forKey:KEY_LOG_VIEWER_SELECTED_COLUMN
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
	
	[sharedLogViewerInstance autorelease]; sharedLogViewerInstance = nil;
	[toolbarItems autorelease];
}

//Change search mode (Called by mode menu)
- (IBAction)selectSearchType:(id)sender
{
    automaticSearch = NO;
	
	//First, update the search mode to the newly selected type
    [self setSearchMode:[sender tag]]; 
	
	//Then, ensure we are ready to search using the current string
	[self setSearchString:activeSearchString];
	
	//Now we are ready to start searching
    [self startSearchingClearingCurrentResults:YES];
}

//Begin a specific search
- (void)setSearchString:(NSString *)inString mode:(LogSearchMode)inMode
{
    automaticSearch = YES;
	//Apply the search mode first since the behavior of setSearchString changes depending on the current mode
    [self setSearchMode:inMode];
    [self setSearchString:inString];
	
    [self startSearchingClearingCurrentResults:YES];
}

//Returns a menu item for the search mode menu
- (NSMenuItem *)_menuItemWithTitle:(NSString *)title forSearchMode:(LogSearchMode)mode
{
    NSMenuItem  *menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:title 
																				 action:@selector(selectSearchType:) 
																		  keyEquivalent:@""];
    [menuItem setTag:mode];
    [menuItem setState:(mode == searchMode ? NSOnState : NSOffState)];
    
    return [menuItem autorelease];
}

//Build the search mode menu
- (void)buildSearchMenu
{
    NSMenu  *cellMenu = [[[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:SEARCH_MENU] autorelease];
    [cellMenu addItem:[self _menuItemWithTitle:ACCOUNT forSearchMode:LOG_SEARCH_FROM]];
    [cellMenu addItem:[self _menuItemWithTitle:DESTINATION forSearchMode:LOG_SEARCH_TO]];
    [cellMenu addItem:[self _menuItemWithTitle:DATE forSearchMode:LOG_SEARCH_DATE]];
    [cellMenu addItem:[self _menuItemWithTitle:CONTENT forSearchMode:LOG_SEARCH_CONTENT]];
	
	[[searchField_logs cell] setSearchMenuTemplate:cellMenu];
}

@end

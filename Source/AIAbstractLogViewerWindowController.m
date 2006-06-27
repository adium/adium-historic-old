//
//  AIAbstractLogViewerWindowController.m
//  Adium
//
//  Created by Evan Schoenberg on 3/24/06.
//

#import "AIAccountController.h"
#import "AIChatLog.h"
#import "AIContactController.h"
#import "AIContentController.h"
#import "AILogFromGroup.h"
#import "AILogToGroup.h"
#import "AILogViewerWindowController.h"
#import "AILoggerPlugin.h"
#import "AIPreferenceController.h"
#import "ESRankingCell.h" 
#import <AIUtilities/AIArrayAdditions.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIDateFormatterAdditions.h>
#import <AIUtilities/AIFileManagerAdditions.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIImageTextCell.h>
#import <AIUtilities/AIOutlineViewAdditions.h>
#import <AIUtilities/AISplitView.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AITableViewAdditions.h>
#import <AIUtilities/AITextAttributes.h>
#import <AIUtilities/AIToolbarUtilities.h>
#import <Adium/AIHTMLDecoder.h>
#import <Adium/AIListContact.h>
#import <Adium/AIMetaContact.h>
#import <Adium/AIServiceIcons.h>
#import <Adium/AIUserIcons.h>

#import "KFTypeSelectTableView.h"
#import "KNShelfSplitView.h"

#define KEY_LOG_VIEWER_WINDOW_FRAME		@"Log Viewer Frame"
#define	PREF_GROUP_CONTACT_LIST			@"Contact List"
#define KEY_LOG_VIEWER_GROUP_STATE		@"Log Viewer Group State"	//Expand/Collapse state of groups
#define TOOLBAR_LOG_VIEWER				@"Log Viewer Toolbar"

#define MAX_LOGS_TO_SORT_WHILE_SEARCHING	3000	//Max number of logs we will live sort while searching
#define LOG_SEARCH_STATUS_INTERVAL			20	//1/60ths of a second to wait before refreshing search status

#define SEARCH_MENU						AILocalizedString(@"Search Menu",nil)
#define FROM							AILocalizedString(@"From",nil)
#define TO								AILocalizedString(@"To",nil)
#define DATE							AILocalizedString(@"Date",nil)
#define CONTENT							AILocalizedString(@"Content",nil)
#define DELETE							AILocalizedString(@"Delete",nil)
#define DELETEALL						AILocalizedString(@"Delete All",nil)
#define SEARCH							AILocalizedString(@"Search",nil)

#define HIDE_EMOTICONS					AILocalizedString(@"Hide Emoticons",nil)
#define SHOW_EMOTICONS					AILocalizedString(@"Show Emoticons",nil)

#define IMAGE_EMOTICONS_OFF				@"emoticon32"
#define IMAGE_EMOTICONS_ON				@"emoticon32_transparent"

#define	REFRESH_RESULTS_INTERVAL		0.5 //Interval between results refreshes while searching

#define ALL_CONTACTS_IDENTIFIER			[NSNumber numberWithInt:-1]

@interface AIAbstractLogViewerWindowController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName plugin:(id)inPlugin;
- (void)initLogFiltering;
- (void)displayLog:(AIChatLog *)log;
- (void)hilightOccurrencesOfString:(NSString *)littleString inString:(NSMutableAttributedString *)bigString firstOccurrence:(NSRange *)outRange;
- (void)sortCurrentSearchResultsForTableColumn:(NSTableColumn *)tableColumn direction:(BOOL)direction;
- (void)startSearchingClearingCurrentResults:(BOOL)clearCurrentResults;
- (void)buildSearchMenu;
- (NSMenuItem *)_menuItemWithTitle:(NSString *)title forSearchMode:(LogSearchMode)mode;
- (void)_logContentFilter:(NSString *)searchString searchID:(int)searchID onSearchIndex:(SKIndexRef)logSearchIndex;
- (void)_logFilter:(NSString *)searchString searchID:(int)searchID mode:(LogSearchMode)mode;
- (void)installToolbar;
- (void)updateRankColumnVisibility;
- (void)openLogAtPath:(NSString *)inPath;
- (void)rebuildContactsList;
- (void)filterForContact:(AIListContact *)inContact;
@end

@implementation AIAbstractLogViewerWindowController

static AIAbstractLogViewerWindowController	*sharedLogViewerInstance = nil;
static int toArraySort(id itemA, id itemB, void *context);

+ (NSString *)nibName
{
	return @"LogViewer";	
}

+ (id)openForPlugin:(id)inPlugin
{
    if (!sharedLogViewerInstance) {
		sharedLogViewerInstance = [[self alloc] initWithWindowNibName:[self nibName] plugin:inPlugin];
	}

    [sharedLogViewerInstance showWindow:nil];
    
	return sharedLogViewerInstance;
}

+ (id)openLogAtPath:(NSString *)inPath plugin:(id)inPlugin
{
	[self openForPlugin:inPlugin];
	
	[sharedLogViewerInstance openLogAtPath:inPath];
	
	return sharedLogViewerInstance;
}

//Open the log viewer window to a specific contact's logs
+ (id)openForContact:(AIListContact *)inContact plugin:(id)inPlugin
{
    [self openForPlugin:inPlugin];

	[sharedLogViewerInstance filterForContact:inContact];
	
    return sharedLogViewerInstance;
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
    displayedLogArray = nil;
    aggregateLogIndexProgressTimer = nil;
    windowIsClosing = NO;
	desiredContactsSourceListDeltaX = 0;

    blankImage = [[NSImage alloc] initWithSize:NSMakeSize(16,16)];

    sortDirection = YES;
    searchMode = LOG_SEARCH_CONTENT;
    dateFormatter = [[NSDateFormatter alloc] initWithDateFormat:[[NSUserDefaults standardUserDefaults] stringForKey:NSDateFormatString] allowNaturalLanguage:YES];
    currentSearchResults = [[NSMutableArray alloc] init];
    fromArray = [[NSMutableArray alloc] init];
    fromServiceArray = [[NSMutableArray alloc] init];
    logFromGroupDict = [[NSMutableDictionary alloc] init];
    toArray = [[NSMutableArray alloc] init];
    toServiceArray = [[NSMutableArray alloc] init];
    logToGroupDict = [[NSMutableDictionary alloc] init];
    resultsLock = [[NSRecursiveLock alloc] init];
    searchingLock = [[NSLock alloc] init];
	contactIDsToFilter = [[NSMutableSet alloc] initWithCapacity:1];

    [super initWithWindowNibName:windowNibName];
	
    return self;
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
    [currentSearchResults release];
    [selectedColumn release];
    [dateFormatter release];
    [displayedLogArray release];
    [blankImage release];
    [activeSearchString release];
	[contactIDsToFilter release];
    
	[logFromGroupDict release]; logFromGroupDict = nil;
	[logToGroupDict release]; logToGroupDict = nil;

    [filterForAccountName release]; filterForAccountName = nil;

	[horizontalRule release]; horizontalRule = nil;

	[adiumIcon release]; adiumIcon = nil;
	[adiumIconHighlighted release]; adiumIconHighlighted = nil;
	
	//We loaded	view_DatePicker from a nib manually, so we must release it
	[view_DatePicker release]; view_DatePicker = nil;

    [super dealloc];
}

//Init our log filtering tree
- (void)initLogFiltering
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
			
			/* Determine the service and fromUID - should be SERVICE.ACCOUNT_NAME
			 * Check against count to guard in case of old, malformed or otherwise odd folders & whatnot sitting in log base
			 */
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

			//To processing
			if (!(toSetForThisService = [toDict objectForKey:serviceClass])) {
				toSetForThisService = [NSMutableSet set];
				[toDict setObject:toSetForThisService
						   forKey:serviceClass];
			}

			//Add the 'to' for each grouping on this account
			toEnum = [[logFromGroup toGroupArray] objectEnumerator];
			while ((currentToGroup = [toEnum nextObject])) {
				NSString	*currentTo;

				if ((currentTo = [currentToGroup to])) {
					//Store currentToGroup on a key in the form "SERVICE.ACCOUNT_NAME/TARGET_CONTACT"
					[logToGroupDict setObject:currentToGroup forKey:[currentToGroup path]];
				}
			}

			[logFromGroup release];
		}
	}

	[self rebuildContactsList];
}

- (void)rebuildContactsList
{
	NSEnumerator	*enumerator = [logFromGroupDict objectEnumerator];
	AILogFromGroup	*logFromGroup;
	
	int	oldCount = [toArray count];
	[toArray release]; toArray = [[NSMutableArray alloc] initWithCapacity:(oldCount ? oldCount : 20)];

	while ((logFromGroup = [enumerator nextObject])) {
		NSEnumerator	*toEnum;
		AILogToGroup	*currentToGroup;
		NSString		*serviceClass = [logFromGroup serviceClass];

		//Add the 'to' for each grouping on this account
		toEnum = [[logFromGroup toGroupArray] objectEnumerator];
		while ((currentToGroup = [toEnum nextObject])) {
			NSString	*currentTo;
			
			if ((currentTo = [currentToGroup to])) {
				AIListObject *listObject = ((serviceClass && currentTo) ?
											[[adium contactController] existingListObjectWithUniqueID:[AIListObject internalObjectIDForServiceID:serviceClass
																																			 UID:currentTo]] :
											nil);
				if (listObject && [listObject isKindOfClass:[AIListContact class]]) {
					AIListContact *parentContact = [(AIListContact *)listObject parentContact];
					if (![toArray containsObjectIdenticalTo:parentContact]) {
						[toArray addObject:parentContact];
					}
					
				} else {
					if (![toArray containsObject:currentToGroup]) {
						[toArray addObject:currentToGroup];
					}
				}
			}
		}		
	}
	
	[toArray sortUsingFunction:toArraySort context:NULL];
	[outlineView_contacts reloadData];	
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

	[[self window] setTitle:AILocalizedString(@"Chat Transcripts Viewer",nil)];
    [textField_progress setStringValue:@""];

	//Autosave doesn't do anything yet
	[shelf_splitView setAutosaveName:@"LogViewer:Shelf"];
	[shelf_splitView setFrame:[[[self window] contentView] frame]];

	// Pull our main article/display split view out of the nib and position it in the shelf view
	[containingView_results retain];
	[containingView_results removeFromSuperview];
	[shelf_splitView setContentView:containingView_results];
	[containingView_results release];
	
	// Pull our source view out of the nib and position it in the shelf view
	[containingView_contactsSourceList retain];
	[containingView_contactsSourceList removeFromSuperview];
	[shelf_splitView setShelfView:containingView_contactsSourceList];
	[containingView_contactsSourceList release];

    //Set emoticon filtering
    showEmoticons = [[[adium preferenceController] preferenceForKey:KEY_LOG_VIEWER_EMOTICONS
                                                              group:PREF_GROUP_LOGGING] boolValue];
    [[toolbarItems objectForKey:@"toggleemoticons"] setLabel:(showEmoticons ? HIDE_EMOTICONS : SHOW_EMOTICONS)];
    [[toolbarItems objectForKey:@"toggleemoticons"] setImage:[NSImage imageNamed:(showEmoticons ? IMAGE_EMOTICONS_ON : IMAGE_EMOTICONS_OFF) forClass:[self class]]];

	//Toolbar
	[self installToolbar];	

	/* XXX This color isn't quite right for a Mail.app-style source list background... it's not the same as what Color Picker reports for it
	 * because _that_ isn't right, either, strangely.
	 * hue: 215 degrees
	 * Saturation 0.07
	 * Brightness 0.97
	 */
	[outlineView_contacts setBackgroundColor:[NSColor colorWithCalibratedHue:(215.0/359.0)
																  saturation:0.07
																  brightness:0.98
																	   alpha:1.0]];

	AIImageTextCell	*dataCell = [[AIImageTextCell alloc] init];
	[[[outlineView_contacts tableColumns] objectAtIndex:0] setDataCell:dataCell];
	[dataCell setControlView:outlineView_contacts];
	[dataCell release];

	[outlineView_contacts setDrawsGradientSelection:YES];
	[outlineView_contacts setFocusRingType:NSFocusRingTypeNone];

	//Localize tableView_results column headers
	[[[tableView_results tableColumnWithIdentifier:@"To"] headerCell] setStringValue:TO];
	[[[tableView_results tableColumnWithIdentifier:@"From"] headerCell] setStringValue:FROM];
	[[[tableView_results tableColumnWithIdentifier:@"Date"] headerCell] setStringValue:DATE];
	[tableView_results setFocusRingType:NSFocusRingTypeNone];

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
	[self sortCurrentSearchResultsForTableColumn:selectedColumn direction:YES];

    //Prepare indexing and filter searching
	[plugin prepareLogContentSearching];
    [self initLogFiltering];

    //Begin our initial search
	[self setSearchMode:LOG_SEARCH_TO];

    [searchField_logs setStringValue:(activeSearchString ? activeSearchString : @"")];
    [self startSearchingClearingCurrentResults:YES];
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
    
    [self initLogFiltering];
    
    [tableView_results reloadData];
    [self selectDisplayedLog];
}

//Called as the window closes
- (void)windowWillClose:(id)sender
{
	[super windowWillClose:sender];

	//Set preference for emoticon filtering
	[[adium preferenceController] setPreference:[NSNumber numberWithBool:showEmoticons]
										 forKey:KEY_LOG_VIEWER_EMOTICONS
										  group:PREF_GROUP_LOGGING];
	
	//Set preference for selected column
	[[adium preferenceController] setPreference:[selectedColumn identifier]
										 forKey:KEY_LOG_VIEWER_SELECTED_COLUMN
										  group:PREF_GROUP_LOGGING];

    /* Disable the search field.  If we don't disable the search field, it will often try to call its target action
     * after the window has closed (and we are gone).  I'm not sure why this happens, but disabling the field
     * before we close the window down seems to prevent the crash.
	 */
    [searchField_logs setEnabled:NO];
	
	/* Note that the window is closing so we don't take behaviors which could cause messages to the window after
	 * it was gone, like responding to a logIndexUpdated message
	 */
	windowIsClosing = YES;

    //Abort any in-progress searching and indexing, and wait for their completion
    [self stopSearching];
    [plugin cleanUpLogContentSearching];

    //Clean up
	[aggregateLogIndexProgressTimer invalidate];
	[aggregateLogIndexProgressTimer release]; aggregateLogIndexProgressTimer = nil;
	
	//Reset our column widths if needed
	[activeSearchString release]; activeSearchString = nil;
	[self updateRankColumnVisibility];
	
	[sharedLogViewerInstance autorelease]; sharedLogViewerInstance = nil;
	[toolbarItems autorelease]; toolbarItems = nil;
}

//Display --------------------------------------------------------------------------------------------------------------
#pragma mark Display
//Update log viewer progress string to reflect current status
- (void)updateProgressDisplay
{
    NSMutableString     *progress = nil;
    int					indexNumber, indexTotal;
    BOOL				indexing;

    //We always convey the number of logs being displayed
    [resultsLock lock];
	unsigned count = [currentSearchResults count];
    if (activeSearchString && [activeSearchString length]) {
		[shelf_splitView setResizeThumbStringValue:[NSString stringWithFormat:((count != 1) ? 
																			   AILocalizedString(@"%i matching logs",nil) :
																			   AILocalizedString(@"1 matching log",nil)),count]];
    } else {
		[shelf_splitView setResizeThumbStringValue:[NSString stringWithFormat:((count != 1) ? 
																			   AILocalizedString(@"%i logs",nil) :
																			   AILocalizedString(@"1 log",nil)),count]];
		
		//We are searching, but there is no active search  string. This indicates we're still opening logs.
		if (searching) {
			progress = [[AILocalizedString(@"Opening logs",nil) mutableCopy] autorelease];			
		}
    }
    [resultsLock unlock];

    //Append search progress
    if (activeSearchString && [activeSearchString length]) {
		if (progress) {
			[progress appendString:@" - "];
		} else {
			progress = [NSMutableString string];
		}

		if (searching) {
			[progress appendString:[NSString stringWithFormat:AILocalizedString(@"Searching for '%@'",nil),activeSearchString]];
		} else {
			[progress appendString:[NSString stringWithFormat:AILocalizedString(@"Search for '%@' complete.",nil),activeSearchString]];			
		}
	}

    //Append indexing progress
    if ((indexing = [plugin getIndexingProgress:&indexNumber outOf:&indexTotal])) {
		if (progress) {
			[progress appendString:@" - "];
		} else {
			progress = [NSMutableString string];
		}
		
		[progress appendString:[NSString stringWithFormat:AILocalizedString(@"Indexing %i of %i",nil), indexNumber, indexTotal]];
    }
	
	if (progress && (searching || indexing || !(activeSearchString && [activeSearchString length]))) {
		[progress appendString:[NSString ellipsis]];	
	}

    //Enable/disable the searching animation
    if (searching || indexing) {
		[progressIndicator startAnimation:nil];
    } else {
		[progressIndicator stopAnimation:nil];
    }
    
    [textField_progress setStringValue:(progress ? progress : @"")];
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

//Refresh the results table
- (void)refreshResults
{
	[self updateProgressDisplay];

	[self refreshResultsSearchIsComplete:NO];
}

- (void)refreshResultsSearchIsComplete:(BOOL)searchIsComplete
{
    [resultsLock lock];
    int count = [currentSearchResults count];
    [resultsLock unlock];
	
    if (!searching || count <= MAX_LOGS_TO_SORT_WHILE_SEARCHING) {
		//Sort the logs correctly which will also reload the table
		[self resortLogs];
		
		if (searchIsComplete && automaticSearch) {
			//If search is complete, select the first log if requested and possible
			[self selectFirstLog];
			
		} else {
			BOOL oldAutomaticSearch = automaticSearch;

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
- (void)displayLogs:(NSArray *)logArray;
{	
    NSMutableAttributedString	*displayText = nil;
	NSAttributedString			*finalDisplayText = nil;
	NSRange						scrollRange = NSMakeRange(0,0);
	BOOL						appendedFirstLog = NO;

    if (![logArray isEqualToArray:displayedLogArray]) {
		[displayedLogArray release];
		displayedLogArray = [logArray copy];
	}

	if ([logArray count] > 1) {
		displayText = [[NSMutableAttributedString alloc] init];
	}

	NSEnumerator *enumerator = [logArray objectEnumerator];
	AIChatLog	 *theLog;
	NSString	 *logBasePath = [AILoggerPlugin logBasePath];
	
	while ((theLog = [enumerator nextObject])) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		//Open the log
		NSString *logFileText = [NSString stringWithContentsOfFile:[logBasePath stringByAppendingPathComponent:[theLog path]]];
		
		if (logFileText && [logFileText length]) {
			if (displayText) {
				if (!horizontalRule) {
					#define HORIZONTAL_BAR			0x2013
					#define HORIZONTAL_RULE_LENGTH	18

					const unichar separatorUTF16[HORIZONTAL_RULE_LENGTH] = {
						HORIZONTAL_BAR, HORIZONTAL_BAR, HORIZONTAL_BAR, HORIZONTAL_BAR, HORIZONTAL_BAR, HORIZONTAL_BAR,
						HORIZONTAL_BAR, HORIZONTAL_BAR, HORIZONTAL_BAR, HORIZONTAL_BAR, HORIZONTAL_BAR, HORIZONTAL_BAR,
						HORIZONTAL_BAR, HORIZONTAL_BAR, HORIZONTAL_BAR, HORIZONTAL_BAR, HORIZONTAL_BAR, HORIZONTAL_BAR
					};
					horizontalRule = [[NSString alloc] initWithCharacters:separatorUTF16 length:HORIZONTAL_RULE_LENGTH];
				}	
				
				[displayText appendString:[NSString stringWithFormat:@"%@%@\n%@ - %@\n%@\n\n",
					(appendedFirstLog ? @"\n" : @""),
					horizontalRule,
					[dateFormatter stringFromDate:[theLog date]],
					[theLog to],
					horizontalRule]
						   withAttributes:[[AITextAttributes textAttributesWithFontFamily:@"Helvetica" traits:NSBoldFontMask size:12] dictionary]];
			}

			if ([[theLog path] hasSuffix:@".AdiumHTMLLog"] || [[theLog path] hasSuffix:@".html"] || [[theLog path] hasSuffix:@".html.bak"]) {
				if (displayText) {
					[displayText appendAttributedString:[AIHTMLDecoder decodeHTML:logFileText]];
				} else {
					displayText = [[AIHTMLDecoder decodeHTML:logFileText] mutableCopy];
				}

			} else {
				AITextAttributes *textAttributes = [AITextAttributes textAttributesWithFontFamily:@"Helvetica" traits:0 size:12];
				
				if (displayText) {
					[displayText appendAttributedString:[[[NSAttributedString alloc] initWithString:logFileText 
																						 attributes:[textAttributes dictionary]] autorelease]];
				} else {
					displayText = [[NSMutableAttributedString alloc] initWithString:logFileText attributes:[textAttributes dictionary]];
				}
				
			}
		}
		
		appendedFirstLog = YES;
		
		[pool release];
	}
	
	if (displayText && [displayText length]) {
		//Add pretty formatting to links
		[displayText addFormattingForLinks];

		//If we are searching by content, highlight the search results
		if ((searchMode == LOG_SEARCH_CONTENT) && [activeSearchString length]) {
			NSEnumerator				*enumerator;
			NSString					*searchWord;
			NSMutableArray				*searchWordsArray = [[activeSearchString componentsSeparatedByString:@" "] mutableCopy];
			NSScanner					*scanner = [NSScanner scannerWithString:activeSearchString];
			
			//Look for an initial quote
			while (![scanner isAtEnd]) {
				NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
				
				[scanner scanUpToString:@"\"" intoString:NULL];
				
				//Scan past the quote
				if (![scanner scanString:@"\"" intoString:NULL]) continue;
				
				NSString *quotedString;
				//And a closing one
				if (![scanner isAtEnd] &&
					[scanner scanUpToString:@"\"" intoString:&quotedString]) {
					//Scan past the quote
					[scanner scanString:@"\"" intoString:NULL];
					/* If a string within quotes is found, remove the words from the quoted string and add the full string
					 * to what we'll be highlighting.
					 *
					 * We'll use indexOfObject: and removeObjectAtIndex: so we only remove _one_ instance. Otherwise, this string:
					 * "killer attack ninja kittens" OR ninja
					 * wouldn't highlight the word ninja by itself.
					 */
					NSArray *quotedWords = [quotedString componentsSeparatedByString:@" "];
					int quotedWordsCount = [quotedWords count];
					
					for (int i = 0; i < quotedWordsCount; i++) {
						NSString	*quotedWord = [quotedWords objectAtIndex:i];
						if (i == 0) {
							//Originally started with a quote, so put it back on
							quotedWord = [@"\"" stringByAppendingString:quotedWord];
						}
						if (i == quotedWordsCount - 1) {
							//Originally ended with a quote, so put it back on
							quotedWord = [quotedWord stringByAppendingString:@"\""];
						}
						int searchWordsIndex = [searchWordsArray indexOfObject:quotedWord];
						if (searchWordsIndex != NSNotFound) {
							[searchWordsArray removeObjectAtIndex:searchWordsIndex];
						} else {
							NSLog(@"displayLog: Couldn't find %@ in %@", quotedWord, searchWordsArray);
						}
					}
					
					//Add the full quoted string
					[searchWordsArray addObject:quotedString];
				}
				[pool release];
			}

			BOOL shouldScrollToWord = NO;
			scrollRange = NSMakeRange([displayText length],0);

			enumerator = [searchWordsArray objectEnumerator];
			while ((searchWord = [enumerator nextObject])) {
				NSRange     occurrence;
				
				//Check against and/or.  We don't just remove it from the array because then we couldn't check case insensitively.
				if (([searchWord caseInsensitiveCompare:@"and"] != NSOrderedSame) &&
					([searchWord caseInsensitiveCompare:@"or"] != NSOrderedSame)) {
					[self hilightOccurrencesOfString:searchWord inString:displayText firstOccurrence:&occurrence];
					
					//We'll want to scroll to the first occurrance of any matching word or words
					if (occurrence.location < scrollRange.location) {
						scrollRange = occurrence;
						shouldScrollToWord = YES;
					}
				}
			}
			
			//If we shouldn't be scrolling to a new range, we want to scroll to the top
			if (!shouldScrollToWord) scrollRange = NSMakeRange(0, 0);
			
			[searchWordsArray release];
		}
		
		//Filter emoticons
		if (showEmoticons) {
			finalDisplayText = [[adium contentController] filterAttributedString:displayText
																 usingFilterType:AIFilterMessageDisplay
																	   direction:AIFilterOutgoing
																		 context:nil];
		} else {
			finalDisplayText = displayText;
		}
	}

	if (finalDisplayText) {
		[[textView_content textStorage] setAttributedString:finalDisplayText];

		//Set this string and scroll to the top/bottom/occurrence
		if ((searchMode == LOG_SEARCH_CONTENT) || automaticSearch) {
			[textView_content scrollRangeToVisible:scrollRange];
		} else {
			[textView_content scrollRangeToVisible:NSMakeRange(0,0)];
		}

	} else {
		//No log selected, empty the view
		[textView_content setString:@""];
	}

	[displayText release];
}

- (void)displayLog:(AIChatLog *)theLog
{
	[self displayLogs:(theLog ? [NSArray arrayWithObject:theLog] : nil)];
}

//Reselect the displayed log (Or another log if not possible)
- (void)selectDisplayedLog
{
    int     firstIndex = NSNotFound;
    
    /* Is the log we had selected still in the table?
	 * (When performing an automatic search, we ignore the previous selection.  This ensures that we always
     * end up with the newest log selected, even when a search takes multiple passes/refreshes to complete).
	 */
	if (!automaticSearch) {
		[resultsLock lock];
		[tableView_results selectItemsInArray:displayedLogArray usingSourceArray:currentSearchResults];
		[resultsLock unlock];
		
		firstIndex = [[tableView_results selectedRowIndexes] firstIndex];
	}

	if (firstIndex != NSNotFound) {
		[tableView_results scrollRowToVisible:[[tableView_results selectedRowIndexes] firstIndex]];
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
	if ([currentSearchResults count] != 0) {
		theLog = [currentSearchResults objectAtIndex:0];
	}
	[resultsLock unlock];
	
	//Change the table selection to this new log
	//We need a little trickery here.  When we change the row, the table view will call our tableViewSelectionDidChange: method.
	//This method will clear the automaticSearch flag, and break any scroll-to-bottom behavior we have going on for the custom
	//search.  As a quick hack, I've added an ignoreSelectionChange flag that can be set to inform our selectionDidChange method
	//that we instantiated this selection change, and not the user.
	ignoreSelectionChange = YES;
	[tableView_results selectRow:0 byExtendingSelection:NO];
	[tableView_results scrollRowToVisible:0];
	ignoreSelectionChange = NO;

	[self displayLog:theLog];  //Manually update the displayed log
}

//Highlight the occurences of a search string within a displayed log
- (void)hilightOccurrencesOfString:(NSString *)littleString inString:(NSMutableAttributedString *)bigString firstOccurrence:(NSRange *)outRange
{
    int					location = 0;
    NSRange				searchRange, foundRange;
    NSString			*plainBigString = [bigString string];
	unsigned			plainBigStringLength = [plainBigString length];
	NSMutableDictionary *attributeDictionary = nil;

    outRange->location = NSNotFound;

    //Search for the little string in the big string
    while (location != NSNotFound && location < plainBigStringLength) {
        searchRange = NSMakeRange(location, plainBigStringLength-location);
        foundRange = [plainBigString rangeOfString:littleString options:NSCaseInsensitiveSearch range:searchRange];
		
		//Bold and color this match
        if (foundRange.location != NSNotFound) {
			if (outRange->location == NSNotFound) *outRange = foundRange;

			if (!attributeDictionary) {
				attributeDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
					[NSFont boldSystemFontOfSize:14], NSFontAttributeName,
					[NSColor yellowColor], NSBackgroundColorAttributeName,
					nil];
			}
			[bigString addAttributes:attributeDictionary
							   range:foundRange];
        }

        location = NSMaxRange(foundRange);
    }
}


//Sorting --------------------------------------------------------------------------------------------------------------
#pragma mark Sorting
- (void)resortLogs
{
	NSString *identifier = [selectedColumn identifier];

    //Resort the data
	[resultsLock lock];
    if ([identifier isEqualToString:@"To"]) {
		[currentSearchResults sortUsingSelector:(sortDirection ? @selector(compareToReverse:) : @selector(compareTo:))];
		
    } else if ([identifier isEqualToString:@"From"]) {
        [currentSearchResults sortUsingSelector:(sortDirection ? @selector(compareFromReverse:) : @selector(compareFrom:))];
		
    } else if ([identifier isEqualToString:@"Date"]) {
        [currentSearchResults sortUsingSelector:(sortDirection ? @selector(compareDateReverse:) : @selector(compareDate:))];
		
    } else if ([identifier isEqualToString:@"Rank"]) {
	    [currentSearchResults sortUsingSelector:(sortDirection ? @selector(compareRankReverse:) : @selector(compareRank:))];
	}
	
    [resultsLock unlock];

    //Reload the data
    [tableView_results reloadData];

    //Reapply the selection
    [self selectDisplayedLog];	
}

//Sorts the selected log array and adjusts the selected column
- (void)sortCurrentSearchResultsForTableColumn:(NSTableColumn *)tableColumn direction:(BOOL)direction
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

//Searching ------------------------------------------------------------------------------------------------------------
#pragma mark Searching
//(Jag)Change search string
- (void)controlTextDidChange:(NSNotification *)notification
{
    if (searchMode != LOG_SEARCH_CONTENT) {
		[self updateSearch:nil];
    }
}

//Change search string (Called by searchfield)
- (IBAction)updateSearch:(id)sender
{
    automaticSearch = NO;
    [self setSearchString:[[[searchField_logs stringValue] copy] autorelease]];
    [self startSearchingClearingCurrentResults:YES];
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

//Begin the current search
- (void)startSearchingClearingCurrentResults:(BOOL)clearCurrentResults
{
    NSDictionary    *searchDict;
    
    //Stop any existing searches
    [self stopSearching];
    	
    //Once all searches have exited, we can start a new one
	if (clearCurrentResults) {
		[resultsLock lock];
		[currentSearchResults release]; currentSearchResults = [[NSMutableArray alloc] init];
		[resultsLock unlock];
	}
	
    searchDict = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithInt:activeSearchID], @"ID",
		[NSNumber numberWithInt:searchMode], @"Mode",
		activeSearchString, @"String",
		[plugin logContentIndex], @"SearchIndex",
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
    //Increase the active search ID so any existing searches stop, and then
    //wait for any active searches to finish and release the lock
    activeSearchID++;

	if (!windowIsClosing) {
		[searchingLock lock]; [searchingLock unlock];
	}
	
	//If the plugin is in the middle of indexing, and we are content searching, we could be autoupdating a search.
	//Be sure to invalidate the timer.
	[aggregateLogIndexProgressTimer invalidate];
	[aggregateLogIndexProgressTimer release]; aggregateLogIndexProgressTimer = nil;
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

	[self updateRankColumnVisibility];
    [self buildSearchMenu];
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

	[self updateRankColumnVisibility];
}

//Build the search mode menu
- (void)buildSearchMenu
{
    NSMenu  *cellMenu = [[[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:SEARCH_MENU] autorelease];
    [cellMenu addItem:[self _menuItemWithTitle:FROM forSearchMode:LOG_SEARCH_FROM]];
    [cellMenu addItem:[self _menuItemWithTitle:TO forSearchMode:LOG_SEARCH_TO]];
    [cellMenu addItem:[self _menuItemWithTitle:DATE forSearchMode:LOG_SEARCH_DATE]];
    [cellMenu addItem:[self _menuItemWithTitle:CONTENT forSearchMode:LOG_SEARCH_CONTENT]];

	[[searchField_logs cell] setSearchMenuTemplate:cellMenu];
}

/*
 * @brief Focus the log viewer on a particular contact
 *
 * If the contact is within a metacontact, the metacontact will be focused.
 */
- (void)filterForContact:(AIListContact *)inContact
{
	AIListContact *parentContact = [inContact parentContact];
	
	/* Ensure the contacts list includes this contact, since only existing AIListContacts are be used
	 * (with AILogToGroup objects used if an AIListContact isn't available) but that situation may have changed
	 * with regard to inContact since the log viewer opened.
	 */
	[self rebuildContactsList];
	
	[outlineView_contacts selectItemsInArray:[NSArray arrayWithObject:(parentContact ? (id)parentContact : (id)ALL_CONTACTS_IDENTIFIER)]];
	unsigned int selectedRow = [[outlineView_contacts selectedRowIndexes] firstIndex];
	if (selectedRow != NSNotFound) {
		[outlineView_contacts scrollRowToVisible:selectedRow];
	}

	//If the search mode is currently the TO field, switch it to content, which is what it should now intuitively do
	if (searchMode == LOG_SEARCH_TO) {
		[self setSearchMode:LOG_SEARCH_CONTENT];
		
		//Update our search string to ensure we're configured for content searching
		[self setSearchString:activeSearchString];
	}
	
    [self startSearchingClearingCurrentResults:YES];
}

/*
 * @brief Returns a menu item for the search mode menu
 */
- (NSMenuItem *)_menuItemWithTitle:(NSString *)title forSearchMode:(LogSearchMode)mode
{
    NSMenuItem  *menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:title 
																				 action:@selector(selectSearchType:) 
																		  keyEquivalent:@""];
    [menuItem setTag:mode];
    [menuItem setState:(mode == searchMode ? NSOnState : NSOffState)];
    
    return [menuItem autorelease];
}

#pragma mark Filtering search results

- (BOOL)chatLogMatchesDateFilter:(AIChatLog *)inChatLog
{
	BOOL matchesDateFilter;

	switch (filterDateType) {
		case AIDateTypeAfter:
			matchesDateFilter = ([[inChatLog date] timeIntervalSinceDate:filterDate] > 0);
			break;
		case AIDateTypeBefore:
			matchesDateFilter = ([[inChatLog date] timeIntervalSinceDate:filterDate] < 0);
			break;
		case AIDateTypeExactly:
			matchesDateFilter = [inChatLog isFromSameDayAsDate:filterDate];
			break;
		default:
			matchesDateFilter = YES;
			break;
	}

	return matchesDateFilter;
}


NSArray *pathComponentsForDocument(SKDocumentRef inDocument)
{
	CFURLRef	url = SKDocumentCopyURL(inDocument);
	CFStringRef logPath = CFURLCopyFileSystemPath(url, kCFURLPOSIXPathStyle);
	NSArray		*pathComponents = [(NSString *)logPath pathComponents];
	
	CFRelease(url);
	CFRelease(logPath);
	
	return pathComponents;
}

/*
 * @brief Should a search display a document with the given information?
 */
- (BOOL)searchShouldDisplayDocument:(SKDocumentRef)inDocument pathComponents:(NSArray *)pathComponents testDate:(BOOL)testDate
{
	BOOL shouldDisplayDocument = YES;

	if ([contactIDsToFilter count]) {
		//Determine the path components if we weren't supplied them
		if (!pathComponents) pathComponents = pathComponentsForDocument(inDocument);

		unsigned int numPathComponents = [pathComponents count];
		
		NSArray *serviceAndFromUIDArray = [[pathComponents objectAtIndex:numPathComponents-3] componentsSeparatedByString:@"."];
		NSString *serviceClass = (([serviceAndFromUIDArray count] >= 2) ? [serviceAndFromUIDArray objectAtIndex:0] : @"");

		NSString *contactName = [pathComponents objectAtIndex:(numPathComponents-2)];

		shouldDisplayDocument = [contactIDsToFilter containsObject:[[NSString stringWithFormat:@"%@.%@",serviceClass,contactName] compactedString]];
	} 
	
	if (shouldDisplayDocument && testDate && (filterDateType != AIDateTypeAnyDate)) {
		if (!pathComponents) pathComponents = pathComponentsForDocument(inDocument);

		unsigned int	numPathComponents = [pathComponents count];
		NSString		*toPath = [NSString stringWithFormat:@"%@/%@",
			[pathComponents objectAtIndex:numPathComponents-3],
			[pathComponents objectAtIndex:numPathComponents-2]];
		NSString		*path = [NSString stringWithFormat:@"%@/%@",toPath,[pathComponents objectAtIndex:numPathComponents-1]];
		AIChatLog		*theLog;
		
		theLog = [[logToGroupDict objectForKey:toPath] logAtPath:path];
		
		shouldDisplayDocument = [self chatLogMatchesDateFilter:theLog];
	}
	
	return shouldDisplayDocument;
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
					[self _logContentFilter:searchString
								   searchID:searchID
							  onSearchIndex:(SKIndexRef)[searchInfoDict objectForKey:@"SearchIndex"]];
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
		
		//When searching in LOG_SEARCH_FROM, we only proceed into matching groups
		if ((mode != LOG_SEARCH_FROM) ||
			(!searchString) || 
			([[fromGroup fromUID] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound)) {

			//Walk through every 'to' group
			toEnumerator = [[fromGroup toGroupArray] objectEnumerator];
			while ((toGroup = [toEnumerator nextObject]) && (searchID == activeSearchID)) {
				
				/* When searching in LOG_SEARCH_TO, we only proceed into matching groups
				 * For all other search modes, we always proceed here so long as either:
				 *	a) We are not filtering for specific contact names or
				 *	b) The contact name matches one of the names in contactIDsToFilter
				 */
				if ((![contactIDsToFilter count] || [contactIDsToFilter containsObject:[[NSString stringWithFormat:@"%@.%@",[toGroup serviceClass],[toGroup to]] compactedString]]) &&
				   ((mode != LOG_SEARCH_TO) ||
				   (!searchString) || 
				   ([[toGroup to] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound))) {
					
					//Walk through every log

					logEnumerator = [toGroup logEnumerator];
					while ((theLog = [logEnumerator nextObject]) && (searchID == activeSearchID)) {
						/* When searching in LOG_SEARCH_DATE, we must have matching dates
						 * For all other search modes, we always proceed here
						 */
						if ((mode != LOG_SEARCH_DATE) ||
						   (!searchString) ||
						   (searchStringDate && [theLog isFromSameDayAsDate:searchStringDate])) {

							if ([self chatLogMatchesDateFilter:theLog]) {
								//Add the log
								[resultsLock lock];
								[currentSearchResults addObject:theLog];
								[resultsLock unlock];							
								
								//Update our status
								if (lastUpdate == 0 || TickCount() > lastUpdate + LOG_SEARCH_STATUS_INTERVAL) {
									[self performSelectorOnMainThread:@selector(updateProgressDisplay)
														   withObject:nil
														waitUntilDone:NO];
									lastUpdate = TickCount();
								}
							}
						}
					}
				}
			}	    
		}
    }
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
    count = [currentSearchResults count];
    [resultsLock unlock];
    
    return count;
}


- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    NSString	*identifier = [tableColumn identifier];

	if ([identifier isEqualToString:@"Rank"] && row >= 0 && row < [currentSearchResults count]) {
		AIChatLog       *theLog = [currentSearchResults objectAtIndex:row];
		
		[aCell setPercentage:[theLog rankingPercentage]];
	}
}

//
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    NSString	*identifier = [tableColumn identifier];
    id          value = nil;
    
    [resultsLock lock];
    if (row < 0 || row >= [currentSearchResults count]) {
		if ([identifier isEqualToString:@"Service"]) {
			value = blankImage;
		} else {
			value = @"";
		}
		
	} else {
		AIChatLog       *theLog = [currentSearchResults objectAtIndex:row];

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
}

//
- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    if (!ignoreSelectionChange) {
		NSArray		*selectedLogs;
		
		//Update the displayed log
		automaticSearch = NO;
		
		[resultsLock lock];
		selectedLogs = [tableView_results arrayOfSelectedItemsUsingSourceArray:currentSearchResults];
		[resultsLock unlock];
		
		[self displayLogs:selectedLogs];
    }
}

//Sort the log array & reflect the new column
- (void)tableView:(NSTableView*)tableView didClickTableColumn:(NSTableColumn *)tableColumn
{    
    [self sortCurrentSearchResultsForTableColumn:tableColumn
                                   direction:(selectedColumn == tableColumn ? !sortDirection : sortDirection)];
}

- (void)tableViewDeleteSelectedRows:(NSTableView *)tableView
{
    [self deleteSelectedLog:nil];
}

- (void)configureTypeSelectTableView:(KFTypeSelectTableView *)tableView
{
	if (tableView == tableView_results) {
		[tableView setSearchColumnIdentifiers:[NSSet setWithObjects:@"To", @"From", nil]];

	} else if (tableView == (KFTypeSelectTableView *)outlineView_contacts) {
		[tableView setSearchWraps:YES];
		[tableView setMatchAlgorithm:KFSubstringMatchAlgorithm];
		[tableView setSearchColumnIdentifiers:[NSSet setWithObject:@"Contacts"]];
	}
}

- (IBAction)toggleEmoticonFiltering:(id)sender
{
	showEmoticons = !showEmoticons;
	[sender setLabel:(showEmoticons ? HIDE_EMOTICONS : SHOW_EMOTICONS)];
	[sender setImage:[NSImage imageNamed:(showEmoticons ? IMAGE_EMOTICONS_ON : IMAGE_EMOTICONS_OFF) forClass:[self class]]];

	[self displayLogs:displayedLogArray];
}

#pragma mark Outline View Data source
- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item
{
	if (!item) {
		if (index == 0) {
			return ALL_CONTACTS_IDENTIFIER;

		} else {
			return [toArray objectAtIndex:index-1]; //-1 for the All item, which is index 0
		}

	} else {
		if ([item isKindOfClass:[AIMetaContact class]]) {
			return [[(AIMetaContact *)item listContactsIncludingOfflineAccounts] objectAtIndex:index];
		}
	}
	
	return nil;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	return (!item || 
			([item isKindOfClass:[AIMetaContact class]] && ([[(AIMetaContact *)item listContactsIncludingOfflineAccounts] count] > 1)) ||
			[item isKindOfClass:[NSArray class]]);
}

- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	if (!item) {
		return [toArray count] + 1; //+1 for the All item

	} else if ([item isKindOfClass:[AIMetaContact class]]) {
		unsigned count = [[(AIMetaContact *)item listContactsIncludingOfflineAccounts] count];
		if (count > 1)
			return count;
		else
			return 0;

	} else {
		return 0;
	}
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	if ([item isKindOfClass:[AIMetaContact class]]) {
		return [(AIMetaContact *)item longDisplayName];
		
	} else if ([item isKindOfClass:[AIListContact class]]) {
		if ([(AIListContact *)item parentContact] != item) {
			//This contact is within a metacontact - always show its UID
			return [(AIListContact *)item formattedUID];
		} else {
			return [(AIListContact *)item longDisplayName];
		} 
		
	} else if ([item isKindOfClass:[AILogToGroup class]]) {
		return [(AILogToGroup *)item to];
		
	} else if ([item isKindOfClass:[ALL_CONTACTS_IDENTIFIER class]]) {
		int contactCount = [toArray count];
		return [NSString stringWithFormat:AILocalizedString(@"All (%@)", nil),
			((contactCount == 1) ?
			 AILocalizedString(@"1 Contact", nil) :
			 [NSString stringWithFormat:AILocalizedString(@"%i Contacts", nil), contactCount])]; 

	} else if ([item isKindOfClass:[NSString class]]) {
		return item;
		
	} else {
		NSLog(@"%@: no idea",item);
		return nil;
	}
}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	if ([item isKindOfClass:[AIMetaContact class]] &&
		[[(AIMetaContact *)item listContactsIncludingOfflineAccounts] count] > 1) {
		/* If the metacontact contains a single contact, fall through (isKindOfClass:[AIListContact class]) and allow using of a service icon.
		 * If it has multiple contacts, use no icon unless a user icon is present.
		 */
		[cell setImage:[AIUserIcons listUserIconForContact:(AIListContact *)item
													  size:NSMakeSize(16,16)]];

	} else if ([item isKindOfClass:[AIListContact class]]) {
		NSImage	*image = [AIUserIcons listUserIconForContact:(AIListContact *)item
														size:NSMakeSize(16,16)];
		if (!image) image = [AIServiceIcons serviceIconForObject:(AIListContact *)item
															type:AIServiceIconSmall
													   direction:AIIconFlipped];
		[cell setImage:image];

	} else if ([item isKindOfClass:[AILogToGroup class]]) {
		[cell setImage:[AIServiceIcons serviceIconForServiceID:[(AILogToGroup *)item serviceClass]
													   type:AIServiceIconSmall
												  direction:AIIconFlipped]];
		
	} else if ([item isKindOfClass:[ALL_CONTACTS_IDENTIFIER class]]) {
		if ([[outlineView arrayOfSelectedItems] containsObjectIdenticalTo:item] &&
			([[self window] isKeyWindow] && ([[self window] firstResponder] == self))) {
			if (!adiumIconHighlighted) {
				adiumIconHighlighted = [[NSImage imageNamed:@"adiumHighlight"
												   forClass:[self class]] retain];
			}

			[cell setImage:adiumIconHighlighted];

		} else {
			if (!adiumIcon) {
				adiumIcon = [[NSImage imageNamed:@"adium"
										forClass:[self class]] retain];
			}

			[cell setImage:adiumIcon];
		}

	} else if ([item isKindOfClass:[NSString class]]) {
		[cell setImage:nil];
		
	} else {
		NSLog(@"%@: no idea",item);
		[cell setImage:nil];
	}	
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
	NSArray *selectedItems = [outlineView_contacts arrayOfSelectedItems];

	[contactIDsToFilter removeAllObjects];

	if ([selectedItems count] && ![selectedItems containsObject:ALL_CONTACTS_IDENTIFIER]) {
		id		item;
		NSEnumerator *enumerator;

		enumerator = [selectedItems objectEnumerator];
		while ((item = [enumerator nextObject])) {
			if ([item isKindOfClass:[AIMetaContact class]]) {
				NSEnumerator	*metaEnumerator;
				AIListContact	*contact;

				metaEnumerator = [[(AIMetaContact *)item listContactsIncludingOfflineAccounts] objectEnumerator];
				while ((contact = [metaEnumerator nextObject])) {
					[contactIDsToFilter addObject:
						[[[NSString stringWithFormat:@"%@.%@",[contact serviceID],[contact UID]] compactedString] safeFilenameString]];
				}
				
			} else if ([item isKindOfClass:[AIListContact class]]) {
				[contactIDsToFilter addObject:
					[[[NSString stringWithFormat:@"%@.%@",[(AIListContact *)item serviceID],[(AIListContact *)item UID]] compactedString] safeFilenameString]];
				
			} else if ([item isKindOfClass:[AILogToGroup class]]) {
				[contactIDsToFilter addObject:[[NSString stringWithFormat:@"%@.%@",[(AILogToGroup *)item serviceClass],[(AILogToGroup *)item to]] compactedString]]; 
			}
		}
	}
	
	[self startSearchingClearingCurrentResults:YES];
}

static int toArraySort(id itemA, id itemB, void *context)
{
	NSString *nameA = [sharedLogViewerInstance outlineView:nil objectValueForTableColumn:nil byItem:itemA];
	NSString *nameB = [sharedLogViewerInstance outlineView:nil objectValueForTableColumn:nil byItem:itemB];

	return [nameA caseInsensitiveCompare:nameB];
}	

- (void)draggedDividerRightBy:(float)deltaX
{	
	desiredContactsSourceListDeltaX = deltaX;
	[splitView_contacts_results resizeSubviewsWithOldSize:[splitView_contacts_results frame].size];
	desiredContactsSourceListDeltaX = 0;
}

- (void)splitView:(NSSplitView *)sender resizeSubviewsWithOldSize:(NSSize)oldSize
{
	if ((sender == splitView_contacts_results) &&
		desiredContactsSourceListDeltaX != 0) {
		float dividerThickness = [sender dividerThickness];

		NSRect newFrame = [sender frame];		
		NSRect leftFrame = [containingView_contactsSourceList frame]; 
		NSRect rightFrame = [containingView_results frame];

		leftFrame.size.width += desiredContactsSourceListDeltaX; 
		leftFrame.size.height = newFrame.size.height;
		leftFrame.origin = NSMakePoint(0,0);

		rightFrame.size.width = newFrame.size.width - leftFrame.size.width - dividerThickness;
		rightFrame.size.height = newFrame.size.height;
		rightFrame.origin.x = leftFrame.size.width + dividerThickness;

		[containingView_contactsSourceList setFrame:leftFrame];
		[containingView_contactsSourceList setNeedsDisplay:YES];
		[containingView_results setFrame:rightFrame];
		[containingView_results setNeedsDisplay:YES];

	} else {
		//Perform the default implementation
		[sender adjustSubviews];
	}
}


//Window Toolbar -------------------------------------------------------------------------------------------------------
#pragma mark Window Toolbar
- (NSString *)dateItemNibName
{
	return nil;
}

- (void)installToolbar
{	
	[NSBundle loadNibNamed:[self dateItemNibName] owner:self];

    NSToolbar 		*toolbar = [[[NSToolbar alloc] initWithIdentifier:TOOLBAR_LOG_VIEWER] autorelease];
    NSToolbarItem	*toolbarItem;
	
    [toolbar setDelegate:self];
    [toolbar setDisplayMode:NSToolbarDisplayModeIconAndLabel];
    [toolbar setSizeMode:NSToolbarSizeModeRegular];
    [toolbar setVisible:YES];
    [toolbar setAllowsUserCustomization:NO];
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
	if ([toolbarItem respondsToSelector:@selector(setVisibilityPriority:)]) {
		[toolbarItem setVisibilityPriority:(NSToolbarItemVisibilityPriorityHigh + 1)];
	}
	[toolbarItem setMinSize:NSMakeSize(130, NSHeight([view_SearchField frame]))];
	[toolbarItem setMaxSize:NSMakeSize(230, NSHeight([view_SearchField frame]))];
	[toolbarItems setObject:toolbarItem forKey:[toolbarItem itemIdentifier]];

	toolbarItem = [AIToolbarUtilities toolbarItemWithIdentifier:DATE_ITEM_IDENTIFIER
														  label:AILocalizedString(@"Date", nil)
												   paletteLabel:AILocalizedString(@"Date", nil)
														toolTip:AILocalizedString(@"Filter logs by date",nil)
														 target:self
												settingSelector:@selector(setView:)
													itemContent:view_DatePicker
														 action:nil
														   menu:nil];
	if ([toolbarItem respondsToSelector:@selector(setVisibilityPriority:)]) {
		[toolbarItem setVisibilityPriority:NSToolbarItemVisibilityPriorityHigh];
	}
	[toolbarItem setMinSize:[view_DatePicker frame].size];
	[toolbarItem setMaxSize:[view_DatePicker frame].size];
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

	[self configureDateFilter];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    return [AIToolbarUtilities toolbarItemFromDictionary:toolbarItems withIdentifier:itemIdentifier];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
    return [NSArray arrayWithObjects:DATE_ITEM_IDENTIFIER, NSToolbarFlexibleSpaceItemIdentifier,
		@"delete", @"toggleemoticons", NSToolbarFlexibleSpaceItemIdentifier,
		@"search", nil];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
    return [[toolbarItems allKeys] arrayByAddingObjectsFromArray:
		[NSArray arrayWithObjects:NSToolbarSeparatorItemIdentifier,
			NSToolbarSpaceItemIdentifier,
			NSToolbarFlexibleSpaceItemIdentifier,
			NSToolbarCustomizeToolbarItemIdentifier, nil]];
}

#pragma mark Date filter

/*
 * @brief Returns a menu item for the date type filter menu
 */
- (NSMenuItem *)_menuItemForDateType:(AIDateType)dateType dict:(NSDictionary *)dateTypeTitleDict
{
    NSMenuItem  *menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:[dateTypeTitleDict objectForKey:[NSNumber numberWithInt:dateType]] 
																				 action:@selector(selectDateType:) 
																		  keyEquivalent:@""];
    [menuItem setTag:dateType];
    
    return [menuItem autorelease];
}

- (NSMenu *)dateTypeMenu
{
	NSDictionary *dateTypeTitleDict = [NSDictionary dictionaryWithObjectsAndKeys:
		AILocalizedString(@"Any Date", nil), [NSNumber numberWithInt:AIDateTypeAnyDate],
		AILocalizedString(@"Today", nil), [NSNumber numberWithInt:AIDateTypeToday],
		AILocalizedString(@"Since Yesterday", nil), [NSNumber numberWithInt:AIDateTypeSinceYesterday],
		AILocalizedString(@"This Week", nil), [NSNumber numberWithInt:AIDateTypeThisWeek],
		AILocalizedString(@"Within Last 2 Weeks", nil), [NSNumber numberWithInt:AIDateTypeWithinLastTwoWeeks],
		AILocalizedString(@"This Month", nil), [NSNumber numberWithInt:AIDateTypeThisMonth],
		AILocalizedString(@"Within Last 2 Months", nil), [NSNumber numberWithInt:AIDateTypeWithinLastTwoMonths],
		nil];
	NSMenu	*dateTypeMenu = [[NSMenu alloc] init];
	AIDateType dateType;
	
	[dateTypeMenu addItem:[self _menuItemForDateType:AIDateTypeAnyDate dict:dateTypeTitleDict]];
	[dateTypeMenu addItem:[NSMenuItem separatorItem]];

	for (dateType = AIDateTypeToday; dateType < AIDateTypeExactly; dateType++) {
		[dateTypeMenu addItem:[self _menuItemForDateType:dateType dict:dateTypeTitleDict]];
	}
	
	return [dateTypeMenu autorelease];
}

- (int)daysSinceStartOfWeekGivenToday:(NSCalendarDate *)today
{
	int todayDayOfWeek = [today dayOfWeek];

	//Try to look at the iCal preferences if possible
	if (!iCalFirstDayOfWeekDetermined) {
		CFPropertyListRef iCalFirstDayOfWeek = CFPreferencesCopyAppValue(CFSTR("first day of week"),CFSTR("com.apple.iCal"));
		if (iCalFirstDayOfWeek) {
			//This should return a CFNumberRef... we're using another app's prefs, so make sure.
			if (CFGetTypeID(iCalFirstDayOfWeek) == CFNumberGetTypeID()) {
				firstDayOfWeek = [(NSNumber *)iCalFirstDayOfWeek intValue];
			}

			CFRelease(iCalFirstDayOfWeek);
		}

		//Don't check again
		iCalFirstDayOfWeekDetermined = YES;
	}

	return ((todayDayOfWeek >= firstDayOfWeek) ? (todayDayOfWeek - firstDayOfWeek) : ((todayDayOfWeek + 7) - firstDayOfWeek));
}

/*
 * @brief A new date type was selected
 *
 * This does not start a search
 */
- (void)selectedDateType:(AIDateType)dateType
{
	NSCalendarDate	*today = [NSCalendarDate date];
	
	[filterDate release]; filterDate = nil;
	
	switch (dateType) {
		case AIDateTypeAnyDate:
			filterDateType = AIDateTypeAnyDate;
			break;
			
		case AIDateTypeToday:
			filterDateType = AIDateTypeExactly;
			filterDate = [today retain];
			break;
			
		case AIDateTypeSinceYesterday:
			filterDateType = AIDateTypeAfter;
			filterDate = [[today dateByAddingYears:0
											months:0
											  days:-1
											 hours:-[today hourOfDay]
										   minutes:-[today minuteOfHour]
										   seconds:-([today secondOfMinute] + 1)] retain];
			break;
			
		case AIDateTypeThisWeek:
			filterDateType = AIDateTypeAfter;
			filterDate = [[today dateByAddingYears:0
											months:0
											  days:-[self daysSinceStartOfWeekGivenToday:today]
											 hours:-[today hourOfDay]
										   minutes:-[today minuteOfHour]
										   seconds:-([today secondOfMinute] + 1)] retain];
			break;
			
		case AIDateTypeWithinLastTwoWeeks:
			filterDateType = AIDateTypeAfter;
			filterDate = [[today dateByAddingYears:0
											months:0
											  days:-14
											 hours:-[today hourOfDay]
										   minutes:-[today minuteOfHour]
										   seconds:-([today secondOfMinute] + 1)] retain];
			break;
			
		case AIDateTypeThisMonth:
			filterDateType = AIDateTypeAfter;
			filterDate = [[[NSCalendarDate date] dateByAddingYears:0
															months:0
															  days:-[today dayOfMonth]
															 hours:0
														   minutes:0
														   seconds:-1] retain];
			break;
			
		case AIDateTypeWithinLastTwoMonths:
			filterDateType = AIDateTypeAfter;
			filterDate = [[[NSCalendarDate date] dateByAddingYears:0
															months:-1
															  days:-[today dayOfMonth]
															 hours:0
														   minutes:0
														   seconds:-1] retain];			
			break;
			
		default:
			break;
	}	
}

/*
 * @brief Select the date type
 */
- (void)selectDateType:(id)sender
{
	[self selectedDateType:[sender tag]];
	[self startSearchingClearingCurrentResults:YES];
}

- (void)configureDateFilter
{
	firstDayOfWeek = 0; /* Sunday */
	iCalFirstDayOfWeekDetermined = NO;

	[popUp_dateFilter setMenu:[self dateTypeMenu]];
	[popUp_dateFilter selectItemWithTag:AIDateTypeAnyDate];
	[self selectedDateType:AIDateTypeAnyDate];
}

#pragma mark Open Log

- (void)openLogAtPath:(NSString *)inPath
{
	AIChatLog   *chatLog = nil;
	NSString	*basePath = [AILoggerPlugin logBasePath];

	//inPath should be in a folder of the form SERVICE.ACCOUNT_NAME/CONTACT_NAME/log.extension
	NSArray		*pathComponents = [inPath pathComponents];
	int			lastIndex = [pathComponents count];
	NSString	*logName = [pathComponents objectAtIndex:--lastIndex];
	NSString	*contactName = [pathComponents objectAtIndex:--lastIndex];
	NSString	*serviceAndAccountName = [pathComponents objectAtIndex:--lastIndex];	
	NSString		*relativeToGroupPath = [serviceAndAccountName stringByAppendingPathComponent:contactName];

	NSString	*serviceID = [[serviceAndAccountName componentsSeparatedByString:@"."] objectAtIndex:0];
	//Filter for logs from the contact associated with the log we're loading
	[self filterForContact:[[adium contactController] contactWithService:[[adium accountController] firstServiceWithServiceID:serviceID]
																 account:nil
																	 UID:contactName]];
	
	NSString *canonicalBasePath = [basePath stringByStandardizingPath];
	NSString *canonicalInPath = [inPath stringByStandardizingPath];

	if ([canonicalInPath hasPrefix:[canonicalBasePath stringByAppendingString:@"/"]]) {
		AILogToGroup	*logToGroup = [logToGroupDict objectForKey:[serviceAndAccountName stringByAppendingPathComponent:contactName]];
		
		chatLog = [logToGroup logAtPath:[relativeToGroupPath stringByAppendingPathComponent:logName]];
		
	} else {
		/* Different Adium user... this sucks. We're given a path like this:
		 *	/Users/evands/Application Support/Adium 2.0/Users/OtherUser/Logs/AIM.Tekjew/HotChick001/HotChick001 (3-30-2005).AdiumLog
		 * and we want to make it relative to our current user's logs folder, which might be
		 *  /Users/evands/Application Support/Adium 2.0/Users/Default/Logs
		 *
		 * To achieve this, add a "/.." for each directory in our current user's logs folder, then add the full path to the log.
		 */
		NSString	*fakeRelativePath = @"";
		
		//Use .. to get back to the root from the base path
		int componentsOfBasePath = [[canonicalBasePath pathComponents] count];
		for (int i = 0; i < componentsOfBasePath; i++) {
			fakeRelativePath = [fakeRelativePath stringByAppendingPathComponent:@".."];
		}
		
		//Now add the path from the root to the actual log
		fakeRelativePath = [fakeRelativePath stringByAppendingPathComponent:canonicalInPath];
		chatLog = [[[AIChatLog alloc] initWithPath:fakeRelativePath
											  from:[serviceAndAccountName substringFromIndex:([serviceID length] + 1)] //One off for the '.'
												to:contactName
									  serviceClass:serviceID] autorelease];
	}

	//Now display the requested log
	if (chatLog) {
		[self displayLog:chatLog];
	}
}

#pragma mark Printing

- (void)adiumPrint:(id)sender
{
	[textView_content print:sender];
}

- (BOOL)validatePrintMenuItem:(id <NSMenuItem>)menuItem
{
	return ([displayedLogArray count] > 0);
}

@end

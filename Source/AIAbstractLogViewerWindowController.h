//
//  AIAbstractLogViewerWindowController.h
//  Adium
//
//  Created by Evan Schoenberg on 3/24/06.
//

#import <Adium/AIWindowController.h>

@class AIChatLog, AILoggerPlugin;

#define	REFRESH_RESULTS_INTERVAL		0.5 //Interval between results refreshes while searching
#define LOG_SEARCH_STATUS_INTERVAL		20	//1/60ths of a second to wait before refreshing search status

#define	LOG_VIEWER_DID_UPDATE_LOG_ARRAYS	@"LogViewerDidUpdateLogArrays"

#define SEARCH_MENU						AILocalizedString(@"Search Menu",nil)
#define FROM							AILocalizedString(@"From",nil)
#define TO								AILocalizedString(@"To",nil)

#define ACCOUNT							AILocalizedString(@"Account",nil)
#define DESTINATION						AILocalizedString(@"Destination",nil)

#define DATE							AILocalizedString(@"Date",nil)
#define CONTENT							AILocalizedString(@"Content",nil)
#define DELETE							AILocalizedString(@"Delete",nil)
#define DELETEALL						AILocalizedString(@"Delete All",nil)
#define SEARCH							AILocalizedString(@"Search",nil)

typedef enum {
    LOG_SEARCH_FROM = 0,
    LOG_SEARCH_TO,
    LOG_SEARCH_DATE,
    LOG_SEARCH_CONTENT
} LogSearchMode;

@class AIListContact;

@interface AIAbstractLogViewerWindowController : AIWindowController {
	AILoggerPlugin							*plugin;

    IBOutlet	NSTableView                 *tableView_results;
    IBOutlet	NSTextView                  *textView_content;

	IBOutlet    NSView                      *view_SearchField;
    IBOutlet    NSButton                    *button_deleteLogs;

	//Array of selected / displayed logs.  (Locked access)
    NSMutableArray		*currentSearchResults;		//Array of filtered/resulting logs
    NSLock				*resultsLock;			//Lock before touching the array
    AIChatLog			*displayedLog;			//Currently selected/displayed log	

	LogSearchMode		searchMode;				//Currently selected search mode

	IBOutlet    NSProgressIndicator         *progressIndicator;
    IBOutlet    NSTextField                 *textField_progress;

	NSSearchField		*searchField_logs;
	
	NSTableColumn		*selectedColumn;		//Selected/active sort column
	
	//Search information
    int					activeSearchID;			//ID of the active search thread, all other threads should quit
    NSLock				*searchingLock;			//Locked when a search is in progress
    BOOL				searching;				//YES if a search is in progress
    NSString			*activeSearchString;	//Current search string
	
    BOOL				sortDirection;			//Direction to sort

	
	NSTimer					*refreshResultsTimer;
	
	NSString				*filterForAccountName ;	//Account name to restrictively match content searches
	NSString				*filterForContactName;	//Contact name to restrictively match content searches
	
	NSMutableDictionary		*logToGroupDict;
	NSMutableDictionary		*logFromGroupDict;

	BOOL				automaticSearch;		//YES if this search was performed automatically for the user (view ___'s logs...)
    BOOL				ignoreSelectionChange;	//Hack to prevent automatic table selection changes from clearing the automaticSearch flag
    BOOL				windowIsClosing;		//YES only if windowShouldClose: has been called, to prevent actions after that point

	NSMutableDictionary	*toolbarItems;
    NSImage				*blankImage;
	
	NSMutableArray		*fromArray;				//Array of account names
    NSMutableArray		*fromServiceArray;		//Array of services for accounts
    NSMutableArray		*toArray;				//Array of contacts
    NSMutableArray		*toServiceArray;		//Array of services for accounts
    NSDateFormatter		*dateFormatter;			//Format for dates displayed in the table
	
	
    int					sameSelection;
    BOOL				useSame;
	
}

+ (id)openForPlugin:(id)inPlugin;
+ (id)openForContact:(AIListContact *)inContact plugin:(id)inPlugin;
+ (id)openLogAtPath:(NSString *)inPath plugin:(id)inPlugin;
+ (id)existingWindowController;
+ (void)closeSharedInstance;

- (void)stopSearching;

- (void)determineToAndFromGroupDicts;
- (void)displayLog:(AIChatLog *)log;
- (void)installToolbar;

- (void)setSearchMode:(LogSearchMode)inMode;
- (void)setSearchString:(NSString *)inString;
- (IBAction)updateSearch:(id)sender;

- (void)searchComplete;
- (void)startSearchingClearingCurrentResults:(BOOL)clearCurrentResults;

- (void)refreshResults;
- (void)resortLogs;
- (void)selectFirstLog;
- (void)selectDisplayedLog;
- (void)refreshResults;
- (void)refreshResultsSearchIsComplete:(BOOL)searchIsComplete;
- (void)updateProgressDisplay;

- (NSMutableString *)progressString;

@end

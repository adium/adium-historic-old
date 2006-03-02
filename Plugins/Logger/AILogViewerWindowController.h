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

#import "AILoggerPlugin.h"
#import <Adium/AIWindowController.h>

#define	KEY_LOG_VIEWER_EMOTICONS			@"Log Viewer Emoticons"
#define	KEY_LOG_VIEWER_DRAWER_STATE			@"Log Viewer Drawer State"
#define	KEY_LOG_VIEWER_DRAWER_SIZE			@"Log Viewer Drawer Size"
#define KEY_LOG_VIEWER_SELECTED_COLUMN		@"Log Viewer Selected Column Identifier"
#define	LOG_VIEWER_DID_CREATE_LOG_ARRAYS	@"LogViewerDidCreateLogArrays"

@class AIAlternatingRowOutlineView, AIListContact, AILoggerPlugin, AIChatLog;

typedef enum {
    LOG_SEARCH_FROM = 0,
    LOG_SEARCH_TO,
    LOG_SEARCH_DATE,
    LOG_SEARCH_CONTENT
} LogSearchMode;

@interface AILogViewerWindowController : AIWindowController {
    AILoggerPlugin							*plugin;
	
    IBOutlet	NSTableView                 *tableView_results;
    IBOutlet	NSTextView                  *textView_content;
    IBOutlet    id                          searchField_logs;       //May be an NSSearchField or an NSTextField
    IBOutlet    NSProgressIndicator         *progressIndicator;
    IBOutlet    NSTextField                 *textField_progress;
    IBOutlet    NSButton                    *button_deleteLogs;
    IBOutlet    NSView                      *view_SearchField;
    IBOutlet    NSView                      *view_emoteToggle;
    IBOutlet    NSButton                    *button_emoticonToggle;
    IBOutlet    NSDrawer                    *drawer_contacts;
    IBOutlet    NSTextField                 *textField_totalAccounts;
    IBOutlet    NSTextField                 *textField_totalContacts;
	
    //Misc
    //NSMutableArray		*availableLogArray;		//Array/tree of all available logs
    NSMutableArray		*fromArray;				//Array of account names
    NSMutableArray		*fromServiceArray;		//Array of services for accounts
    NSMutableArray		*toArray;				//Array of contacts
    NSMutableArray		*toServiceArray;		//Array of services for accounts
    NSTableColumn		*selectedColumn;		//Selected/active sort column
    BOOL				sortDirection;			//Direction to sort
    LogSearchMode		searchMode;				//Currently selected search mode
    NSDateFormatter		*dateFormatter;			//Format for dates displayed in the table
    BOOL				automaticSearch;		//YES if this search was performed automatically for the user (view ___'s logs...)
    BOOL				ignoreSelectionChange;	//Hack to prevent automatic table selection changes from clearing the automaticSearch flag
    BOOL				showEmoticons;			//Flag for whether or not to process emoticons
    BOOL				windowIsClosing;		//YES only if windowShouldClose: has been called, to prevent actions after that point

	//Array of selected / displayed logs.  (Locked access)
    NSMutableArray		*selectedLogArray;		//Array of filtered/resulting logs
    NSLock				*resultsLock;			//Lock before touching the array
    AIChatLog			*displayedLog;			//Currently selected/displayed log
	
    //Search information
    int					activeSearchID;			//ID of the active search thread, all other threads should quit
    NSLock				*searchingLock;			//Locked when a search is in progress
    BOOL				searching;				//YES if a search is in progress
    NSString			*activeSearchString;	//Current search string
    NSString			*activeSearchStringEncoded;	//Current search string encoded into HTML
	
	//Used to update a content search as the index updates
    NSTimer				*aggregateLogIndexProgressTimer; 
	
    NSMutableDictionary	*toolbarItems;
    NSImage				*blankImage;
    
    int					sameSelection;
    BOOL				useSame;
	
	NSMutableDictionary		*logToGroupDict;
	NSTimer					*refreshResultsTimer;
}

+ (id)openForPlugin:(id)inPlugin;
+ (id)openForContact:(AIListContact *)inContact plugin:(id)inPlugin;
+ (id)existingWindowController;
- (IBAction)updateSearch:(id)sender;
- (IBAction)selectSearchType:(id)sender;
- (IBAction)deleteAllLogs:(id)sender;
- (IBAction)deleteSelectedLog:(id)sender;
- (IBAction)toggleEmoticonFiltering:(id)sender;
- (void)setSearchString:(NSString *)inString mode:(LogSearchMode)inMode;
- (void)setSearchMode:(LogSearchMode)inMode;
- (void)setSearchString:(NSString *)inString;
- (NSMutableArray *)fromArray;
- (NSMutableArray *)toServiceArray;
- (NSMutableArray *)fromServiceArray;
- (NSMutableArray *)toArray;

- (void)filterForContactName:(NSString *)inContactName;
- (void)filterForAccountName:(NSString *)inAccountName;

- (void)rebuildIndices;

- (void)searchComplete;
- (void)stopSearching;

@end

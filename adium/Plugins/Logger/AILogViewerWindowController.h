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

@class AIAlternatingRowOutlineView, AIListContact, AILoggerPlugin, AILog;

typedef enum {
    LOG_SEARCH_FROM = 0,
    LOG_SEARCH_TO,
    LOG_SEARCH_DATE,
    LOG_SEARCH_CONTENT
} LogSearchMode;

@interface AILogViewerWindowController : AIWindowController {
    AILoggerPlugin				*plugin;

    IBOutlet	NSTableView			*tableView_results;
    IBOutlet	NSTextView			*textView_content;
    IBOutlet    id				searchField_logs;       //May be an NSSearchField or an NSTextField
    IBOutlet    NSPopUpButton			*popUp_jagSearchMode;   //Used in the jag log viewer to select search mode
    IBOutlet    NSProgressIndicator		*progressIndicator;
    IBOutlet    NSTextField			*textField_progress;

    //Misc
    NSMutableArray      *availableLogArray;     //Array/tree of all available logs
    NSTableColumn       *selectedColumn;	//Selected/active sort column
    BOOL		sortDirection;		//Direction to sort
    LogSearchMode       searchMode;		//Currently selected search mode
    NSDateFormatter     *dateFormatter;		//Format for dates displayed in the table
    BOOL		automaticSearch;	//YES if this search was performed automatically for the user (view ___'s logs...)
    BOOL		ignoreSelectionChange;  //Hack to prevent automatic table selectin changes from clearing the automaticSearch flag

    //Search information
    int			activeSearchID;		//ID of the active search thread, all other threads should quit
    NSLock		*searchingLock;		//Locked when a search is in progress
    BOOL		searching;		//YES if a search is in progress
    NSString		*activeSearchString;    //Current search string
    
    //Array of selected / displayed logs.  (Locked access)
    NSMutableArray      *selectedLogArray;      //Array of filtered/resulting logs
    NSLock		*resultsLock;		//Lock before touching the array
    AILog		*displayedLog;		//Currently selected/displayed log

}

+ (id)openForPlugin:(id)inPlugin;
+ (id)openForContact:(AIListContact *)inContact plugin:(id)inPlugin;
+ (id)existingWindowController;
- (IBAction)closeWindow:(id)sender;
- (IBAction)updateSearch:(id)sender;
- (IBAction)selectSearchType:(id)sender;

@end

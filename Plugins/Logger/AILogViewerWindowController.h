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
#import "AIAbstractLogViewerWindowController.h"

#define	KEY_LOG_VIEWER_EMOTICONS			@"Log Viewer Emoticons"
#define	KEY_LOG_VIEWER_DRAWER_STATE			@"Log Viewer Drawer State"
#define	KEY_LOG_VIEWER_DRAWER_SIZE			@"Log Viewer Drawer Size"

@class AIAlternatingRowOutlineView, AIListContact, AILoggerPlugin, AIChatLog;

@interface AILogViewerWindowController : AIAbstractLogViewerWindowController {
    IBOutlet    NSDrawer                    *drawer_contacts;
    IBOutlet    NSTextField                 *textField_totalAccounts;
    IBOutlet    NSTextField                 *textField_totalContacts;
	
    //Misc
    //NSMutableArray		*availableLogArray;		//Array/tree of all available logs
	
    NSString			*activeSearchStringEncoded;	//Current search string encoded into HTML
	
	//Used to update a content search as the index updates
    NSTimer				*aggregateLogIndexProgressTimer; 
	
	NSString				*filterForAccountName ;	//Account name to restrictively match content searches
	NSString				*filterForContactName;	//Contact name to restrictively match content searches
}

- (IBAction)deleteAllLogs:(id)sender;
- (IBAction)deleteSelectedLog:(id)sender;
- (NSMutableArray *)fromArray;
- (NSMutableArray *)toServiceArray;
- (NSMutableArray *)fromServiceArray;
- (NSMutableArray *)toArray;

- (void)filterForContactName:(NSString *)inContactName;
- (void)filterForAccountName:(NSString *)inAccountName;

- (void)rebuildIndices;

- (void)_logFilter:(NSString *)searchString searchID:(int)searchID mode:(LogSearchMode)mode;

@end

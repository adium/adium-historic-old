/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2003, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

/*
 * $Revision: 1.5 $
 * $Date: 2003/12/22 06:28:01 $
 * $Author: jmelloy $
 */

#import "libpq-fe.h"

@class AIAlternatingRowOutlineView, AIListContact;

@interface JMSQLLogViewerWindowController : AIWindowController {
    IBOutlet	AIAlternatingRowOutlineView	*outlineView_contacts;
    IBOutlet	NSTableView			*tableView_results;
    IBOutlet	NSTextView			*textView_content;

    NSMutableArray	*availableLogArray;
    NSMutableArray	*selectedLogArray;

    NSTableColumn	*selectedColumn;
    BOOL		sortDirection;

	NSString	*username;
	NSString	*url;
	NSString	*port;
	NSString	*database;
	NSString	*password;	
	
    PGconn		*conn;
}

+ (id)logViewerWindowController;
- (IBAction)closeWindow:(id)sender;
- (void)showLogsForContact:(AIListContact *)contact;

@end

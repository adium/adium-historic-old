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

@interface AILogImporter : AIWindowController {
    IBOutlet	NSTableView		*tableView_userList;
    
    IBOutlet	NSPanel			*panel_progress;
    IBOutlet	NSTextField		*textField_Goal;
    IBOutlet	NSTextField		*textField_Progress;
    IBOutlet	NSProgressIndicator	*progress_working;

    //
    NSArray		*availableUsers;
    NSMutableArray	*usersToImport;
    NSTimer		*importTimer;
    
    //Adium 1.6 import
    NSMutableArray	*sourcePathArray;
    NSMutableArray	*destPathArray;
    NSEnumerator	*sourcePathEnumerator;
    NSEnumerator	*destPathEnumerator;
}

+ (id)logImporter;
- (IBAction)closeWindow:(id)sender;

- (IBAction)importLogs:(id)sender;

@end

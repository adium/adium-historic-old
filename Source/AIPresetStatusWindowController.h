/* 
Adium, Copyright 2001-2005, Adam Iser
 
 This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 General Public License as published by the Free Software Foundation; either version 2 of the License,
 or (at your option) any later version.
 
 This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 Public License for more details.
 
 You should have received a copy of the GNU General Public License along with this program; if not,
 write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import <Cocoa/Cocoa.h>

@interface AIPresetStatusWindowController : AIWindowController {
	IBOutlet	NSButton			*button_editState;
	IBOutlet	NSButton			*button_deleteState;
	IBOutlet	NSTableView			*tableView_stateList;
	IBOutlet	AIAutoScrollView	*scrollView_stateList;

	NSArray				*stateArray;
	AIStatus		*tempDragState;
}

+ (AIPresetStatusWindowController *)presetStatusWindowController;

- (void)configureStateList;
- (void)updateControlAvailability;

- (IBAction)editState:(id)sender;
- (IBAction)deleteState:(id)sender;
- (IBAction)newState:(id)sender;

- (void)stateArrayChanged:(NSNotification *)notification;

@end

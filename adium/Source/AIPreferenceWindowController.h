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

#import <Cocoa/Cocoa.h>

@class AIAdium, AIPreferenceViewController;

@interface AIPreferenceWindowController : NSWindowController {
    IBOutlet	NSTabView	*tabView_category;
    
    IBOutlet	NSView		*view_Accounts_Connections;
    IBOutlet	NSView		*view_Accounts_Profile;
    IBOutlet	NSView		*view_Accounts_Hosts;
    IBOutlet	NSView		*view_ContactList_General;
    IBOutlet	NSView		*view_ContactList_Display;
    IBOutlet	NSView		*view_Messages_Display;
    IBOutlet	NSView		*view_Messages_Sending;
    IBOutlet	NSView		*view_Messages_Receiving;
    IBOutlet	NSView		*view_Status_Away;
    IBOutlet	NSView		*view_Status_Idle;
    IBOutlet	NSView		*view_Dock;
    IBOutlet	NSView		*view_Sound;

    AIAdium			*owner;
    NSMutableDictionary		*toolbarItems;

    
}

+ (AIPreferenceWindowController *)preferenceWindowControllerWithOwner:(id)inOwner;
+ (void)closeSharedInstance;
- (IBAction)closeWindow:(id)sender;
- (void)showView:(AIPreferenceViewController *)inView;

@end

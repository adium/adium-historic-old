/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2002, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

#import "AIContactListEditorPlugin.h"
#import "AIContactListEditorWindowController.h"
#import "AIAdium.h"
#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>

@implementation AIContactListEditorPlugin

- (void)installPlugin
{
    AIMiniToolbarItem	*toolbarItem;
    NSMenuItem		*menuItem;

    //Install the 'edit contact list' menu item
    menuItem = [[[NSMenuItem alloc] initWithTitle:@"Edit Contact List" target:self action:@selector(showContactListEditor:) keyEquivalent:@""] autorelease];
    [[owner menuController] addMenuItem:menuItem toLocation:LOC_Adium_Preferences];

    //Register our toolbar item
    toolbarItem = [[AIMiniToolbarItem alloc] initWithIdentifier:@"EditContactList"];
    [toolbarItem setImage:[AIImageUtilities imageNamed:@"AIMsettings" forClass:[self class]]];
    [toolbarItem setTarget:self];
    [toolbarItem setAction:@selector(showContactListEditor:)];
    [toolbarItem setToolTip:@"Edit contact list"];
    [toolbarItem setPaletteLabel:@"Edit contact list"];
    [toolbarItem setEnabled:YES];
    [[AIMiniToolbarCenter defaultCenter] registerItem:[toolbarItem autorelease]];
}

//Show the contact list editor window
- (IBAction)showContactListEditor:(id)sender
{
    [[AIContactListEditorWindowController contactListEditorWindowControllerWithOwner:owner] showWindow:nil];
}

@end

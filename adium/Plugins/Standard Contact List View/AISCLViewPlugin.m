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

#import <Adium/Adium.h>
#import "AISCLViewPlugin.h"
#import "AISCLCell.h"
#import "AISCLOutlineView.h"
#import "AIAdium.h"
#import "AICLPreferences.h"
#import "AISCLViewController.h"

@interface AISCLViewPlugin (PRIVATE)
@end

@implementation AISCLViewPlugin

- (void)installPlugin
{
    controllerArray = [[NSMutableArray alloc] init];

    //Register ourself as an available contact list view
    [[owner interfaceController] registerContactListViewController: self];

    //Register our default preferences
    [[owner preferenceController] registerDefaults:[NSDictionary dictionaryNamed:SCL_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_CONTACT_LIST];

    //Install the preference view
    preferences = [[AICLPreferences contactListPreferencesWithOwner:owner] retain];
}

- (void)uninstallPlugin
{
    //[[owner interfaceController] unregisterContactListViewController: self];
}

- (void)dealloc
{
    [controllerArray release];

    [super dealloc];
}

//Return a new contact list view
- (NSView *)contactListView
{
    AISCLViewController	*controller = [AISCLViewController contactListViewControllerWithOwner:owner];

    [controllerArray addObject:controller];

    return([controller contactListView]);
}

//Close a contact list view
- (void)closeContactListView:(NSView *)inView
{
    NSEnumerator	*enumerator;
    AISCLViewController	*controller;

    //Remove the view from our array
    enumerator = [controllerArray objectEnumerator];
    while((controller = [enumerator nextObject])){
        if([controller contactListView] == inView){
            [controllerArray removeObject:controller];
            return; //We've found and removed our view, return.
        }
    }
}


@end






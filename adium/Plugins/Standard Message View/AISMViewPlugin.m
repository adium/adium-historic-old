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

#import <AIUtilities/AIUtilities.h>
#import <Adium/Adium.h>
#import "AISMViewPlugin.h"
#import "AIAdium.h"
#import "AISMViewController.h"
#import "AISMPreferences.h"

#define SMV_DEFAULT_PREFS	@"SMVDefaults"

@implementation AISMViewPlugin

- (void)installPlugin
{
    controllerArray = [[NSMutableArray alloc] init];
    
    [[owner interfaceController] registerMessageViewController:self];

    //Register our default preferences
    [[owner preferenceController] registerDefaults:[NSDictionary dictionaryNamed:SMV_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_STANDARD_MESSAGE_DISPLAY];

    //Install the preference view
    preferences = [[AISMPreferences messageViewPreferencesWithOwner:owner] retain];
}

- (void)uninstallPlugin
{
    //[[owner interfaceController] unregisterMessageViewController:self];
}

//returns a NEW message view configured for the specified handle
- (NSView *)messageViewForContact:(AIListContact *)inContact
{
    AISMViewController	*controller = [AISMViewController messageViewControllerForContact:inContact owner:owner];

    [controllerArray addObject:controller];

    return([controller messageView]);
}

- (void)closeMessageView:(NSView *)inView
{
    NSEnumerator	*enumerator;
    AISMViewController	*controller;

    //Remove the view from our array
    enumerator = [controllerArray objectEnumerator];
    while((controller = [enumerator nextObject])){
        if([controller messageView] == inView){
	    
            [controllerArray removeObject:controller];
            return; //We've found and removed our view, return.
        }
    }
}

@end










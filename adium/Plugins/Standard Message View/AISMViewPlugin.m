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

#import "AISMViewPlugin.h"
#import "AISMViewController.h"
#import "AISMPreferences.h"

#define SMV_DEFAULT_PREFS	@"SMVDefaults"

@implementation AISMViewPlugin

- (void)installPlugin
{
    //Register ourself as a message list view plugin
    [[owner interfaceController] registerMessageViewPlugin:self];

    //Register our default preferences and install our preference view
    [[owner preferenceController] registerDefaults:[NSDictionary dictionaryNamed:SMV_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_STANDARD_MESSAGE_DISPLAY];
    preferences = [[AISMPreferences messageViewPreferencesWithOwner:owner] retain];
}

//Return a message view controller
- (id <AIMessageViewController>)messageViewControllerForChat:(AIChat *)inChat
{
    return([AISMViewController messageViewControllerForChat:inChat owner:owner]);
}

@end










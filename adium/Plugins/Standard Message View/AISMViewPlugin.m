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

@implementation AISMViewPlugin

#define SMV_THEMABLE_PREFS      @"SMV Themable Prefs"

- (void)installPlugin
{
    //Register ourself as a message list view plugin
    [[adium interfaceController] registerMessageViewPlugin:self];

    //Register our default preferences and install our preference view
    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:SMV_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_STANDARD_MESSAGE_DISPLAY];
    preferences = [[AISMPreferences preferencePane] retain];
    
    //Register themable preferences
    [[adium preferenceController] registerThemableKeys:[NSArray arrayNamed:SMV_THEMABLE_PREFS forClass:[self class]] forGroup:PREF_GROUP_STANDARD_MESSAGE_DISPLAY];
        
    //Set up a time stamp format based on this user's locale
    NSString    *format = [[[adium preferenceController] preferencesForGroup:PREF_GROUP_STANDARD_MESSAGE_DISPLAY] objectForKey:KEY_SMV_TIME_STAMP_FORMAT];
    if(!format || [format length] == 0){
        [[adium preferenceController] setPreference:[NSDateFormatter localizedDateFormatStringShowingSeconds:NO showingAMorPM:NO]
                                             forKey:KEY_SMV_TIME_STAMP_FORMAT
                                              group:PREF_GROUP_STANDARD_MESSAGE_DISPLAY];
    }
}

//Return a message view controller
- (id <AIMessageViewController>)messageViewControllerForChat:(AIChat *)inChat
{
    return([AISMViewController messageViewControllerForChat:inChat]);
}

@end


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

#import "AISendingKeyPreferencesPlugin.h"
#import "AISendingKeyPreferences.h"

@interface AISendingKeyPreferencesPlugin (PRIVATE)
- (void)preferencesChanged:(NSNotification *)notification;
- (void)_configureSendingKeysForObject:(id)inObject;
@end

@implementation AISendingKeyPreferencesPlugin

- (void)installPlugin
{
    //Setup our preferences
    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:SENDING_KEY_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_GENERAL];
    preferences = [[AISendingKeyPreferences preferencePane] retain];
    
    //Register as a text entry filter
    [[adium contentController] registerTextEntryFilter:self];

    //Observe preference changes
    [[adium notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    [self preferencesChanged:nil];

}

//
- (void)didOpenTextEntryView:(NSText<AITextEntryView> *)inTextEntryView
{
    [self _configureSendingKeysForObject:inTextEntryView]; //Configure the sending keys
}

//
- (void)willCloseTextEntryView:(NSText<AITextEntryView> *)inTextEntryView
{
    //Ignore
}

//Update all views in response to a preference change
- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_GENERAL] == 0){
        NSEnumerator	*enumerator;
        id		entryView;

        //Set sending keys of all open views
        enumerator = [[[adium contentController] openTextEntryViews] objectEnumerator];
        while(entryView = [enumerator nextObject]){
            [self _configureSendingKeysForObject:entryView];
        }
    }
}

//Configure the message sending keys
- (void)_configureSendingKeysForObject:(id)inObject
{
    if([inObject isKindOfClass:[AISendingTextView class]]){
        [(AISendingTextView *)inObject setSendOnReturn:[[[[adium preferenceController] preferencesForGroup:PREF_GROUP_GENERAL] objectForKey:@"Send On Return"] boolValue]];
		[(AISendingTextView *)inObject setSendOnEnter:[[[[adium preferenceController] preferencesForGroup:PREF_GROUP_GENERAL] objectForKey:@"Send On Enter"] boolValue]];
    }
}

@end



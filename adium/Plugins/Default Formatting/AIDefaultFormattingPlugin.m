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

#import "AIDefaultFormattingPlugin.h"
#import <AIUtilities/AIUtilities.h>
#import <Adium/Adium.h>
#import "AIAdium.h"
#import "AIDefaultFormattingPreferences.h"

#define DEFAULT_FORMATTING_DEFAULT_PREFS	@"FormattingDefaults"

@interface AIDefaultFormattingPlugin (PRIVATE)
- (void)preferencesChanged:(NSNotification *)notification;
- (void)_resetFormattingInView:(NSText<AITextEntryView> *)inTextEntryView;
@end

@implementation AIDefaultFormattingPlugin

- (void)installPlugin
{
    //Register as an entry filter
    [[owner contentController] registerTextEntryFilter:self];

    //Register our default preferences
    [[owner preferenceController] registerDefaults:[NSDictionary dictionaryNamed:DEFAULT_FORMATTING_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_FORMATTING];

    //Our preference view
    preferences = [[AIDefaultFormattingPreferences preferencePaneWithOwner:owner] retain];

    //Observe
    [[owner notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    [self preferencesChanged:nil];
}

- (void)didOpenTextEntryView:(NSText<AITextEntryView> *)inTextEntryView
{
    [self _resetFormattingInView:inTextEntryView]; //Set the formatting to default
}

- (void)willCloseTextEntryView:(NSText<AITextEntryView> *)inTextEntryView
{
    //Ignored
}

- (void)preferencesChanged:(NSNotification *)notification
{
/*    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_DOCK_BEHAVIOR] == 0){
        NSDictionary	*preferenceDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_DOCK_BEHAVIOR];

    }*/
}



// Private --------------------------------------------------------------------------
//Resets all the text in an entry view to the default values
- (void)_resetFormattingInView:(NSText<AITextEntryView> *)inTextEntryView
{
    NSMutableAttributedString	*contents;
    NSDictionary		*prefDict;
    NSDictionary		*attributes;
    NSColor			*textColor;
    NSColor			*backgroundColor;
    NSColor			*subBackgroundColor;
    NSFont			*font;

    //Get the prefs
    prefDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_FORMATTING];
    font = [[prefDict objectForKey:KEY_FORMATTING_FONT] representedFont];
    textColor = [[prefDict objectForKey:KEY_FORMATTING_TEXT_COLOR] representedColor];
    backgroundColor = [[prefDict objectForKey:KEY_FORMATTING_BACKGROUND_COLOR] representedColor];
    subBackgroundColor = [[prefDict objectForKey:KEY_FORMATTING_SUBBACKGROUND_COLOR] representedColor];

    //Setup the attributes
    if(!subBackgroundColor){
        attributes = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, textColor, NSForegroundColorAttributeName, backgroundColor, AIBodyColorAttributeName, nil];
    }else{
        attributes = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, textColor, NSForegroundColorAttributeName, backgroundColor, AIBodyColorAttributeName, subBackgroundColor, NSBackgroundColorAttributeName, nil];
    }

    //Set them as the typing attributes for all new text
    [inTextEntryView setTypingAttributes:attributes];

    //Apply the attributes to the existing content
    contents = [[[inTextEntryView attributedString] mutableCopy] autorelease];
    [contents setAttributes:attributes range:NSMakeRange(0,[contents length])];
    [inTextEntryView setAttributedString:contents];
}


@end

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
    [[adium contentController] registerTextEntryFilter:self];

    //Register our default preferences
    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:DEFAULT_FORMATTING_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_FORMATTING];

    //Our preference view
    preferences = [[AIDefaultFormattingPreferences preferencePane] retain];

    //Observe
    [[adium notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
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
    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_FORMATTING] == 0){
		NSDictionary		*prefDict;
		NSMutableDictionary *attributes;
		NSColor				*textColor;
		NSColor				*backgroundColor;
		NSColor				*subBackgroundColor;
		NSFont				*font;
				
		//Get the prefs
		prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_FORMATTING];
		font = [[prefDict objectForKey:KEY_FORMATTING_FONT] representedFont];
		textColor = [[prefDict objectForKey:KEY_FORMATTING_TEXT_COLOR] representedColor];
		backgroundColor = [[prefDict objectForKey:KEY_FORMATTING_BACKGROUND_COLOR] representedColor];
		subBackgroundColor = [[prefDict objectForKey:KEY_FORMATTING_SUBBACKGROUND_COLOR] representedColor];

		attributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, nil];
		
		//Setup the attributes; don't include colors which match the systemwide defaults
		if (backgroundColor && ![backgroundColor equalToRGBColor:[NSColor textBackgroundColor]]){
			[attributes setObject:backgroundColor forKey:AIBodyColorAttributeName];	
		}
		if(subBackgroundColor){
			[attributes setObject:subBackgroundColor forKey:NSBackgroundColorAttributeName];
		}
		if (textColor && ![textColor equalToRGBColor:[NSColor textColor]]){
			[attributes setObject:textColor forKey:NSForegroundColorAttributeName];	
		}

		[[adium contentController] setDefaultFormattingAttributes:attributes];
    }
}



// Private --------------------------------------------------------------------------
//Resets all the text in an entry view to the default values
- (void)_resetFormattingInView:(NSText<AITextEntryView> *)inTextEntryView
{
    NSMutableAttributedString	*contents;
    NSDictionary				*attributes;

	attributes = [[adium contentController] defaultFormattingAttributes];
	
    //Set them as the typing attributes for all new text
    [inTextEntryView setTypingAttributes:attributes];

    //Apply the attributes to the existing content
    contents = [[[inTextEntryView attributedString] mutableCopy] autorelease];
    [contents setAttributes:attributes range:NSMakeRange(0,[contents length])];
    [inTextEntryView setAttributedString:contents];
}


@end

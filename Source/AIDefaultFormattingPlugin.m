/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "AIContentController.h"
#import "AIDefaultFormattingPlugin.h"
#import "AIInterfaceController.h"
#import "AIMenuController.h"
#import "AIPreferenceController.h"
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIColorAdditions.h>
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AIFontAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AITextAttributes.h>
#import <Adium/AIContentMessage.h>

#define DEFAULT_FORMATTING_DEFAULT_PREFS	@"FormattingDefaults"

@protocol AITextEntryView;

@interface AIDefaultFormattingPlugin (PRIVATE)
- (void)preferencesChanged:(NSNotification *)notification;
- (void)_resetFormattingInView:(NSText<AITextEntryView> *)inTextEntryView;
@end

@implementation AIDefaultFormattingPlugin

/*!
 * @brief Install the default formatting plugin
 */
- (void)installPlugin
{
    //Preferences
    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:DEFAULT_FORMATTING_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_FORMATTING];
	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_FORMATTING];

	//Reset formatting menu item
	NSMenuItem	*menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:AILocalizedString(@"Restore Default Formatting",nil)
																				  target:self
																				  action:@selector(restoreDefaultFormat:)
																		   keyEquivalent:@""] autorelease];
    [[adium menuController] addMenuItem:menuItem toLocation:LOC_Format_Additions];
	
	//Register as an entry filter, so we can prepare textviews as they open
    [[adium contentController] registerTextEntryFilter:self];

	//Observe content sending so we can save the user's formatting
    [[adium notificationCenter] addObserver:self
                                   selector:@selector(didSendContent:)
                                       name:CONTENT_MESSAGE_SENT
                                     object:nil];
}

/*!
 * @brief Invoked when formatting preferences change
 */
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	NSMutableDictionary	*attributes;
	
	//Update our local preference cache for the new values
	[font release];
	[textColor release];
	font = [[[prefDict objectForKey:KEY_FORMATTING_FONT] representedFont] retain];
	textColor = [[[prefDict objectForKey:KEY_FORMATTING_TEXT_COLOR] representedColor] retain];
	
	//Apply the new preferences as Adium's default formatting attributes
	attributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, nil];
	if(textColor && ![textColor equalToRGBColor:[NSColor textColor]]){
		[attributes setObject:textColor forKey:NSForegroundColorAttributeName];	
	}	
	[[adium contentController] setDefaultFormattingAttributes:attributes];
}

/*!
 * @brief Invoked when a text entry view opens, set it to our default formatting
 */
- (void)didOpenTextEntryView:(NSText<AITextEntryView> *)inTextEntryView
{
	[self _resetFormattingInView:inTextEntryView];
}

/*!
 * @brief Invoked when a text entry view closes
 */
- (void)willCloseTextEntryView:(NSText<AITextEntryView> *)inTextEntryView
{
    //Ignored
}

/*!
 * @brief Invoked when content is sent, remember the text formatting used
 */
- (void)didSendContent:(NSNotification *)notification
{
    AIContentObject	*content = [[notification userInfo] objectForKey:@"AIContentObject"];

    if(content && [[content type] isEqualToString:CONTENT_MESSAGE_TYPE]){
		NSAttributedString	*message = [content message];
		
		if([message length] > 0) {
			NSDictionary	*attributes = [message attributesAtIndex:[message length]-1 effectiveRange:nil];
			NSString		*newFont = [(NSFont *)[attributes objectForKey:NSFontAttributeName] stringRepresentation];
			NSString		*newTextColor = [(NSColor *)[attributes objectForKey:NSForegroundColorAttributeName] stringRepresentation];
			
			//If the attribute is nil for these values, substitute our defaults
			if(!newFont) newFont = [[adium preferenceController] defaultPreferenceForKey:KEY_FORMATTING_FONT
																				   group:PREF_GROUP_FORMATTING
																				  object:nil];
			if(!newTextColor) newTextColor = [[adium preferenceController] defaultPreferenceForKey:KEY_FORMATTING_TEXT_COLOR 
																							 group:PREF_GROUP_FORMATTING
																							object:nil];
			
			//Save the new formatting (if it's changed)
			if(![[font stringRepresentation] isEqualToString:newFont]){
				NSLog(@"newfont:%@  (was %@)",newFont,[font stringRepresentation]);
				[[adium preferenceController] setPreference:newFont
													 forKey:KEY_FORMATTING_FONT
													  group:PREF_GROUP_FORMATTING];
			}
			if(![[textColor stringRepresentation] isEqualToString:newTextColor]){
				NSLog(@"newcolor:%@ (was %@)",newTextColor,[textColor stringRepresentation]);
				[[adium preferenceController] setPreference:newTextColor
													 forKey:KEY_FORMATTING_TEXT_COLOR
													  group:PREF_GROUP_FORMATTING];
			}
		}
	}
}


/*!
 * @brief Restore text formatting to default in all message windows
 */
- (void)restoreDefaultFormat:(id)sender
{
	//Reset formatting to default
	[[adium preferenceController] setPreference:nil
										 forKey:KEY_FORMATTING_FONT
										  group:PREF_GROUP_FORMATTING];
	[[adium preferenceController] setPreference:nil
										 forKey:KEY_FORMATTING_TEXT_COLOR
										  group:PREF_GROUP_FORMATTING];
	
	//Update all open message windows to our default formatting
	NSEnumerator	*enumerator = [[[adium contentController] openTextEntryViews] objectEnumerator];
	NSText<AITextEntryView> *textEntryView;
	
	while(textEntryView = [enumerator nextObject]){
		[self _resetFormattingInView:textEntryView];
	}	
}

/*!
 * @brief Resets all the text in an entry view to the default values
 */
- (void)_resetFormattingInView:(NSText<AITextEntryView> *)inTextEntryView
{
    NSMutableAttributedString	*contents;
    NSDictionary				*attributes;

	attributes = [[adium contentController] defaultFormattingAttributes];
	
    //Set them as the typing attributes for all new text
    [inTextEntryView setTypingAttributes:attributes];

    //Apply the attributes to the existing content
    contents = [[inTextEntryView attributedString] mutableCopy];
    [contents setAttributes:attributes range:NSMakeRange(0,[contents length])];
    [inTextEntryView setAttributedString:contents];
	[contents release];
}

@end

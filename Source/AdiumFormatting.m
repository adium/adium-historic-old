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
#import "AIPreferenceController.h"
#import "AdiumFormatting.h"
#import <AIUtilities/AIColorAdditions.h>
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AIFontAdditions.h>
#import <AIUtilities/AITextAttributes.h>

#define DEFAULT_FORMATTING_DEFAULT_PREFS	@"FormattingDefaults"

@implementation AdiumFormatting

/*!
 * @brief Init
 */
- (id)init
{
	if ((self = [super init])) {
		[[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:DEFAULT_FORMATTING_DEFAULT_PREFS
																			forClass:[self class]]
											  forGroup:PREF_GROUP_FORMATTING];		
		_defaultAttributes = nil;
	}
	
	return self;
}

/*!
 * @brief Finish Initing
 *
 * Requires:
 * 1) Preference controller is ready
 */
- (void)controllerDidLoad
{
	//Observe formatting preference changes
	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_FORMATTING];
}

/*!
 * @brief Dealloc
 */
- (void)dealloc
{
	[[adium notificationCenter] removeObserver:self];
	[_defaultAttributes release]; _defaultAttributes = nil;
	
	[super dealloc];
}

/*
 * @brief Returns the default formatting attributes
 *
 * These attributes should be used for new text entry views, messages, etc.
 * @return NSDictionary of NSAttributedString attributes
 */
- (NSDictionary *)defaultFormattingAttributes
{
	if(!_defaultAttributes){
		NSFont	*font = [[[adium preferenceController] preferenceForKey:KEY_FORMATTING_FONT
																  group:PREF_GROUP_FORMATTING] representedFont];
		NSColor	*textColor = [[[adium preferenceController] preferenceForKey:KEY_FORMATTING_TEXT_COLOR
																	   group:PREF_GROUP_FORMATTING] representedColor];
		NSColor	*backgroundColor = [[[adium preferenceController] preferenceForKey:KEY_FORMATTING_BACKGROUND_COLOR
																			 group:PREF_GROUP_FORMATTING] representedColor];
				
		//Build formatting dict
		_defaultAttributes = [[NSMutableDictionary dictionaryWithObject:font forKey:NSFontAttributeName] retain];
		if (textColor && ![textColor equalToRGBColor:[NSColor textColor]]) {
			[_defaultAttributes setObject:textColor forKey:NSForegroundColorAttributeName];	
		}	
		if (backgroundColor && ![backgroundColor equalToRGBColor:[NSColor textBackgroundColor]]) {
			[_defaultAttributes setObject:backgroundColor forKey:AIBodyColorAttributeName];	
		}
	}
	
	return _defaultAttributes;
}

/*!
 * @brief Formatting preferences changed, reset our formatting cache
 */
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key object:(AIListObject *)object
					preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	[_defaultAttributes release];
	_defaultAttributes = nil;
}

@end

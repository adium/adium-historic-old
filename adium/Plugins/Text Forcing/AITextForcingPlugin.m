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

#import "AITextForcingPlugin.h"
#import "AITextForcingPreferences.h"

#define TEXT_FORCING_DEFAULT_PREFS	@"TextForcingDefaults"

@interface AITextForcingPlugin (PRIVATE)
- (void)filterContentObject:(AIContentObject *)inObject;
- (void)preferencesChanged:(NSNotification *)notification;
@end

@implementation AITextForcingPlugin

- (void)installPlugin
{
    //init
    forceFont = NO;
    forceText = NO;
    forceBackground = NO;
    force_desiredFont = nil;
    force_desiredTextColor = nil;
    force_desiredBackgroundColor = nil;

    //Register our default preferences
    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:TEXT_FORCING_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_TEXT_FORCING];
    [self preferencesChanged:nil];
    
    //Our preference view
    preferences = [[AITextForcingPreferences preferencePane] retain];

    //Register our content filter
    [[adium contentController] registerIncomingContentFilter:self];
    
    //Observe
    [[adium notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
}

- (NSAttributedString *)filterAttributedString:(NSAttributedString *)inAttributedString forContentObject:(AIContentObject *)inObject
{
	if(forceFont || forceText || forceBackground){
		if(inAttributedString && [inAttributedString length]){
			NSMutableAttributedString	*message = [[inAttributedString mutableCopy] autorelease];
			NSRange						range = NSMakeRange(0, [message length]);
			
			if(forceFont){
				[message addAttribute:NSFontAttributeName value:force_desiredFont range:range];
			}
			if(forceText){
				[message addAttribute:NSForegroundColorAttributeName value:force_desiredTextColor range:range];
			}
			if(forceBackground){
				//Add the forced body color and remove any 'sub-background' colors
				[message addAttribute:AIBodyColorAttributeName value:force_desiredBackgroundColor range:range];
				[message removeAttribute:NSBackgroundColorAttributeName range:NSMakeRange(0, [message length])];
			}
			
			return(message);
		}
	}
	
	return(inAttributedString);
}    

- (void)preferencesChanged:(NSNotification *)notification
{
    if([(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_TEXT_FORCING] == 0){
        NSDictionary	*prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_TEXT_FORCING];

        //Release the old values..
        [force_desiredFont release]; force_desiredFont = nil;
        [force_desiredTextColor release]; force_desiredTextColor = nil;
        [force_desiredBackgroundColor release]; force_desiredBackgroundColor = nil;

        //Cache the preference values
        forceFont = [[prefDict objectForKey:KEY_FORCE_FONT] boolValue];
        forceText = [[prefDict objectForKey:KEY_FORCE_TEXT_COLOR] boolValue];
        forceBackground = [[prefDict objectForKey:KEY_FORCE_BACKGROUND_COLOR] boolValue];

        force_desiredFont = [[[prefDict objectForKey:KEY_FORCE_DESIRED_FONT] representedFont] retain];
        force_desiredTextColor = [[[prefDict objectForKey:KEY_FORCE_DESIRED_TEXT_COLOR] representedColor] retain];
        force_desiredBackgroundColor = [[[prefDict objectForKey:KEY_FORCE_DESIRED_BACKGROUND_COLOR] representedColor] retain];
    }
}

@end






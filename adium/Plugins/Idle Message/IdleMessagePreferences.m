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

#import "IdleMessagePreferences.h"
#import "IdleMessagePlugin.h"

@interface IdleMessagePreferences (PRIVATE)
- (void)textDidEndEditing:(NSNotification *)notification;
@end

@implementation IdleMessagePreferences

//Preference pane properties
- (PREFERENCE_CATEGORY)category{
    return(AIPref_Advanced_Status);
}
- (NSString *)label{
    return(AILocalizedString(@"Idle Message",nil));
}
- (NSString *)nibName{
    return(@"IdleMessagePrefs");
}

- (NSDictionary *)restorablePreferences
{
	NSDictionary *defaultPrefs = [NSDictionary dictionaryNamed:IDLE_MESSAGE_DEFAULT_PREFS forClass:[self class]];
	NSDictionary *defaultsDict = [NSDictionary dictionaryWithObject:defaultPrefs forKey:PREF_GROUP_IDLE_MESSAGE];
	return(defaultsDict);
}

//Configure the preference view
- (void)viewDidLoad
{
    NSDictionary		*preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_IDLE_MESSAGE];
    NSAttributedString	*idleMessage = [NSAttributedString stringWithData:[[adium preferenceController] preferenceForKey:@"IdleMessage"
																												   group:GROUP_ACCOUNT_STATUS]];

    //Idle message
    [checkBox_enableIdleMessage setState:[[preferenceDict objectForKey:KEY_IDLE_MESSAGE_ENABLED] boolValue]];
    [[textView_idleMessage textStorage] setAttributedString:idleMessage];

	//This doesn't work.  Why not?
	//[[textView_idleMessage window] setInitialFirstResponder:textView_idleMessage];
    [[NSNotificationCenter defaultCenter] addObserver:textView_idleMessage selector:@selector(textDidChange:) name:NSTextDidChangeNotification object:textView_idleMessage];
}

//force the textView to save its contents when the view will close
- (void)viewWillClose
{
	[self textDidEndEditing:nil];
}

// Called in response to all preference controls, applies new settings
- (IBAction)changePreference:(id)sender
{
    if(sender == checkBox_enableIdleMessage) {
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_IDLE_MESSAGE_ENABLED
                                              group:PREF_GROUP_IDLE_MESSAGE];
    }
}

//User finished editing their idle message
- (void)textDidEndEditing:(NSNotification *)notification;
{
	NSData  *idleMessageData = [[textView_idleMessage textStorage] dataRepresentation];
	
    [[adium preferenceController] setPreference:idleMessageData 
										 forKey:@"IdleMessage"
										  group:GROUP_ACCOUNT_STATUS];
    [[adium preferenceController] setPreference:idleMessageData
                                         forKey:KEY_IDLE_MESSAGE
                                          group:PREF_GROUP_IDLE_MESSAGE];
}

@end

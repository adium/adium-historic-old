/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2004, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

#import "IdleTimePreferences.h"
#import "IdleTimePlugin.h"

#define IDLE_TIME_PREF_TITLE		AILocalizedString(@"Idle",nil)  //Title of the preference view
#define AUTO_AWAY_QUICK_AWAY_TITLE  @"Last quick away"
#define ELIPSIS_STRING				AILocalizedString(@"...",nil)

@interface IdleTimePreferences (PRIVATE)
- (void)configureView;
- (void)configureAutoAwayPreferences;
- (void)configureControlDimming;
- (void)loadAwayMessages;
- (NSMutableArray *)_loadAwaysFromArray:(NSArray *)array;
- (NSMenu *)savedAwaysMenu;
- (void)preferencesChanged:(NSNotification *)notification;
@end

@implementation IdleTimePreferences

//Preference pane properties
- (PREFERENCE_CATEGORY)category{
    return(AIPref_Status_Idle);
}
- (NSString *)label{
    return(@"Idle Time");
}
- (NSString *)nibName{
    return(@"IdleTimePrefs");
}

//Configures our view for the current preferences
- (void)viewDidLoad
{
    NSDictionary	*preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_IDLE_TIME];
	
    [checkBox_enableIdle setState:[[preferenceDict objectForKey:KEY_IDLE_TIME_ENABLED] boolValue]];
    [textField_idleMinutes setIntValue:[[preferenceDict objectForKey:KEY_IDLE_TIME_IDLE_MINUTES] intValue]];
    [checkBox_enableAutoAway setState:[[preferenceDict objectForKey:KEY_AUTO_AWAY_ENABLED] boolValue]];
    [textField_autoAwayMinutes setIntValue:[[preferenceDict objectForKey:KEY_AUTO_AWAY_IDLE_MINUTES] intValue]];
	
	[[adium notificationCenter] addObserver:self 
								   selector:@selector(preferencesChanged:)
									   name:Preference_GroupChanged 
									 object:nil];
	[self preferencesChanged:nil];
	
    [self configureControlDimming];
}

//Preference view is closing
- (void)viewWillClose
{
	[[adium notificationCenter] removeObserver:self];
}

//Enable/disable controls that are available/unavailable
- (void)configureControlDimming
{
    [textField_idleMinutes setEnabled:[checkBox_enableIdle state]];
    [stepper_idleMinutes setEnabled:[checkBox_enableIdle state]];
	[textField_autoAwayMinutes setEnabled:[checkBox_enableAutoAway state]];
	[stepper_autoAwayMinutes setEnabled:[checkBox_enableAutoAway state]];
	[popUp_title setEnabled:[checkBox_enableAutoAway state]];
}

//Called in response to all preference controls, applies new settings
- (IBAction)changePreference:(id)sender
{
    if(sender == checkBox_enableIdle){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_IDLE_TIME_ENABLED
                                              group:PREF_GROUP_IDLE_TIME];
        [self configureControlDimming];

    }else if(sender == textField_idleMinutes){
        [[adium preferenceController] setPreference:[NSNumber numberWithInt:[sender intValue]]
                                             forKey:KEY_IDLE_TIME_IDLE_MINUTES
                                              group:PREF_GROUP_IDLE_TIME];

    }else if(sender == checkBox_enableAutoAway){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_AUTO_AWAY_ENABLED
                                              group:PREF_GROUP_IDLE_TIME];
        [self configureControlDimming];

    }else if(sender == textField_autoAwayMinutes){
        [[adium preferenceController] setPreference:[NSNumber numberWithInt:[sender intValue]]
                                             forKey:KEY_AUTO_AWAY_IDLE_MINUTES
                                              group:PREF_GROUP_IDLE_TIME];

    }else if(sender == popUp_title){
		[[adium preferenceController] setPreference:[NSNumber numberWithInt:[popUp_title indexOfSelectedItem]]
											 forKey:KEY_AUTO_AWAY_MESSAGE_INDEX
											  group:PREF_GROUP_IDLE_TIME];
	}
}

//
- (void)configureAutoAwayPreferences
{
	NSDictionary	*preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_IDLE_TIME];
	[popUp_title setMenu:[self savedAwaysMenu]];
	int awayMessageIndex = [[preferenceDict objectForKey:KEY_AUTO_AWAY_MESSAGE_INDEX] intValue];
	if ((awayMessageIndex >= 0) && (awayMessageIndex < [popUp_title numberOfItems])){
		[popUp_title selectItemAtIndex:awayMessageIndex];
	}
}

//Recursively load the away messages, rebuilding the structure with mutable objects
- (NSMutableArray *)_loadAwaysFromArray:(NSArray *)array
{
    NSEnumerator	*enumerator;
    NSDictionary	*dict;
    NSMutableArray	*mutableArray = [[NSMutableArray alloc] init];

    enumerator = [array objectEnumerator];
    while((dict = [enumerator nextObject])){
        NSString	*type = [dict objectForKey:@"Type"];

        if([type isEqualToString:@"Group"]){
            [mutableArray addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                @"Group", @"Type",
                [self _loadAwaysFromArray:[dict objectForKey:@"Contents"]], @"Contents",
                [dict objectForKey:@"Name"], @"Name",
                nil]];

        }else if([type isEqualToString:@"Away"]){
            [mutableArray addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                @"Away", @"Type",
                [NSAttributedString stringWithData:[dict objectForKey:@"Message"]], @"Message",
                [dict objectForKey:@"Title"], @"Title",
                nil]];

        }
    }

    return(mutableArray);
}

//Load the away messages
- (void)loadAwayMessages
{
    NSArray	*tempArray;

    //Release any existing away array
    [awayMessageArray release];

    //Load the saved away messages
    tempArray = [[[adium preferenceController] preferencesForGroup:PREF_GROUP_AWAY_MESSAGES] objectForKey:KEY_SAVED_AWAYS];
    if(tempArray){
        //Load the aways
        awayMessageArray = [self _loadAwaysFromArray:tempArray];
    }
}

- (NSMenu *)savedAwaysMenu
{
    NSMenu		*savedAwaysMenu = [[NSMenu alloc] init];
    NSMenuItem  *menuItem;
    
	[self loadAwayMessages]; //load the away messages into awayMessageArray

    menuItem = [[[NSMenuItem alloc] initWithTitle:AUTO_AWAY_QUICK_AWAY_TITLE
											target:self
											action:nil
										keyEquivalent:@""] autorelease];
	[savedAwaysMenu addItem:menuItem];
	
	if (awayMessageArray){
		[savedAwaysMenu addItem:[NSMenuItem separatorItem]];

        NSEnumerator *enumerator = [awayMessageArray objectEnumerator];
        NSDictionary *dict;
        while(dict = [enumerator nextObject]){
            NSString * title = [dict objectForKey:@"Title"];
            if(title){
				menuItem = [[[NSMenuItem alloc] initWithTitle:title
													   target:self
													   action:nil
												keyEquivalent:@""] autorelease];
            }else{
                NSString * message = [[dict objectForKey:@"Message"] string];
				
                //Cap the away menu title (so they're not incredibly long)
                if([message length] > MENU_AWAY_DISPLAY_LENGTH){
                    message = [[message substringToIndex:MENU_AWAY_DISPLAY_LENGTH] stringByAppendingString:ELIPSIS_STRING];
                }
                
                menuItem = [[[NSMenuItem alloc] initWithTitle:message
                                                       target:self
                                                       action:nil
                                                keyEquivalent:@""] autorelease];
            }
            [menuItem setRepresentedObject:dict];
            [menuItem setEnabled:YES];
            [savedAwaysMenu addItem:menuItem];        
        }
    }        
	
    [savedAwaysMenu setAutoenablesItems:NO];
    return savedAwaysMenu;
}

- (void)preferencesChanged:(NSNotification *)notification
{
	if(notification == nil || ([[[notification userInfo] objectForKey:@"Group"] isEqualTo:PREF_GROUP_AWAY_MESSAGES] &&
							   [[[notification userInfo] objectForKey:@"Key"] isEqualTo:KEY_SAVED_AWAYS])) {
		[self configureAutoAwayPreferences];
	}
}

    
@end

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

#import "IdleTimePreferences.h"
#import "IdleTimePlugin.h"

#define IDLE_TIME_PREF_NIB          @"IdleTimePrefs"		//Name of preference nib
#define IDLE_TIME_PREF_TITLE		AILocalizedString(@"Idle",nil)  //Title of the preference view
#define AUTO_AWAY_NO_AWAYS_TITLE	@"No saved aways"   //What to display in popUp_title if no messages are saved

@interface IdleTimePreferences (PRIVATE)
- (void)configureView;
- (void)configureAutoAwayPreferences;
- (void)configureControlDimming;
- (void)loadAwayMessages;
- (NSMutableArray *)_loadAwaysFromArray:(NSArray *)array;
- (NSMenu *)savedAwaysMenu;
@end

@implementation IdleTimePreferences
//
+ (IdleTimePreferences *)idleTimePreferences
{
    return([[[self alloc] init] autorelease]);
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

    }
}

- (IBAction)changeAwayPreference:(id)sender
{
    [[adium preferenceController] setPreference:[NSNumber numberWithInt:[popUp_title indexOfSelectedItem]]
										 forKey:KEY_AUTO_AWAY_MESSAGE_INDEX
										 group:PREF_GROUP_IDLE_TIME];
}

//Private ---------------------------------------------------------------------------
//init
- (id)init
{
    //Init
    [super init];

    //Register our preference pane
    [[adium preferenceController] addPreferencePane:[AIPreferencePane preferencePaneInCategory:AIPref_Status_Idle withDelegate:self label:IDLE_TIME_PREF_TITLE]];

    return(self);
}

//Return the view for our preference pane
- (NSView *)viewForPreferencePane:(AIPreferencePane *)preferencePane
{
    //Load our preference view nib
    if(!view_prefView){
        [NSBundle loadNibNamed:IDLE_TIME_PREF_NIB owner:self];

        //Configure our view
        [self configureView];
    }

    return(view_prefView);
}

//Clean up our preference pane
- (void)closeViewForPreferencePane:(AIPreferencePane *)preferencePane
{
    [view_prefView release]; view_prefView = nil;
}

//Configures our view for the current preferences
- (void)configureView
{
    NSDictionary	*preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_IDLE_TIME];

    //Idle
    [checkBox_enableIdle setState:[[preferenceDict objectForKey:KEY_IDLE_TIME_ENABLED] boolValue]];
    [textField_idleMinutes setIntValue:[[preferenceDict objectForKey:KEY_IDLE_TIME_IDLE_MINUTES] intValue]];
    [checkBox_enableAutoAway setState:[[preferenceDict objectForKey:KEY_AUTO_AWAY_ENABLED] boolValue]];
    [textField_autoAwayMinutes setIntValue:[[preferenceDict objectForKey:KEY_AUTO_AWAY_IDLE_MINUTES] intValue]];
	
	[self configureAutoAwayPreferences];
	
    [self configureControlDimming];
}

- (IBAction)refreshAutoAwayPreferences:(id)sender
{
    [self configureAutoAwayPreferences];
}

- (void)configureAutoAwayPreferences
{
	NSDictionary	*preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_IDLE_TIME];
	[popUp_title setMenu:[self savedAwaysMenu]];
	int awayMessageIndex = [[preferenceDict objectForKey:KEY_AUTO_AWAY_MESSAGE_INDEX] intValue];
	if ((awayMessageIndex >= 0) && (awayMessageIndex < [popUp_title numberOfItems])){
		[popUp_title selectItemAtIndex:awayMessageIndex];
	}
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

//Recursively load the away messages, rebuilding the structure with mutable objects
- (NSMutableArray *)_loadAwaysFromArray:(NSArray *)array
{
    NSEnumerator	*enumerator;
    NSDictionary	*dict;
    NSMutableArray	*mutableArray = [[NSMutableArray alloc] init];

    enumerator = [array objectEnumerator];
    while((dict = [enumerator nextObject])){
        NSString	*type = [dict objectForKey:@"Type"];

        if([type compare:@"Group"] == 0){
            [mutableArray addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                @"Group", @"Type",
                [self _loadAwaysFromArray:[dict objectForKey:@"Contents"]], @"Contents",
                [dict objectForKey:@"Name"], @"Name",
                nil]];

        }else if([type compare:@"Away"] == 0){
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

    if (awayMessageArray){
        NSEnumerator *enumerator = [awayMessageArray objectEnumerator];
        NSDictionary *dict;
        while(dict = [enumerator nextObject]){
            NSString * title = [dict objectForKey:@"Title"];
            if(title){
            menuItem = [[[NSMenuItem alloc] initWithTitle:title
                                                    target:self
                                                    action:@selector(changeAwayPreference:)
                                             keyEquivalent:@""] autorelease];
            }else{
                NSString * message = [[dict objectForKey:@"Message"] string];
    
                //Cap the away menu title (so they're not incredibly long)
                if([message length] > MENU_AWAY_DISPLAY_LENGTH){
                    message = [[message substringToIndex:MENU_AWAY_DISPLAY_LENGTH] stringByAppendingString:@"É"];
                }
                
                menuItem = [[[NSMenuItem alloc] initWithTitle:message
                                                       target:self
                                                       action:@selector(changeAwayPreference:)
                                                keyEquivalent:@""] autorelease];
            }
            [menuItem setRepresentedObject:dict];
            [menuItem setEnabled:YES];
            [savedAwaysMenu addItem:menuItem];        
        }
    }else{
            menuItem = [[[NSMenuItem alloc] initWithTitle:AUTO_AWAY_NO_AWAYS_TITLE
                                                    target:nil
                                                    action:nil
                                                keyEquivalent:@""] autorelease];
            [menuItem setEnabled:NO];
            [savedAwaysMenu addItem:menuItem];
			[checkBox_enableAutoAway setState:NO];
            [checkBox_enableAutoAway setEnabled:NO];
            [textField_autoAwayMinutes setEnabled:NO];
	}            

    [savedAwaysMenu setAutoenablesItems:NO];
    return savedAwaysMenu;
}

    
@end

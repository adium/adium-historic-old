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

#import "AIAwayStatusWindowController.h"
#import "AIAwayStatusWindowPlugin.h"
#import "AIEventSoundsPlugin.h"
#import "JSCEventBezelPlugin.h"

#define AWAY_STATUS_WINDOW_NIB					@"AwayStatusWindow"
#define	KEY_AWAY_STATUS_WINDOW_FRAME			@"Away Status Frame"
#define KEY_SMV_SHOW_AMPM      	                @"Show AM-PM"
#define PREF_GROUP_STANDARD_MESSAGE_DISPLAY		@"Message Display"

@interface AIAwayStatusWindowController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName;
- (void)updateAwayTime:(NSTimer *)inTimer;
- (void)preferencesChanged:(NSNotification *)notification;
@end

@implementation AIAwayStatusWindowController

AIAwayStatusWindowController	*sharedAwayStatusInstance = nil;

//Open the away window
+ (void)openAwayStatusWindow
{
	if(!sharedAwayStatusInstance){
		sharedAwayStatusInstance = [[self alloc] initWithWindowNibName:AWAY_STATUS_WINDOW_NIB];
		[sharedAwayStatusInstance showWindow:nil];
	}
}

//Close the away window
+ (void)closeAwayStatusWindow
{
	if(sharedAwayStatusInstance){
		[sharedAwayStatusInstance closeWindow:nil];
	}
}

//init the window controller
- (id)initWithWindowNibName:(NSString *)windowNibName
{
    [super initWithWindowNibName:windowNibName];

	//Remember the time this panel was displayed
    awayDate = [[NSDate date] retain];

    return(self);
}

//dealloc
- (void)dealloc
{
	[awayDate release];

    [super dealloc];
}

//Setup the window after it had loaded
- (void)windowDidLoad
{
    NSString	*savedFrame;
	
    //Restore the window position
    savedFrame = [[[adium preferenceController] preferencesForGroup:PREF_GROUP_WINDOW_POSITIONS] objectForKey:KEY_AWAY_STATUS_WINDOW_FRAME];
    if(savedFrame){
        [[self window] setFrameFromString:savedFrame];
    }
    
    //Observe preference changes
    [[adium notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    [self preferencesChanged:nil];
    
	//Install a timer to periodically update the away time
	awayTimer = [[NSTimer scheduledTimerWithTimeInterval:60.0
												  target:self
												selector:@selector(updateAwayTime:)
												userInfo:nil
												 repeats:YES] retain];
    [self updateAwayTime:nil];    
}

//Closes this window
- (void)closeWindow:(id)sender
{
    if([self windowShouldClose:nil]){
        [[self window] close];
    }
}

//Do some housekeeping before closing the away status window
- (BOOL)windowShouldClose:(id)sender
{
    //Save the window position
    [[adium preferenceController] setPreference:[[self window] stringWithSavedFrame]
                                         forKey:KEY_AWAY_STATUS_WINDOW_FRAME
                                          group:PREF_GROUP_WINDOW_POSITIONS];
    
    //Clean up and release the shared instance
    [[adium notificationCenter] removeObserver:self];    
	[awayTimer invalidate];
	[awayTimer release];
    [sharedAwayStatusInstance autorelease]; sharedAwayStatusInstance = nil;
	
    return(YES);
}

- (BOOL)shouldCascadeWindows
{
    return(NO);
}


//Window Content -------------------------------------------------------------------------------------------------------
//Preferences have changed, update window
- (void)preferencesChanged:(NSNotification *)notification
{
    NSString    *group = [[notification userInfo] objectForKey:@"Group"];
	
	//Mute Sounds
	if(notification == nil || [group compare:PREF_GROUP_SOUNDS] == 0){
		[button_mute setState:[[[adium preferenceController] preferenceForKey:KEY_EVENT_MUTE_WHILE_AWAY
																		group:PREF_GROUP_SOUNDS] boolValue]];
		
	}
	
	//Show Bezels
	if(notification == nil || [group compare:PREF_GROUP_EVENT_BEZEL] == 0){
		[button_showBezel setState:![[[adium preferenceController] preferenceForKey:KEY_EVENT_BEZEL_SHOW_AWAY
																			  group:PREF_GROUP_EVENT_BEZEL] boolValue]];
		
	}
	
	//Away Message
	if(notification == nil || [group compare:GROUP_ACCOUNT_STATUS] == 0 && [notification object] == nil){
		NSAttributedString	*awayMessage = [[[adium preferenceController] preferenceForKey:@"AwayMessage"
																					 group:GROUP_ACCOUNT_STATUS] attributedString];
		if(awayMessage) [[textView_awayMessage textStorage] setAttributedString:awayMessage];
	}
	
	//Window behavior
	if(notification == nil || [group compare:PREF_GROUP_AWAY_STATUS_WINDOW] == 0){
		NSDictionary	*prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_AWAY_STATUS_WINDOW];
		
		[(NSPanel *)[self window] setFloatingPanel:[[prefDict objectForKey:KEY_FLOAT_AWAY_STATUS_WINDOW] boolValue]];
		[(NSPanel *)[self window] setHidesOnDeactivate:[[prefDict objectForKey:KEY_HIDE_IN_BACKGROUND_AWAY_STATUS_WINDOW] boolValue]];

	}
}

//Update the displayed time
- (void)updateAwayTime:(NSTimer *)inTimer
{    
	NSString	*startTime = [awayDate descriptionWithCalendarFormat:[NSDateFormatter localizedDateFormatStringShowingSeconds:NO showingAMorPM:YES]
															timeZone:nil
															  locale:nil];
	NSString	*duration = [NSDateFormatter stringForTimeIntervalSinceDate:awayDate showingSeconds:NO abbreviated:NO];
	
	if(!duration || [duration length] == 0) duration = @"Less than a minute";
    [textField_awayTime setStringValue:[NSString stringWithFormat:@"Since %@ (%@)", startTime, duration]];
}

//User clicks come back, remove the away message
- (IBAction)comeBack:(id)sender
{
    [[adium preferenceController] setPreference:nil forKey:@"AwayMessage" group:GROUP_ACCOUNT_STATUS];
}


//Custom Behavior While Away -------------------------------------------------------------------------------------------
//Toggle sound muting
- (IBAction)toggleMute:(id)sender
{
    [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                         forKey:KEY_EVENT_MUTE_WHILE_AWAY
                                          group:PREF_GROUP_SOUNDS];
}

//Toggle bezel display
- (IBAction)toggleShowBezel:(id)sender
{
    [[adium preferenceController] setPreference:[NSNumber numberWithBool:![sender state]]
                                         forKey:KEY_EVENT_BEZEL_SHOW_AWAY
                                          group:PREF_GROUP_EVENT_BEZEL];
}

@end


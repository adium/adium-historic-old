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
#import "AIAdium.h"
#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>

#define AWAY_STATUS_WINDOW_NIB			@"AwayStatusWindow"
#define	KEY_AWAY_STATUS_WINDOW_FRAME		@"Away Status Frame"
#define KEY_SMV_SHOW_AMPM      	                @"Show AM-PM"
#define PREF_GROUP_STANDARD_MESSAGE_DISPLAY	@"Message Display"


@interface AIAwayStatusWindowController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName owner:(id)inOwner;
- (void)updateAwayTime:(id)userInfo;
- (NSString *)getTheTime:(time_t)secs;
- (void)preferencesChanged:(NSNotification *)notification;
@end

@implementation AIAwayStatusWindowController

//Return a new away status window controller
AIAwayStatusWindowController	*mySharedInstance = nil;
+ (AIAwayStatusWindowController *)awayStatusWindowControllerForOwner:(id)inOwner
{
    if(!mySharedInstance){
        mySharedInstance = [[self alloc] initWithWindowNibName:AWAY_STATUS_WINDOW_NIB owner:inOwner];
    }
    
    return(mySharedInstance);
}

// Called by menu items to force updates, including closing the window
+ (void)updateAwayStatusWindow
{
    if(mySharedInstance) {
        [mySharedInstance updateWindow];
    }
}

// Sets the window visibility -- used with the pref to hide/show the window
+ (void)setWindowVisible:(bool)visible
{
    if(mySharedInstance) {
        [mySharedInstance setVisible:visible];
    }
}

// Called when "Come Back" button is clicked
- (IBAction)comeBack:(id)sender
{
    [[owner accountController] setProperty:nil forKey:@"AwayMessage" account:nil];
    [mySharedInstance updateWindow];
}

// 
- (void)updateWindow
{

    // Get the show window status
    bool shouldShow = [[[[owner preferenceController] preferencesForGroup:PREF_GROUP_AWAY_STATUS_WINDOW] objectForKey:KEY_SHOW_AWAY_STATUS_WINDOW] boolValue];
    
    // Get the window floating status
    bool shouldFloat = [[[[owner preferenceController] preferencesForGroup:PREF_GROUP_AWAY_STATUS_WINDOW] objectForKey:KEY_FLOAT_AWAY_STATUS_WINDOW] boolValue];

    // Get the hide on deactivate status
    bool shouldHide = [[[[owner preferenceController] preferencesForGroup:PREF_GROUP_AWAY_STATUS_WINDOW] objectForKey:KEY_HIDE_IN_BACKGROUND_AWAY_STATUS_WINDOW] boolValue];
    
    // Get the away message. Returns null string if none.
    NSAttributedString *awayMessage = [NSAttributedString stringWithData:[[owner accountController] propertyForKey:@"AwayMessage" account:nil]];

    // Is an away message still up?
    if(awayMessage) {

        // Should we should the away message?
        if( shouldShow ) {
            [self showWindow:nil];
            // Set window level (floating or normal)
            [(NSPanel *)[self window] setFloatingPanel:shouldFloat]; //We know we're working with a panel here, so this typecast is safe and stops any compiler warnings.
            // Set hide on deactivate status
            [[self window] setHidesOnDeactivate:shouldHide];
        } else {
            [[self window] orderOut:nil];
        }
        
        // Update the message text
        [[textView_awayMessage textStorage] setAttributedString:awayMessage];
        
        //Update the time text
        [self updateAwayTime:nil];
        
    } else {
        // No away message, hide the window
        if([self windowShouldClose:nil]){
            [[self window] close];
        }
    }
    
}

- (void)setVisible:(bool)visible
{
    if( visible )
    {
        [[self window] orderFront:nil];
    } else {
        [[self window] orderOut:nil];
    }
}

//Private ----------------------------------------------------------------
//init the window controller
- (id)initWithWindowNibName:(NSString *)windowNibName owner:(id)inOwner
{
    [super initWithWindowNibName:windowNibName owner:self];

    owner = [inOwner retain];
    
    awayDate = [[NSDate date] retain];
    awayTimer = [[NSTimer scheduledTimerWithTimeInterval:60.0
        target:self
        selector:@selector(updateAwayTime:)
        userInfo:nil
        repeats:YES]
    retain];
    
    [[owner notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    
    [self preferencesChanged:nil];
    
    return(self);
}

//dealloc
- (void)dealloc
{
    [owner release];
    
    [awayDate release];
    [awayTimer release];

    [[owner notificationCenter] removeObserver:self];

    [timeStampFormat release];

    [super dealloc];
}

//Setup the window after it had loaded
- (void)windowDidLoad
{

    NSString	*savedFrame;
     
    //Restore the window position
    savedFrame = [[[owner preferenceController] preferencesForGroup:PREF_GROUP_WINDOW_POSITIONS] objectForKey:KEY_AWAY_STATUS_WINDOW_FRAME];
    if(savedFrame){
        [[self window] setFrameFromString:savedFrame];
    }
    
    // Put the current away message in the text field
    [[textView_awayMessage textStorage] setAttributedString:[NSAttributedString stringWithData:[[owner accountController] propertyForKey:@"AwayMessage" account:nil]]];
    
    [self updateAwayTime:nil];

    // Still to Add:
    // Put the time we went away in the text field
    // Add prefs: toggle showing the window, toggle window visibility on deactivate

}

//Closes this window
- (void)closeWindow
{
    if([self windowShouldClose:nil]){
        [[self window] close];
    }
}

// Do some housekeeping before closing the away status window
- (BOOL)windowShouldClose:(id)sender
{

    //Save the window position
    [[owner preferenceController] setPreference:[[self window] stringWithSavedFrame]
                                         forKey:KEY_AWAY_STATUS_WINDOW_FRAME
                                          group:PREF_GROUP_WINDOW_POSITIONS];
    
    //Release the shared instance
    [mySharedInstance autorelease]; mySharedInstance = nil;

    return(YES);
}

- (BOOL)shouldCascadeWindows
{
    return(NO);
}

- (void)preferencesChanged:(NSNotification *)notification
{
            NSDictionary *prefDict = [[owner preferenceController]
                preferencesForGroup:PREF_GROUP_STANDARD_MESSAGE_DISPLAY];
            
            //release the old one
            [timeStampFormat release];
            
            //get the new one
            timeStampFormat = [[NSDateFormatter localizedDateFormatStringShowingSeconds:NO
                showingAMorPM:[[prefDict objectForKey:KEY_SMV_SHOW_AMPM] boolValue]] retain];

}

- (void)updateAwayTime:(id)userInfo
{    
    [textField_awayTime setStringValue:
        [NSString stringWithFormat:@"Since %@ (%@)",
            [awayDate descriptionWithCalendarFormat:timeStampFormat timeZone:nil locale:nil], 
            [self getTheTime:(time_t)[awayDate timeIntervalSince1970]]]];
}

- (NSString *)getTheTime:(time_t)then
{
    time_t t = then;
    time_t now = time(NULL);
    long diff = now - t;
            
    if(diff < 59) //less than 1 minute
        return @"Less than a minute";
    else if(diff < 3599) //less than 1 hour
        return [NSString stringWithFormat:
            ((int)diff/60 == 1 ? @"%d minute" : @"%d minutes"), (int)diff/60];
    else
    {
        if((long)diff % 3600 < 59) // no minutes
            return [NSString stringWithFormat:
                ((int)diff/3600 == 1 ? @"%d hours" : @"%d hours"), (int)diff/3600];
        else // there are minutes
                return [NSString stringWithFormat:
                @"%d:%d hours", (int)diff/3600, (int)((int)diff % 3600)/60];
    }
}

@end


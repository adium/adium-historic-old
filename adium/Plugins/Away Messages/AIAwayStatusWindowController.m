//
//  AIAwayStatusWindowController.m
//  Adium
//
//  Created by David Clark on Sat May 17 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIAwayStatusWindowController.h"
#import "AIAwayMessagesPlugin.h"
#import "AIAdium.h"
#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>

#define AWAY_STATUS_WINDOW_NIB		@"AwayStatusWindow"
#define	KEY_AWAY_STATUS_WINDOW_FRAME	@"Away Status Frame"

@interface AIAwayStatusWindowController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName owner:(id)inOwner;
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
    [[owner accountController] setStatusObject:nil forKey:@"AwayMessage" account:nil];
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
    NSAttributedString *awayMessage = [NSAttributedString stringWithData:[[owner accountController] statusObjectForKey:@"AwayMessage" account:nil]];

    // Is an away message still up?
    if(awayMessage) {

        // Should we should the away message?
        if( shouldShow ) {
            [self showWindow:nil];
            // Set window level (floating or normal)
            [[self window] setFloatingPanel:shouldFloat];
            // Set hide on deactivate status
            [[self window] setHidesOnDeactivate:shouldHide];
        } else {
            [[self window] orderOut:nil];
        }
        
        // Update the message text
        [[textView_awayMessage textStorage] setAttributedString:awayMessage];
        
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

    return(self);
}

//dealloc
- (void)dealloc
{
    [owner release];

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
    [[textView_awayMessage textStorage] setAttributedString:[NSAttributedString stringWithData:[[owner accountController] statusObjectForKey:@"AwayMessage" account:nil]]];

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

@end


//
//  AIEnterAwayWindowController.m
//  Adium
//
//  Created by Adam Iser on Sun Jan 12 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIEnterAwayWindowController.h"
#import "AIAdium.h"
#import <Adium/Adium.h>

#define ENTER_AWAY_WINDOW_NIB		@"EnterAwayWindow"		//Filename of the window nib
#define	KEY_ENTER_AWAY_WINDOW_FRAME	@"Enter Away Frame"


@interface AIEnterAwayWindowController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName owner:(id)inOwner;
- (BOOL)windowShouldClose:(id)sender;
@end

@implementation AIEnterAwayWindowController

//Return a new contact list window controller
AIEnterAwayWindowController	*sharedInstance = nil;
+ (AIEnterAwayWindowController *)enterAwayWindowControllerForOwner:(id)inOwner
{
    if(!sharedInstance){
        sharedInstance = [[self alloc] initWithWindowNibName:ENTER_AWAY_WINDOW_NIB owner:inOwner];
    }
    return(sharedInstance);
}

//Closes this window
- (IBAction)closeWindow:(id)sender
{
    if([self windowShouldClose:nil]){
        [[self window] close];
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
    savedFrame = [[[owner preferenceController] preferencesForGroup:PREF_GROUP_WINDOW_POSITIONS] objectForKey:KEY_ENTER_AWAY_WINDOW_FRAME];
    if(savedFrame){
        [[self window] setFrameFromString:savedFrame];
    }

}

//Close the contact list window
- (BOOL)windowShouldClose:(id)sender
{
    //Save the window position
    [[owner preferenceController] setPreference:[[self window] stringWithSavedFrame]
                                         forKey:KEY_ENTER_AWAY_WINDOW_FRAME
                                          group:PREF_GROUP_WINDOW_POSITIONS];

    //Release the shared instance
    [sharedInstance autorelease]; sharedInstance = nil;
    
    return(YES);
}

- (BOOL)shouldCascadeWindows
{
    return(NO);
}

@end

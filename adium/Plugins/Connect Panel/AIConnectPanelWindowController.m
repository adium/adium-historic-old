//
//  AIConnectPanelWindowController.m
//  Adium
//
//  Created by Adam Iser on Fri Mar 12 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "AIConnectPanelWindowController.h"

#define CONNET_PANEL_NIB		@"ConnectPanel"
#define	KEY_CONNECT_PANEL_FRAME	@"Connect Panel Frame"

@implementation AIConnectPanelWindowController

//Return a new connection window
AIConnectPanelWindowController	*sharedConnectPanelInstance = nil;
+ (AIConnectPanelWindowController *)connectPanelWindowController
{
    if(!sharedConnectPanelInstance){
        sharedConnectPanelInstance = [[self alloc] initWithWindowNibName:CONNET_PANEL_NIB];
    }
    return(sharedConnectPanelInstance);
}

//init
- (id)initWithWindowNibName:(NSString *)windowNibName
{
    [super initWithWindowNibName:windowNibName];
	
    return(self);
}

//Window did load
- (void)windowDidLoad
{
    NSString	*savedFrame;
	
    //Restore the window position
	savedFrame = [[adium preferenceController] preferenceForKey:KEY_CONNECT_PANEL_FRAME group:PREF_GROUP_WINDOW_POSITIONS];
    if(savedFrame){
        [[self window] setFrameFromString:savedFrame];
    }
	
}

//Close this window
- (IBAction)closeWindow:(id)sender
{
    if([self windowShouldClose:nil]){
        [[self window] close];
    }
}

//Window is closing
- (BOOL)windowShouldClose:(id)sender
{
    //Save the window position
    [[adium preferenceController] setPreference:[[self window] stringWithSavedFrame]
                                         forKey:KEY_CONNECT_PANEL_FRAME
                                          group:PREF_GROUP_WINDOW_POSITIONS];
	
    return(YES);
}

//dealloc
- (void)dealloc
{	
    [super dealloc];
}

//Prevent the system from tiling this window
- (BOOL)shouldCascadeWindows
{
    return(NO);
}






@end

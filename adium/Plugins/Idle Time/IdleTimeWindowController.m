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

#import "IdleTimeWindowController.h"
#import "IdleTimePlugin.h"

@implementation IdleTimeWindowController

//Create and return a contact list editor window controller
static IdleTimeWindowController *sharedIdleTimeInstance = nil;
+ (id)idleTimeWindowControllerForPlugin:(AIIdleTimePlugin *)inPlugin
{
    if(!sharedIdleTimeInstance){
        sharedIdleTimeInstance = [[self alloc] initWithWindowNibName:@"SetIdleTime" forPlugin:inPlugin];
    }

    return(sharedIdleTimeInstance);
}

+ (void)closeSharedInstance
{
    if(sharedIdleTimeInstance){
        [sharedIdleTimeInstance closeWindow:nil];
    }
}

- (id)initWithWindowNibName:(NSString *)windowNibName forPlugin:(AIIdleTimePlugin *)inPlugin
{
    plugin = inPlugin;

    [super initWithWindowNibName:windowNibName];

    return(self);
}

- (void)windowDidLoad
{
    [[self window] center];

    [self configureControls:nil];
}

//Close the window
- (IBAction)closeWindow:(id)sender
{
    if([self windowShouldClose:nil]){
        [[self window] close];
    }
}

- (BOOL)windowShouldClose:(id)sender
{
    //Close this shared instance
    [self autorelease];
    sharedIdleTimeInstance = nil;
    
    return(YES);
}

- (void)dealloc
{    
    [super dealloc];
}

- (IBAction)configureControls:(id)sender
{
}

- (IBAction)apply:(id)sender
{
    [plugin setManualIdleTime:([textField_IdleHours intValue] * 3600) + ([textField_IdleMinutes intValue] * 60)];

    [self closeWindow:nil];
}

@end

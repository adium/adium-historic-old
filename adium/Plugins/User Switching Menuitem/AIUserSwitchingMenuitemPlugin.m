//
//  AIUserSwitchingMenuitemPlugin.m
//  Adium
//
//  Created by Ian Krieg on Thu Jul 17 2003.
//

#import "AIUserSwitchingMenuitemPlugin.h"
#import "AILoginWindowController.h"


@implementation AIUserSwitchingMenuitemPlugin

- (IBAction)changeUsers:(id)sender
{
    //Prompt for the user
    //AILoginWindowController *loginWindowController = [[AILoginWindowController loginWindowController] retain];
    //[loginWindowController showWindow:nil];
    
    NSLog (@"User asked to change users.");
    [[owner loginController] switchUsers];
}

- (void)installPlugin
{
    menuItem_changeUsers = [[NSMenuItem alloc] initWithTitle:@"Switch Users…" target:self action:@selector(changeUsers:) keyEquivalent:@""];
    [[owner menuController] addMenuItem:menuItem_changeUsers toLocation:LOC_Adium_Preferences];
}


@end

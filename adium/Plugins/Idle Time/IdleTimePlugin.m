//
//  Idle Time.m
//  Adium
//
//  Created by Greg Smith on Wed Dec 18 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import "IdleTimePlugin.h"
#import <AIUtilities/AIUtilities.h>
#import "IdleTimeWindowController.h"

extern double CGSSecondsSinceLastInputEvent(unsigned long evType);

@implementation AIIdleTimePlugin

- (void)installPlugin
{
    //Install the timer for auto idles
    [self installIdleTimer];

    //Install the menu item to manually set idle time
    NSMenuItem		*menuItem;

    menuItem = [[[NSMenuItem alloc] initWithTitle:@"Set Idle Time" target:self action:@selector(showIdleTimeWindow:) keyEquivalent:@"I"] autorelease];
    [[owner menuController] addMenuItem:menuItem toLocation:LOC_File_Status];
    
    //Install all the toolbar item to manually set idle time
    AIMiniToolbarItem	*toolbarItem;

    toolbarItem = [[AIMiniToolbarItem alloc] initWithIdentifier:@"IdleTime"];
    [toolbarItem setImage:[AIImageUtilities imageNamed:@"idle" forClass:[self class]]];
    [toolbarItem setTarget:self];
    [toolbarItem setAction:@selector(showIdleTimeWindow:)];
    [toolbarItem setEnabled:YES];
    [toolbarItem setToolTip:@"Set Idle Time"];
    [toolbarItem setPaletteLabel:@"Set Idle Time"];
    [toolbarItem setDelegate:self];
    [[AIMiniToolbarCenter defaultCenter] registerItem:[toolbarItem autorelease]];
}

- (void)goIdle
{
    double seconds = CGSSecondsSinceLastInputEvent(-1);

    //see if they're idle
    if(seconds > 300){//idle after 5 minutes, evenutally there will be a preference for this

        int		loop;
        NSArray		*accountArray;
        AIAccount	*theAccount;

        accountArray = [[owner accountController] accountArray];

        for(loop = 0;loop < [accountArray count];loop++){
            theAccount = [accountArray objectAtIndex:loop];
            if ([theAccount conformsToProtocol:@protocol(AIAccount_IdleTime)] &&
                (![(AIAccount <AIAccount_IdleTime> *)theAccount idleWasSetManually])) {
                [(AIAccount<AIAccount_IdleTime> *)theAccount setIdleTime:seconds manually:FALSE];
            }
        }

        //uninstall ourself
        [self removeTimer:idleTimer];

        //install unidle timer
        [self installUnidleTimer];
    }
}

- (void)unIdle
{
    double seconds = CGSSecondsSinceLastInputEvent(-1);

    //see if they're unidle
    if(seconds < 300){

        int		loop;
        NSArray		*accountArray;
        AIAccount	*theAccount;

        accountArray = [[owner accountController] accountArray];

        for(loop = 0;loop < [accountArray count];loop++){
            theAccount = [accountArray objectAtIndex:loop];
            if ([theAccount conformsToProtocol:@protocol(AIAccount_IdleTime)] &&
                (![(AIAccount <AIAccount_IdleTime> *)theAccount idleWasSetManually])) {
                [(AIAccount<AIAccount_IdleTime> *)theAccount setIdleTime:0 manually:FALSE];
            }
        }

        //uninstall ourself
        [self removeTimer:unidleTimer];

        //install idle timer
        [self installIdleTimer];
    }
}

- (void)installIdleTimer
{
    //---install idle timer---
    idleTimer = [[NSTimer scheduledTimerWithTimeInterval:(30.0) target:self selector:@selector(goIdle) userInfo:nil repeats:YES] retain];
}

- (void)installUnidleTimer
{
    //---install unidle timer---
    unidleTimer = [[NSTimer scheduledTimerWithTimeInterval:(1.0) target:self selector:@selector(unIdle) userInfo:nil repeats:YES] retain];
}

- (void)removeTimer:(NSTimer *)timer
{
    NSParameterAssert(timer != nil);
    [timer invalidate];
    [timer release];
    timer = nil;
}

- (IBAction)showIdleTimeWindow:(id)sender
{
    [[IdleTimeWindowController IdleTimeWindowControllerWithOwner:owner] showWindow:nil];
}

- (void)dealloc
{
    [IdleTimeWindowController release]; 	//Release the controller we created above.
    [AIMiniToolbarItem release];
    [super dealloc];
}

- (BOOL)configureToolbarItem:(AIMiniToolbarItem *)inToolbarItem forObjects:(NSDictionary *)inObjects
{
    return(YES);
}



@end

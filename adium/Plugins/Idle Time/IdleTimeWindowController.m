
#import <Adium/Adium.h>

#import "IdleTimeWindowController.h"
#import "IdleTimePlugin.h"

@implementation IdleTimeWindowController

//Create and return a contact list editor window controller
static IdleTimeWindowController *sharedInstance = nil;
+ (id)idleTimeWindowControllerWithOwner:(id)inOwner
{
    if(!sharedInstance){
        sharedInstance = [[self alloc] initWithWindowNibName:@"SetIdleTime" owner:inOwner];
    }

    return(sharedInstance);
}

+ (void)closeSharedInstance
{
    if(sharedInstance){
        [sharedInstance closeWindow:nil];
    }
}

- (id)initWithWindowNibName:(NSString *)windowNibName owner:(id)inOwner
{
    owner = [inOwner retain];

    [super initWithWindowNibName:windowNibName owner:self];

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
    sharedInstance = nil;
    
    return(YES);
}

- (void)dealloc
{
    [owner release];
    [AIIdleTimePlugin release];
    
    [super dealloc];
}

- (IBAction)configureControls:(id)sender
{
}

- (IBAction)apply:(id)sender
{
    [owner setManualIdleTime:([textField_IdleHours intValue] * 3600) + ([textField_IdleMinutes intValue] * 60)];

    [self closeWindow:nil];
}

@end

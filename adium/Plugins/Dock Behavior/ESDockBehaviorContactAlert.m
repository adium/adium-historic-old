//
//  ESDockBehaviorContactAlert.m
//  Adium
//
//  Created by Evan Schoenberg on Thu Nov 27 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "ESDockBehaviorContactAlert.h"

#define CONTACT_ALERT_ACTION_NIB @  "DockBehaviorContactAlert"
#define BOUNCE_THE_DOCK				AILocalizedString(@"Bounce the dock","Contact Alert: Boucne the dock icon")

@interface ESDockBehaviorContactAlert (PRIVATE)
- (NSMenu *)behaviorListMenu;
@end

@implementation ESDockBehaviorContactAlert

-(id)init
{
    behaviorListMenu_cached = nil;

    return([super init]);
}

-(void)dealloc{
    [behaviorListMenu_cached release];
    [super dealloc];
}

-(NSString *)nibName
{
    return CONTACT_ALERT_ACTION_NIB;
}

- (NSMenuItem *)alertMenuItem
{
    NSMenuItem * menuItem = [[[NSMenuItem alloc] initWithTitle:BOUNCE_THE_DOCK
                                           target:self
                                           action:@selector(selectedAlert:)
                                    keyEquivalent:@""] autorelease];
    [menuItem setRepresentedObject:CONTACT_ALERT_IDENTIFIER];

    return (menuItem);
}

- (NSImage *)icon
{
	return [NSImage imageNamed:@"dockalert" forClass:[self class]];
}

//setup display for bouncing the dock
- (void)configureView
{   
    //Get the current dictionary
    NSDictionary *currentDict = [[adium contactAlertsController] currentDictForContactAlert:self];
        
    [popUp_actionDetails setMenu:[self behaviorListMenu]];
    //Set the menu to its previous setting if the stored event matches
    if ([(NSString *)[currentDict objectForKey:KEY_EVENT_ACTION] isEqualToString:CONTACT_ALERT_IDENTIFIER]) {
        [popUp_actionDetails selectItemAtIndex:[popUp_actionDetails indexOfItemWithRepresentedObject:[currentDict objectForKey:KEY_EVENT_DETAILS]]];        
    }
    [popUp_actionDetails autosizeAndCenterHorizontally];
    
    [self configureWithSubview:view_details_menu];
}


- (NSMenu *)behaviorListMenu
{
    if (!behaviorListMenu_cached) {
        //get a behavior menu
        NSMenu		*behaviorMenu = [AIDockBehaviorPlugin behaviorListMenuForTarget:self];
        
        //Change the represented objects to strings for contact alert compatibility
        NSArray             *behaviorMenuItems = [behaviorMenu itemArray];
        NSEnumerator        *enumerator = [behaviorMenuItems objectEnumerator];
        NSMenuItem          *menuItem;
        
        while (menuItem = [enumerator nextObject]) {
            [menuItem setRepresentedObject:[[menuItem representedObject] stringValue]];
        }
        
        behaviorListMenu_cached = [behaviorMenu retain];
    }
    return behaviorListMenu_cached;
}
//The user selected a behavior
- (IBAction)selectBehavior:(id)sender
{
    [popUp_actionDetails autosizeAndCenterHorizontally];
    
    NSString	*behavior = [sender representedObject];
    [self setObject:behavior forKey:KEY_EVENT_DETAILS];
    
    //Save event sound preferences
    [self saveEventActionArray];
}

@end
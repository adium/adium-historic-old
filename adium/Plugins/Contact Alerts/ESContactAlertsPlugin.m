//
//  ESContactAlertsPlugin.m
//  Adium
//
//  Created by Evan Schoenberg on Mon Jul 14 2003.
//

#import "ESContactAlertsPlugin.h"
#import "ESContactAlertsWindowController.h"
#import "CSNewContactAlertWindowController.h"

#define EDIT_CONTACTS_ALERTS    AILocalizedString(@"Edit Alerts",nil)
#define EDIT_ALERTS				AILocalizedString(@"Edit Alerts",nil)

@interface ESContactAlertsPlugin(PRIVATE)
- (void)processEventActionArray:(NSMutableArray *)eventActionArray forObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys;
@end

@implementation ESContactAlertsPlugin

- (void)installPlugin
{    
	//Install the 'contact alerts' menu item
    editContactAlertsMenuItem = [[[NSMenuItem alloc] initWithTitle:EDIT_CONTACTS_ALERTS target:self action:@selector(editContactAlerts:) keyEquivalent:@""] autorelease];
    [[adium menuController] addMenuItem:editContactAlertsMenuItem toLocation:LOC_Contact_Action];
	
    //Add our 'contact alerts' contextual menu item
    contactAlertsContextMenuItem = [[[NSMenuItem alloc] initWithTitle:EDIT_ALERTS target:self action:@selector(editContactAlerts:) keyEquivalent:@""] autorelease];
    [[adium menuController] addContextualMenuItem:contactAlertsContextMenuItem toLocation:Context_Contact_Action];
}

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
    return(YES);
}

- (IBAction)editContactAlerts:(id)sender
{
    [ESContactAlertsWindowController showContactAlertsWindowForObject:[[adium contactController] selectedListObject]];
}

@end


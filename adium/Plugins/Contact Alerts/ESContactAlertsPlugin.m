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
#define EDIT_ALERTS		AILocalizedString(@"Add Alert",nil)

@interface ESContactAlertsPlugin(PRIVATE)
- (void)processEventActionArray:(NSMutableArray *)eventActionArray forObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys;
@end

@implementation ESContactAlertsPlugin

- (void)installPlugin
{
	AIMiniToolbarItem *toolbarItem;
    //Install the 'contact alerts' menu item
    editContactAlertsMenuItem = [[[NSMenuItem alloc] initWithTitle:EDIT_CONTACTS_ALERTS target:self action:@selector(editContactAlerts:) keyEquivalent:@""] autorelease];
    [[adium menuController] addMenuItem:editContactAlertsMenuItem toLocation:LOC_Contact_Action];
	
	
    //Add our 'contact alerts' contextual menu item
    contactAlertsContextMenuItem = [[[NSMenuItem alloc] initWithTitle:EDIT_ALERTS target:self action:@selector(addContactAlert:) keyEquivalent:@""] autorelease];
    [[adium menuController] addContextualMenuItem:contactAlertsContextMenuItem toLocation:Context_Contact_Action];
	
    //Add our 'contact alerts' toolbar item
    toolbarItem = [[AIMiniToolbarItem alloc] initWithIdentifier:@"ContactAlerts"];
    [toolbarItem setImage:[NSImage imageNamed:@"alerts" forClass:[self class]]];
    [toolbarItem setTarget:self];
    [toolbarItem setAction:@selector(toolbarContactAlerts:)];
    [toolbarItem setEnabled:YES];
    [toolbarItem setToolTip:@"Edit Contact Alerts"];
    [toolbarItem setPaletteLabel:@"Edit Contact Alerts"];
    [toolbarItem setDelegate:self];
    [[AIMiniToolbarCenter defaultCenter] registerItem:[toolbarItem autorelease]];
}

- (void)uninstallPlugin
{

}

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
    BOOL valid = YES;
    if(menuItem == editContactAlertsMenuItem) {
    }else if(menuItem == contactAlertsContextMenuItem) {
        return([[adium menuController] contactualMenuContact] != nil);
    }
    return(valid);
}

- (IBAction)editContactAlerts:(id)sender
{
    [ESContactAlertsWindowController showContactAlertsWindowForObject:[[adium contactController] selectedListObject]];
}

- (IBAction)addContactAlert:(id)sender
{
	ESContactAlerts *instance = [[[ESContactAlerts alloc] initWithDetailsView:nil withTable:nil withPrefView:nil] autorelease];
	CSNewContactAlertWindowController *windowController;
	[instance configForObject:[[adium menuController] contactualMenuContact]];
	windowController = [[CSNewContactAlertWindowController alloc] initWithInstance:instance editing:NO];
	[windowController setDelegate:self];
	[windowController showWindow:nil];
}

- (void)contactAlertWindowFinished:(id)sender didCreate:(BOOL)created
{
	if (created)
	{
		[[adium notificationCenter] postNotificationName:One_Time_Event_Fired 
												  object:[[sender contactAlertsInstance] activeObject]];
	}
}

- (BOOL)configureToolbarItem:(AIMiniToolbarItem *)inToolbarItem forObjects:(NSDictionary *)inObjects
{
    NSDictionary	*objects = [inToolbarItem configurationObjects];
    AIListContact	*object = [objects objectForKey:@"ContactObject"];
    BOOL		enabled = object &&  [object isKindOfClass:[AIListObject class]];
    
    [inToolbarItem setEnabled:enabled];
    return(YES);
}

- (IBAction)toolbarContactAlerts:(AIMiniToolbarItem *)toolbarItem
{
    NSDictionary		*objects = [toolbarItem configurationObjects];
    AIListObject		*object = [objects objectForKey:@"ContactObject"];
    
    [ESContactAlertsWindowController showContactAlertsWindowForObject:object];
}

@end
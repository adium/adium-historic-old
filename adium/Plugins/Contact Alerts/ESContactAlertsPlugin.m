//
//  ESContactAlertsPlugin.m
//  Adium
//
//  Created by Evan Schoenberg on Mon Jul 14 2003.
//

#import "ESContactAlertsPlugin.h"
#import "ESContactAlertsWindowController.h"
#import "ESContactAlertsPreferences.h"
#import "AIContactStatusEventsPlugin.h"

@interface ESContactAlertsPlugin(PRIVATE)
- (void)processEventActionArray:(NSMutableArray *)eventActionArray forObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys;
@end

@implementation ESContactAlertsPlugin

- (void)installPlugin
{
    AIMiniToolbarItem *toolbarItem;

    //Install the 'contact alerts' menu item
    editContactAlertsMenuItem = [[[NSMenuItem alloc] initWithTitle:@"Edit Contact's Alerts" target:self action:@selector(editContactAlerts:) keyEquivalent:@""] autorelease];
    [[owner menuController] addMenuItem:editContactAlertsMenuItem toLocation:LOC_Contact_Action];

    //Add our 'contact alerts' contextual menu item
    contactAlertsContextMenuItem = [[[NSMenuItem alloc] initWithTitle:@"Edit Alerts" target:self action:@selector(editContextContactAlerts:) keyEquivalent:@""] autorelease];
    [[owner menuController] addContextualMenuItem:contactAlertsContextMenuItem toLocation:Context_Contact_Action];

    //Add our 'contact alerts' toolbar item
    toolbarItem = [[AIMiniToolbarItem alloc] initWithIdentifier:@"ContactAlerts"];
    [toolbarItem setImage:[AIImageUtilities imageNamed:@"alerts" forClass:[self class]]];
    [toolbarItem setTarget:self];
    [toolbarItem setAction:@selector(toolbarContactAlerts:)];
    [toolbarItem setEnabled:YES];
    [toolbarItem setToolTip:@"Edit Contact Alerts"];
    [toolbarItem setPaletteLabel:@"Edit Contact Alerts"];
    [toolbarItem setDelegate:self];
    [[AIMiniToolbarCenter defaultCenter] registerItem:[toolbarItem autorelease]];

    //Install the preference pane
    prefs = [[ESContactAlertsPreferences contactAlertsPreferencesWithOwner:owner] retain];
}

- (void)uninstallPlugin
{

}

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
    BOOL valid = YES;
    if(menuItem == editContactAlertsMenuItem) {

        AIListContact	*selectedContact = [[owner contactController] selectedContact];

        if(selectedContact){
            [editContactAlertsMenuItem setTitle:[NSString stringWithFormat:@"Edit %@'s Alerts",[selectedContact displayName]]];
        }else{
            [editContactAlertsMenuItem setTitle:@"Edit Contact's Alerts"];
            valid = NO;
        }
    }else if(menuItem == contactAlertsContextMenuItem) {
        return([[owner menuController] contactualMenuContact] != nil);
    }
    return(valid);
}

- (IBAction)editContactAlerts:(id)sender
{
    [ESContactAlertsWindowController showContactAlertsWindowWithOwner:owner
                                                            forObject:[[owner contactController] selectedContact]];
}

- (IBAction)editContextContactAlerts:(id)sender
{
    [ESContactAlertsWindowController showContactAlertsWindowWithOwner:owner
                                                            forObject:[[owner menuController] contactualMenuContact]];
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
    
    [ESContactAlertsWindowController showContactAlertsWindowWithOwner:owner forObject:object];
}

@end
//
//  AIContactAlertsPlugin.m
//  Adium
//
//  Created by Evan Schoenberg on Mon Jul 14 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIContactAlertsPlugin.h"
#import "AIContactAlertsWindowController.h"
#import <AIUtilities/AIUtilities.h>
#import <Adium/Adium.h>
#import "AIAdium.h"

@interface AIContactAlertsPlugin(PRIVATE)

@end

@implementation AIContactAlertsPlugin

//basic actions
- (void) registerBuiltInActions
{

}

- (void)installPlugin
{
      AIMiniToolbarItem *toolbarItem;

    //Install the 'contact alerts' menu item
    editContactAlertsMenuItem = [[NSMenuItem alloc] initWithTitle:@"Edit Contact's Alerts" target:self action:@selector(editContactAlerts:) keyEquivalent:@""];
    [[owner menuController] addMenuItem:editContactAlertsMenuItem toLocation:LOC_Contact_Action];

    //Add our 'contact alerts' contextual menu item
    contactAlertsContextMenuItem = [[NSMenuItem alloc] initWithTitle:@"Edit Contact's Alerts" target:self action:@selector(editContextContactInfo:) keyEquivalent:@""];
    [[owner menuController] addContextualMenuItem:contactAlertsContextMenuItem toLocation:Context_Contact_Manage];

    //Add our 'contact alerts' toolbar item
    toolbarItem = [[AIMiniToolbarItem alloc] initWithIdentifier:@"ContactAlerts"];
    [toolbarItem setImage:[AIImageUtilities imageNamed:@"info" forClass:[self class]]];
    [toolbarItem setTarget:self];
    [toolbarItem setAction:@selector(toolbarContactAlerts:)];
    [toolbarItem setEnabled:YES];
    [toolbarItem setToolTip:@"Edit Contact Alerts"];
    [toolbarItem setPaletteLabel:@"Edit Contact Alerts"];
    [toolbarItem setDelegate:self];
    [[AIMiniToolbarCenter defaultCenter] registerItem:[toolbarItem autorelease]];    


    //Register the 'built-in' actions (the ones within this plugin)
    [self registerBuiltInActions];
    
    //Register as a contact observer
    [[owner contactController] registerListObjectObserver:self];
}



- (void)uninstallPlugin
{

}


- (NSArray *)updateListObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys
{
    eventActionArray =  [[owner preferenceController] preferenceForKey:KEY_EVENT_ACTIONSET group:PREF_GROUP_ALERTS object:inObject];
    int				away, online, unviewedContent, signedOn, signedOff, typing;
    double			idle;

    //Get all the values
    away = [[inObject statusArrayForKey:@"Away"] greatestIntegerValue];
    idle = [[inObject statusArrayForKey:@"Idle"] greatestDoubleValue];
    online = [[inObject statusArrayForKey:@"Online"] greatestIntegerValue];
    signedOn = [[inObject statusArrayForKey:@"Signed On"] greatestIntegerValue];
    signedOff = [[inObject statusArrayForKey:@"Signed Off"] greatestIntegerValue];
    typing = [[inObject statusArrayForKey:@"Typing"] greatestIntegerValue];
    unviewedContent = [[inObject statusArrayForKey:@"UnviewedContent"] greatestIntegerValue];
    
   // [[owner soundController] playSoundAtPath:[soundPathDict objectForKey:[notification name]]];
    return nil;
}





- (IBAction)editContactAlerts:(id)sender
{
    [AIContactAlertsWindowController showContactAlertsWindowWithOwner:owner
                                         forContact:[[owner contactController] selectedContact]];
}

- (IBAction)editContextContactAlerts:(id)sender
{
    [AIContactAlertsWindowController showContactAlertsWindowWithOwner:owner
                                         forContact:[[owner menuController] contactualMenuContact]];
}

// Specific actions can be given a human-readable name and registered
- (void)registerAction:(NSString *)inNotification displayName:(NSString *)displayName
{
    [eventActionsDict setObject:[NSDictionary dictionaryWithObjectsAndKeys:inNotification, KEY_EVENT_NOTIFICATION, displayName, KEY_EVENT_DISPLAY_NAME, nil] forKey:inNotification];
}


- (BOOL)configureToolbarItem:(AIMiniToolbarItem *)inToolbarItem forObjects:(NSDictionary *)inObjects
{
    NSDictionary		*objects = [inToolbarItem configurationObjects];
    AIListContact		*object = [objects objectForKey:@"ContactObject"];
    NSLog(@"configuring toolbar item");
    BOOL			enabled = (object && [object isKindOfClass:[AIListContact class]]);

    [inToolbarItem setEnabled:enabled];
    return(enabled);
}

- (IBAction)toolbarContactAlerts:(AIMiniToolbarItem *)toolbarItem
{
    NSDictionary		*objects = [toolbarItem configurationObjects];
    AIListContact		*object = [objects objectForKey:@"ContactObject"];

    if([object isKindOfClass:[AIListContact class]]){
        //Show the profile window
        [AIContactAlertsWindowController showContactAlertsWindowWithOwner:owner forContact:object];
    }
}
@end

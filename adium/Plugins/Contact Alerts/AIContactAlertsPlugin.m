//
//  AIContactAlertsPlugin.m
//  Adium
//
//  Created by Evan Schoenberg on Mon Jul 14 2003.
//

#import "AIContactAlertsPlugin.h"
#import "AIContactAlertsWindowController.h"
#import <AIUtilities/AIUtilities.h>
#import <Adium/Adium.h>
#import "AIAdium.h"

@interface AIContactAlertsPlugin(PRIVATE)

@end

@implementation AIContactAlertsPlugin

- (void)installPlugin
{
      AIMiniToolbarItem *toolbarItem;

    //Install the 'contact alerts' menu item
    editContactAlertsMenuItem = [[NSMenuItem alloc] initWithTitle:@"Edit Contact's Alerts" target:self action:@selector(editContactAlerts:) keyEquivalent:@""];
    [[owner menuController] addMenuItem:editContactAlertsMenuItem toLocation:LOC_Contact_Action];

    //Add our 'contact alerts' contextual menu item
    contactAlertsContextMenuItem = [[NSMenuItem alloc] initWithTitle:@"Edit Alerts" target:self action:@selector(editContextContactInfo:) keyEquivalent:@""];
    [[owner menuController] addContextualMenuItem:contactAlertsContextMenuItem toLocation:Context_Contact_Manage];

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

    //Register as a contact observer
    [[owner contactController] registerListObjectObserver:self];
}



- (void)uninstallPlugin
{

}


- (NSArray *)updateListObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys delayed:(BOOL)delayed silent:(BOOL)silent
{
    NSMutableArray * eventActionArray =  [[[[owner preferenceController] preferenceForKey:KEY_EVENT_ACTIONSET group:PREF_GROUP_ALERTS object:inObject] mutableCopy] autorelease];
    NSEnumerator * actionsEnumerator;
    NSDictionary * actionDict;
    NSString * action;
    NSString * event;
    int status, event_status;
    BOOL status_matches;

    [eventActionArray addObjectsFromArray:[[owner preferenceController] preferenceForKey:KEY_EVENT_ACTIONSET group:PREF_GROUP_ALERTS object:[inObject containingGroup]]]; //get the group array, as well
    
    actionsEnumerator = [eventActionArray objectEnumerator];
    while(actionDict = [actionsEnumerator nextObject])
    {
        event = [actionDict objectForKey:KEY_EVENT_NOTIFICATION];
 //       NSLog(@"modified keys are %@; the event is %@; the statusArrayForKey is %@; giv is %i and looking for %i",inModifiedKeys, event, [inObject statusArrayForKey:event], [[inObject statusArrayForKey:event] greatestIntegerValue],  [[actionDict objectForKey:KEY_EVENT_STATUS] intValue]);

        status = [[inObject statusArrayForKey:event] greatestIntegerValue];
        event_status = [[actionDict objectForKey:KEY_EVENT_STATUS] intValue];
        status_matches = (status && event_status) || (!status && !event_status); //XOR
        if ( status_matches && [inModifiedKeys containsObject:event])
             { //actions to take when an event is matched go here

            action = [actionDict objectForKey:KEY_EVENT_ACTION];

            if ([action compare:@"Sound"] == 0)
            {
                NSString	*soundPath = [actionDict objectForKey:KEY_EVENT_DETAILS];
                if(soundPath != nil && [soundPath length] != 0) {
                    [[owner soundController] playSoundAtPath:soundPath]; //Play the sound
                }
            }

            else if ([action compare:@"Message"] == 0)
            { //message
                if ([[inObject statusArrayForKey:@"Online"] greatestIntegerValue]) //must still be online to prevent an error message
                {
                NSMutableArray * onlineAccounts = [NSMutableArray array];
                NSEnumerator * accountEnumerator;
                AIAccount * account;
                AIContentMessage * responseContent;
                
                accountEnumerator = [[[owner accountController] accountArray] objectEnumerator];
                while(account = [accountEnumerator nextObject]){
                    if ([[account statusObjectForKey:@"Status"] intValue] == STATUS_ONLINE)
                    {
                        [onlineAccounts addObject:account];
                    }
                }
                account = [onlineAccounts objectAtIndex:0];

                NSAttributedString  *message = [[NSAttributedString alloc] initWithString:[actionDict objectForKey:KEY_EVENT_DETAILS]];
                 responseContent = [AIContentMessage messageInChat:[[owner contentController] chatWithListObject:inObject onAccount:account]
                                                       withSource:account
                                                      destination:inObject
                                                             date:nil
                                                          message:message];
                [[owner contentController] sendContentObject:responseContent];
                }
            }
            else if ([action compare:@"Alert"] == 0) {
                NSAttributedString *message = [[NSAttributedString alloc] initWithString:[actionDict objectForKey:KEY_EVENT_DETAILS]];
                NSString *title = [[NSString alloc] initWithString:[NSString stringWithFormat:@"%@ %@", [inObject displayName], [actionDict objectForKey:KEY_EVENT_DISPLAYNAME]]];
                NSRunInformationalAlertPanel(title, [message string], @"Okay", nil, nil);
            }
        }
    }
    return nil; //we don't change any attributes
}

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
    BOOL valid = YES;
    if(menuItem == editContactAlertsMenuItem){

        AIListContact	*selectedContact = [[owner contactController] selectedContact];

        if(selectedContact){
            [editContactAlertsMenuItem setTitle:[NSString stringWithFormat:@"Edit %@'s Alerts",[selectedContact displayName]]];
        }else{
            [editContactAlertsMenuItem setTitle:@"Edit Contact's Alerts"];
            valid = NO;
        }
    }else if(menuItem == contactAlertsContextMenuItem){
        NSLog(@"checking context...");
        return([[owner menuController] contactualMenuContact] != nil);
    }
    return(valid);
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

- (BOOL)configureToolbarItem:(AIMiniToolbarItem *)inToolbarItem forObjects:(NSDictionary *)inObjects
{
    NSDictionary		*objects = [inToolbarItem configurationObjects];
    AIListContact		*object = [objects objectForKey:@"ContactObject"];
    BOOL			enabled = (object && [object isKindOfClass:[AIListContact class]]);

    [inToolbarItem setEnabled:enabled];
    return(enabled);
}

- (IBAction)toolbarContactAlerts:(AIMiniToolbarItem *)toolbarItem
{
    NSDictionary		*objects = [toolbarItem configurationObjects];
    AIListContact		*object = [objects objectForKey:@"ContactObject"];

    if([object isKindOfClass:[AIListContact class]]){
        //Show the window
        [AIContactAlertsWindowController showContactAlertsWindowWithOwner:owner forContact:object];
    }
}


@end

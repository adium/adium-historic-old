//
//  ESContactAlertsPlugin.m
//  Adium
//
//  Created by Evan Schoenberg on Mon Jul 14 2003.
//

#import "ESContactAlertsPlugin.h"
#import "ESContactAlertsWindowController.h"
#import "ESContactAlertsPreferences.h"
#import <AIUtilities/AIUtilities.h>
#import <Adium/Adium.h>
#import "AIAdium.h"
#import "SUSpeaker.h"

@interface ESContactAlertsPlugin(PRIVATE)
- (void)processEventActionArrayForObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys;
@end

@implementation ESContactAlertsPlugin

- (void)installPlugin
{
    AIMiniToolbarItem *toolbarItem;

    //Install the 'contact alerts' menu item
    editContactAlertsMenuItem = [[NSMenuItem alloc] initWithTitle:@"Edit Contact's Alerts" target:self action:@selector(editContactAlerts:) keyEquivalent:@""];
    [[owner menuController] addMenuItem:editContactAlertsMenuItem toLocation:LOC_Contact_Action];

    //Add our 'contact alerts' contextual menu item
    contactAlertsContextMenuItem = [[NSMenuItem alloc] initWithTitle:@"Edit Alerts" target:self action:@selector(editContextContactAlerts:) keyEquivalent:@""];
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

    //Initialize our text-to-speech object
    speaker = [[SUSpeaker alloc] init];

    //Install the preference pane
    prefs = [[ESContactAlertsPreferences contactAlertsPreferencesWithOwner:owner] retain];
}

- (void)uninstallPlugin
{

}

- (NSArray *)updateListObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys delayed:(BOOL)delayed silent:(BOOL)silent
{
    if (!silent) //We do things.  If silent, don't do them.
    {
        [self processEventActionArrayForObject:inObject keys:inModifiedKeys];
        [self processEventActionArrayForObject:[inObject containingGroup] keys:inModifiedKeys]; //process the group's array, as well
    }
    return nil; //we don't change any attributes
}

- (void)processEventActionArrayForObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys
{
    NSMutableArray * eventActionArray =  [[owner preferenceController] preferenceForKey:KEY_EVENT_ACTIONSET group:PREF_GROUP_ALERTS object:inObject];

    NSEnumerator * actionsEnumerator;
    NSDictionary * actionDict;
    NSString * event;
    int status, event_status;
    BOOL status_matches;

    actionsEnumerator = [eventActionArray objectEnumerator];
    while(actionDict = [actionsEnumerator nextObject])
    {
        event = [actionDict objectForKey:KEY_EVENT_NOTIFICATION];
        status = [[inObject statusArrayForKey:event] greatestIntegerValue];
        event_status = [[actionDict objectForKey:KEY_EVENT_STATUS] intValue];
        status_matches = (status && event_status) || (!status && !event_status); //XOR

        if ( status_matches && [inModifiedKeys containsObject:event] ) { //actions to take when an event is matched go here
            NSString * action = [actionDict objectForKey:KEY_EVENT_ACTION];
            NSString * details = [actionDict objectForKey:KEY_EVENT_DETAILS];
            int delete = [[actionDict objectForKey:KEY_EVENT_DELETE] intValue];
            int onlyWhileActive = [[actionDict objectForKey:KEY_EVENT_ACTIVE] intValue];
            BOOL success = NO;

            if ([action compare:@"Message"] == 0) { //message - uses Only While Active in a special way

                AIAccount * account;
                AIContentMessage * responseContent;
                NSString * errorReason;
                NSDictionary * detailsDict = [actionDict objectForKey:KEY_EVENT_DETAILS_DICT];
                account = [[owner accountController] accountWithID:[detailsDict objectForKey:KEY_MESSAGE_SENDFROM]];
                NSAttributedString  *message = [[NSAttributedString alloc] initWithString:details];
                int displayError = [[detailsDict objectForKey:KEY_MESSAGE_ERROR] intValue];
                NSString * uid = [detailsDict objectForKey:KEY_MESSAGE_SENDTO_UID];
                NSString * service = [detailsDict objectForKey:KEY_MESSAGE_SENDTO_SERVICE];
                AIListContact * contact = [[owner contactController] contactInGroup:nil withService:service UID:uid];

                if ([[owner contentController] availableForSendingContentType:CONTENT_MESSAGE_TYPE toListObject:nil onAccount:account]) //desired account is available
                {	success = YES;	}
                else
                {
                    if ([[detailsDict objectForKey:KEY_MESSAGE_OTHERACCOUNT] intValue]) //use another account if necessary pref
                    {
                        NSMutableArray * onlineAccounts = [NSMutableArray array];
                        NSEnumerator * accountEnumerator;
                        accountEnumerator = [[[owner accountController] accountArray] objectEnumerator];
                        //use first acccount on the same service as the handle which is also available to send content
                        while(account = [accountEnumerator nextObject]){
                            if ( [[contact serviceID] compare:[[[account service] handleServiceType] identifier]] == 0 &&
                                 [[owner contentController] availableForSendingContentType:CONTENT_MESSAGE_TYPE toListObject:nil onAccount:account])
                            {
                                [onlineAccounts addObject:account];
                            }
                        }

                        if (![onlineAccounts count]) //no appropriate accounts found
                        {
                            errorReason = [[NSString alloc] initWithString:@"failed because no appropriate accounts are online."];
                            success = NO;
                        }
                        else
                        {
                            success = YES;
                            account = [onlineAccounts objectAtIndex:0]; //pick first account in our array of possibilities
                        }
                    }
                    else
                    {
                        errorReason = [[NSString alloc] initWithString:[NSString stringWithFormat:@"with %@ failed because the account %@ is currently offline.",[account accountDescription],[account accountDescription]]];
                        success = NO;
                    }
                }
                if (success) //we're good so far...
                {
                    if (!onlyWhileActive || (![[owner accountController] statusObjectForKey:@"IdleSince" account:account] && ![[owner accountController] statusObjectForKey:@"AwayMessage" account:account]))
                    {
                        if ([[contact statusArrayForKey:@"Online"] greatestIntegerValue])
                        {
                            AIChat	*chat = [[owner contentController] openChatOnAccount:account withListObject:contact];

                            [[owner interfaceController] setActiveChat:chat];
                            responseContent = [AIContentMessage messageInChat:chat
                                                                   withSource:account
                                                                  destination:contact
                                                                         date:nil
                                                                      message:message];
                            success = [[owner contentController] sendContentObject:responseContent];

                            if (!success)
                                errorReason = [[NSString alloc] initWithString:[NSString stringWithFormat:@"failed while sending the message."]];
                        }
                        else //target contact is not online
                        {
                            errorReason = [[NSString alloc] initWithString:[NSString stringWithFormat:@"failed because %@ is currently unavailable.",[contact displayName]]];
                            success = NO;
                        }

                    }
                    else //target account not active
                    {
                        displayError = NO; //don't display an error message, even if the preference is to do so
                        success = NO;
                    }
                }

                if (!success && displayError) //Would have had it if it weren't for those pesky account and contact kids...
                {
                    NSString *alertMessage = [[NSString alloc] initWithString:[NSString stringWithFormat:@"The attempt to send \"%@\" to %@ %@",[message string],[contact displayName],errorReason]];
                    NSString *title = [[NSString alloc] initWithString:[NSString stringWithFormat:@"%@ %@", [inObject displayName], [actionDict objectForKey:KEY_EVENT_DISPLAYNAME]]];
                    [[owner interfaceController] handleMessage:title withDescription:alertMessage withWindowTitle:@"Error Sending Message"];
                }
            }

            else//use Only While Active in a global sense from here on out
            {
                if (!onlyWhileActive || (![[owner accountController] statusObjectForKey:@"IdleSince" account:nil] && ![[owner accountController] statusObjectForKey:@"AwayMessage" account:nil]))
                {
                    if ([action compare:@"Sound"] == 0) {
                        if (details != nil && [details length] != 0) {
                            [[owner soundController] playSoundAtPath:details]; //Play the sound
                            success = YES;
                        }
                        else
                            success = NO;
                    }

                    else if ([action compare:@"Alert"] == 0) {
                        NSString *title = [[NSString alloc] initWithString:[NSString stringWithFormat:@"%@ %@", [inObject displayName], [actionDict objectForKey:KEY_EVENT_DISPLAYNAME]]];
                        [[owner interfaceController] handleMessage:title withDescription:details withWindowTitle:@"Contact Alert"];
                        success = YES;
                    }

                    else if ([action compare:@"Bounce"] == 0) {
                        //Perform the behavior
                        [[owner dockController] performBehavior:[details intValue]];
                        success = YES;
                    }

                    else if ([action compare:@"Speak"] == 0) {
                        [speaker speakText:details]; //uses Raphael Sebbe's SpeechUtilities.framework
                        success = YES;
                    }

                    else if ([action compare:@"Open Message"] == 0) { //Force open a chat window
                        NSDictionary * detailsDict = [actionDict objectForKey:KEY_EVENT_DETAILS_DICT];
                        AIAccount * account = [[owner accountController] accountWithID:details];
                        success = YES;
                        if ([[account statusObjectForKey:@"Status"] intValue] == STATUS_OFFLINE) //desired account not available
                        {
                            success = NO; //as of now, we can't open our window
                            if ([[detailsDict objectForKey:KEY_MESSAGE_OTHERACCOUNT] intValue]) //use another account if necessary pref
                            {
                                NSMutableArray * onlineAccounts = [NSMutableArray array];
                                NSEnumerator * accountEnumerator;
                                accountEnumerator = [[[owner accountController] accountArray] objectEnumerator];
                                //use first acccount on the same service as the handle and available to send content
                                while(account = [accountEnumerator nextObject]){
                                    if ( [[account statusObjectForKey:@"Status"] intValue] == STATUS_ONLINE)
                                    {
                                        [onlineAccounts addObject:account];
                                    }
                                }
                                if ([onlineAccounts count])
                                {
                                    account = [onlineAccounts objectAtIndex:0]; //pick first account in our array of possibilities
                                    success = YES; //now we can open our window
                                }
                            }
                        }
                        if (success)
                        {
                            AIChat	*chat = [[owner contentController] openChatOnAccount:account withListObject:inObject];
                            [[owner interfaceController] setActiveChat:chat];
                        }
                    } //end of action code
                    
                  } //close if (test for active)

            } //close else
            
            //after all tests
            if (delete && success) //delete the action from the array
            {
                [eventActionArray removeObject:actionDict];
                [[owner preferenceController] setPreference:eventActionArray forKey:KEY_EVENT_ACTIONSET group:PREF_GROUP_ALERTS object:inObject];

                //Broadcast a one time event fired message
                [[owner notificationCenter] postNotificationName:One_Time_Event_Fired
                                                          object:inObject
                                                        userInfo:nil];
            }
            
        } //close status_matches && containsKey
    } //close while
} //end function

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
    NSDictionary		*objects = [inToolbarItem configurationObjects];
    AIListContact		*object = [objects objectForKey:@"ContactObject"];
    BOOL			enabled = object &&  [object isKindOfClass:[AIListObject class]];

    [inToolbarItem setEnabled:enabled];
    return(enabled);
}

- (IBAction)toolbarContactAlerts:(AIMiniToolbarItem *)toolbarItem
{
    NSDictionary		*objects = [toolbarItem configurationObjects];
    AIListObject		*object = [objects objectForKey:@"ContactObject"];

    [ESContactAlertsWindowController showContactAlertsWindowWithOwner:owner forObject:object];
}

- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_ALERTS] == 0){
        NSLog(@"prefs changed.");
    }
}

@end
//
//  ESSendMessageContactAlert.m
//  Adium XCode
//
//  Created by Evan Schoenberg on Fri Nov 28 2003.
//

#import "ESSendMessageContactAlert.h"
#import "ESSendMessageContactAlertPlugin.h"

#define CONTACT_ALERT_ACTION_NIB @"SendMessageContactAlert"

@interface ESSendMessageContactAlert (PRIVATE)
-(IBAction)saveMessageDetails:(id)sender;
- (NSMenu *)accountMenu;
- (NSMenu *)sendToContactMenu;
@end

int alphabeticalGroupOfflineSort(id objectA, id objectB, void *context);

#define SEND_MESSAGE    AILocalizedString(@"Send a message",nil)
#define OFFLINE		AILocalizedString(@"Offline",nil)

@implementation ESSendMessageContactAlert

-(NSString *)nibName
{
    return CONTACT_ALERT_ACTION_NIB;
}

- (NSMenuItem *)alertMenuItem
{
    NSMenuItem * menuItem = [[[NSMenuItem alloc] initWithTitle:SEND_MESSAGE
                                                        target:self
                                                        action:@selector(selectedAlert:)
                                                 keyEquivalent:@""] autorelease];
    [menuItem setRepresentedObject:CONTACT_ALERT_IDENTIFIER];
    
    return (menuItem);
}

//setup display for the sending message details
-(IBAction)selectedAlert:(id)sender
{  	
    //Get the current dictionary
    NSDictionary *currentDict = [[[adium contactAlertsController] currentDictForContactAlert:self] retain];
    AIListObject *activeContactObject = [[[adium contactAlertsController] currentObjectForContactAlert:self] retain];
    
    NSString            *details = [currentDict objectForKey:KEY_EVENT_DETAILS];
    NSMutableDictionary *detailsDict;
    AIAccount           *account;
    
    if (![(NSString *)[currentDict objectForKey:KEY_EVENT_ACTION] isEqualToString:CONTACT_ALERT_IDENTIFIER]) {
        [self setObject:nil forKey:KEY_EVENT_DETAILS];
        details = nil;
    }
    
    [textField_message_actionDetails setStringValue:(details ? details : @"")];
    [textField_message_actionDetails setDelegate:self];
    
    [popUp_message_actionDetails_one setMenu:[self accountMenu]];
    [popUp_message_actionDetails_two setMenu:[self sendToContactMenu]];
    
    detailsDict = [currentDict objectForKey:KEY_EVENT_DETAILS_DICT];
    if (!detailsDict) { //new message
        //Configure buttons
        [button_anotherAccount setState:NSOnState]; //default: use another account if needed
        [button_displayAlert setState:NSOffState]; //default: don't display an alert
        
        //Configure the Send To: menu
        if ([activeContactObject isKindOfClass:[AIListContact class]]) {
            [popUp_message_actionDetails_two selectItemAtIndex:[popUp_message_actionDetails_two indexOfItemWithRepresentedObject:activeContactObject]]; //default: send to the current contact
        }
        
        //Configure the Send From: menu
        NSEnumerator * accountEnumerator = [[[adium accountController] accountArray] objectEnumerator];

        //enumerate the accounts, stopping as soon as one is not offline (and is therefore online)
        while( (account = [accountEnumerator nextObject]) && (![[account statusObjectForKey:@"Online"] boolValue]) );
        
        if (account) { //if we found an online account, set it as the default account choice
            [popUp_message_actionDetails_one selectItemAtIndex:[popUp_message_actionDetails_one indexOfItemWithRepresentedObject:account]];
        }
        [self saveMessageDetails:nil];
    } else { //restore the old settings
        //Configure the buttons
        [button_anotherAccount setState:[[detailsDict objectForKey:KEY_MESSAGE_OTHERACCOUNT] intValue]];
        [button_displayAlert setState:[[detailsDict objectForKey:KEY_MESSAGE_ERROR] intValue]];

        //Send from account:
        account = [[adium accountController] accountWithObjectID:[detailsDict objectForKey:KEY_MESSAGE_SENDFROM]];
        [popUp_message_actionDetails_one selectItemAtIndex:[popUp_message_actionDetails_one indexOfItemWithRepresentedObject:account]];

        //Send message to:
        NSString *uid = [detailsDict objectForKey:KEY_MESSAGE_SENDTO_UID];
        NSString *service = [detailsDict objectForKey:KEY_MESSAGE_SENDTO_SERVICE];
        AIListContact *contact = [[adium contactController] contactWithService:service accountID:[account uniqueObjectID] UID:uid];
        [popUp_message_actionDetails_two selectItemAtIndex:[popUp_message_actionDetails_two indexOfItemWithRepresentedObject:contact]];
        
    }
    [self configureWithSubview:view_details_message];
    
    [[view_details_message window] makeFirstResponder:textField_message_actionDetails];
    [currentDict release]; [activeContactObject release];
}

//Send Message
-(IBAction)saveMessageDetails:(id)sender
{
    NSMutableDictionary *detailsDict = [[NSMutableDictionary alloc] init];
    AIListContact       *contact;
    AIAccount           *account;
    
    //set the sendFrom account if necessary
    if (account = [[popUp_message_actionDetails_one selectedItem] representedObject])
        [detailsDict setObject:[account uniqueObjectID] forKey:KEY_MESSAGE_SENDFROM];
    
    //set the sendTo contact if necessary, saving the UID and Service
    if (contact = [[popUp_message_actionDetails_two selectedItem] representedObject]) {
        [detailsDict setObject:[contact UID] forKey:KEY_MESSAGE_SENDTO_UID];
        [detailsDict setObject:[contact serviceID] forKey:KEY_MESSAGE_SENDTO_SERVICE];
    }
    
    //save the buttons 
    [detailsDict setObject:[NSNumber numberWithInt:[button_anotherAccount state]] forKey:KEY_MESSAGE_OTHERACCOUNT];
    [detailsDict setObject:[NSNumber numberWithInt:[button_displayAlert state]] forKey:KEY_MESSAGE_ERROR];
    
    [self setObject:detailsDict forKey:KEY_EVENT_DETAILS_DICT];
    [detailsDict release]; //setObject sends a retain
    
    [self saveEventActionArray];
}

- (NSMenu *)accountMenu
{    
    NSMenu          *accountMenu = [[NSMenu alloc] init];
    
    NSEnumerator    *accountEnumerator;
    AIAccount       *account;    
    accountEnumerator = [[[adium accountController] accountArray] objectEnumerator];
    
    while(account = [accountEnumerator nextObject]){
        NSMenuItem 	*menuItem;
        NSString	*accountDescription;
        accountDescription = [account displayName];
        menuItem = [[[NSMenuItem alloc] initWithTitle:accountDescription
                                               target:self
                                               action:@selector(saveMessageDetails:)
                                        keyEquivalent:@""] autorelease];
        [menuItem setRepresentedObject:account];
        [accountMenu addItem:menuItem];
    }
    
    return ([accountMenu autorelease]);
}

//builds an alphabetical menu of contacts for all online accounts; online contacts are sorted to the top and seperated
//from offline ones by a seperator reading "Offline"
//uses alphabeticalGroupOfflineSort and calls saveMessageDetails: when a selection is made
- (NSMenu *)sendToContactMenu
{
    NSMenu		*contactMenu = [[NSMenu alloc] init];
    //Build the menu items
    NSMutableArray		*contactArray =  [[adium contactController] allContactsInGroup:nil subgroups:YES];
    if ([contactArray count])
    {
        [contactArray sortUsingFunction:alphabeticalGroupOfflineSort context:nil]; //online buddies will end up at the top, alphabetically
        
        NSEnumerator 	*enumerator = 	[contactArray objectEnumerator];
        AIListObject	*contact;
        //NSString 	*groupName = [[[NSString alloc] init] autorelease];
        BOOL		firstOfflineSearch = NO;
        
        while (contact = [enumerator nextObject])
        {
            NSMenuItem		*menuItem;
            NSString	 	*itemDisplay;
            NSString		*itemUID = [contact UID];
            itemDisplay = [contact displayName];
            if ( !([itemDisplay compare:itemUID] == 0) ) //display name and screen name aren't the same
                itemDisplay = [NSString stringWithFormat:@"%@ (%@)",itemDisplay,itemUID]; //show the UID along with the display name
            menuItem = [[[NSMenuItem alloc] initWithTitle:itemDisplay
                                                   target:self
                                                   action:@selector(saveMessageDetails:)
                                            keyEquivalent:@""] autorelease];
            [menuItem setRepresentedObject:contact];
#ifdef MAC_OS_X_VERSION_10_3
            if ([menuItem respondsToSelector:@selector(setIndentationLevel:)])
                [menuItem setIndentationLevel:1];
#endif
            
#warning Again, this can not work as-is now.
            /*
            if ([groupName compare:[[contact containingGroup] displayName]] != 0)
            {
                NSMenuItem	*groupItem;
                if ([contactMenu numberOfItems] > 0) [contactMenu addItem:[NSMenuItem separatorItem]];
                groupItem = [[[NSMenuItem alloc] initWithTitle:[[contact containingGroup] displayName]
                                                        target:nil
                                                        action:nil
                                                 keyEquivalent:@""] autorelease];
                [groupItem setEnabled:NO];
#ifdef MAC_OS_X_VERSION_10_3
                if ([menuItem respondsToSelector:@selector(setIndentationLevel:)])
                    [groupItem setIndentationLevel:0];
#endif
                [contactMenu addItem:groupItem];
                firstOfflineSearch = YES; //start searching for an offline contact
            }
            */
            if (firstOfflineSearch)
            {
                if ( !([contact integerStatusObjectForKey:@"Online"]) ) //look for the first offline contact
                {
                    NSMenuItem	*separatorItem;
                    separatorItem = [[[NSMenuItem alloc] initWithTitle:OFFLINE
                                                                target:nil
                                                                action:nil
                                                         keyEquivalent:@""] autorelease];
                    [separatorItem setEnabled:NO];
                    [contactMenu addItem:separatorItem];
                    firstOfflineSearch = NO;
                }
            }
            
            [contactMenu addItem:menuItem];
            
 //           groupName = [[contact containingGroup] displayName];
        }
        [contactMenu setAutoenablesItems:NO];
    }
    return ([contactMenu autorelease]);
}

//Our text field was modified - save in KEY_EVENT_DETAILS (catch here instead of when it sends its action so a sudden window closure won't leave us without saving
- (void)controlTextDidChange:(NSNotification *)notification
{
    [self setObject:[[notification object] stringValue] forKey:KEY_EVENT_DETAILS];
    
    [self saveEventActionArray];
}

@end

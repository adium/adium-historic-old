//
//  ESOpenMessageWindowContactAlert.m
//  Adium
//
//  Created by Evan Schoenberg on Sat Nov 29 2003.
//

#import "ESOpenMessageWindowContactAlert.h"
#import "ESOpenMessageWindowContactAlertPlugin.h"

#define CONTACT_ALERT_ACTION_NIB @"OpenMessageWindowContactAlert"

#define OPEN_MESSAGE_WINDOW AILocalizedString(@"Open empty message window","Contact alert: open a new message window")

@interface ESOpenMessageWindowContactAlert (PRIVATE)
-(IBAction)saveOpenMessageDetails:(id)sender;
- (NSMenu *)accountForOpenMessageMenu;
@end

@implementation ESOpenMessageWindowContactAlert

-(NSString *)nibName
{
    return CONTACT_ALERT_ACTION_NIB;
}

- (NSMenuItem *)alertMenuItem
{
    NSMenuItem * menuItem = [[[NSMenuItem alloc] initWithTitle:OPEN_MESSAGE_WINDOW
                                                        target:self
                                                        action:@selector(selectedAlert:)
                                                 keyEquivalent:@""] autorelease];
    [menuItem setRepresentedObject:CONTACT_ALERT_IDENTIFIER];
    
    return (menuItem);
}

//setup display for opening message window
-(IBAction)selectedAlert:(id)sender
{  
    NSDictionary *currentDict = [[[adium contactAlertsController] currentDictForContactAlert:self] retain];
    
    NSMutableDictionary * detailsDict = [currentDict objectForKey:KEY_EVENT_DETAILS_DICT];
    
    [popUp_actionDetails_open_message setMenu:[self accountForOpenMessageMenu]];
    
    if (!detailsDict) //new message
    {
        NSEnumerator    *accountEnumerator = [[[adium accountController] accountArray] objectEnumerator];
        AIAccount       *account;
        
        //enumerate until we find an online account
        while( (account = [accountEnumerator nextObject]) && (![[account statusObjectForKey:@"Online"] boolValue]) );
        
         //if we found an online account, set it as the default account choice
        if (account)
        {
            NSString *accountID = [account uniqueObjectID];
            [popUp_actionDetails_open_message selectItemAtIndex:[popUp_actionDetails_open_message indexOfItemWithRepresentedObject:account]]; //set the menu view
            
            [self setObject:accountID forKey:KEY_EVENT_DETAILS];
        }
        
        [button_anotherAccount_open_message setState:NSOnState]; //default: use another account if needed
        
        [self saveOpenMessageDetails:nil];
    }
    else //restore the old settings
    {
        //Restore the account
        AIAccount * account = [[adium accountController] accountWithObjectID:[currentDict objectForKey:KEY_EVENT_DETAILS]];
        [popUp_actionDetails_open_message selectItemAtIndex:[popUp_actionDetails_open_message indexOfItemWithRepresentedObject:account]];
        [button_anotherAccount_open_message setState:[[detailsDict objectForKey:KEY_MESSAGE_OTHERACCOUNT] intValue]];
    }
    
    [self saveEventActionArray];
    
    [self configureWithSubview:view_details_open_message];
}

//Open Message Window
-(IBAction)saveOpenMessageDetails:(id)sender
{
    NSMutableDictionary *detailsDict = [[NSMutableDictionary alloc] init];
    [detailsDict setObject:[NSNumber numberWithInt:[button_anotherAccount_open_message state]] forKey:KEY_MESSAGE_OTHERACCOUNT];
    
    [self setObject:detailsDict forKey:KEY_EVENT_DETAILS_DICT];
    [detailsDict release]; //setObject sends a retain
    
    [self saveEventActionArray];
}


//--Open Message Window--
- (NSMenu *)accountForOpenMessageMenu
{
    NSEnumerator * accountEnumerator;
    AIAccount * account;
    NSMenu * accountMenu = [[NSMenu alloc] init];
    
    accountEnumerator = [[[adium accountController] accountArray] objectEnumerator];
    while(account = [accountEnumerator nextObject]){
        NSMenuItem 	*menuItem;
        NSString	*accountDescription;
        accountDescription = [account displayName];
        menuItem = [[[NSMenuItem alloc] initWithTitle:accountDescription
                                               target:self
                                               action:@selector(selectAccount:)
                                        keyEquivalent:@""] autorelease];
        [menuItem setRepresentedObject:account];
        [accountMenu addItem:menuItem];
    }
    
    return accountMenu;
}
- (IBAction)selectAccount:(id)sender
{
    AIAccount * account = [sender representedObject];
    
    [self setObject:[account uniqueObjectID] forKey:KEY_EVENT_DETAILS];
    
    //Save event preferences
    [self saveEventActionArray];
}


@end

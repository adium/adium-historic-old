//
//  CSNewContactAlertWindowController.m
//  Adium
//
//  Created by Chris Serino on Wed Mar 31 2004.
//

#import "CSNewContactAlertWindowController.h"
#import "ESContactAlertsWindowController.h"
#import "ESContactAlerts.h"
#import "ESContactAlertsPlugin.h"

#define NEW_ALERT_NIB @"NewAlert"
#define KEY_NEW_ALERT_FRAME @"New Alert Frame"
#define OFFLINE AILocalizedString(@"Offline",nil)

@interface CSNewContactAlertWindowController (PRIVATE)

- (NSMenu *)switchContactMenu;

@end

extern int alphabeticalGroupOfflineSort_contactAlerts(id objectA, id objectB, void *context);

@implementation CSNewContactAlertWindowController

#pragma mark Initialization

- (id)initWithInstance:(ESContactAlerts *)inInstance editing:(BOOL)inEditing
{
	if (self = [super initWithWindowNibName:NEW_ALERT_NIB])
	{
		[self setContactAlertsInstance:inInstance];
		editing = inEditing;
	}
	return self;
}

- (void)dealloc
{
	[instance release];
	[super dealloc];
}

#pragma mark Window Management

- (void)windowDidLoad
{
	NSString	*savedFrame;
	NSDictionary *actionDict;
	
	[self window];
	
	//Restore the window position
    savedFrame = [[[adium preferenceController] preferencesForGroup:PREF_GROUP_WINDOW_POSITIONS] objectForKey:KEY_NEW_ALERT_FRAME];
    if(savedFrame){
        [[self window] setFrame:NSRectFromString(savedFrame) display:YES];            
    }
	[popUp_contact setMenu:[self switchContactMenu]];
	
	if (!editing)
	{
		[instance newEvent:self]; //create the new event we'll be working with
	}
	
    [[self window] setDelegate:self];
	
	[instance setMainView:view_auxilary];
	
	[popUp_event setMenu:[instance eventMenu]];
	[popUp_action setMenu:[instance actionListMenu]];
	
	actionDict = [instance dictAtIndex:[instance currentRow]];
	
	[popUp_event selectItemWithTitle:[actionDict objectForKey:KEY_EVENT_DISPLAYNAME]];
	
	//Selects the current action
	NSEnumerator *actionEnumerator = [[popUp_action itemArray] objectEnumerator];
	NSMenuItem *currentItem;
	
	while (currentItem = [actionEnumerator nextObject]) {
		if ([(NSString *)[actionDict objectForKey:KEY_EVENT_ACTION] compare:(NSString *)[currentItem representedObject]] == 0) {
			[popUp_action selectItem:currentItem];
			break;
		}
	}
	
	//Selects the current contact
	NSEnumerator *enumerator = [[popUp_contact itemArray] objectEnumerator];
	AIListObject *alertObject;
	
	alertObject = [instance activeObject];
	while (currentItem = [enumerator nextObject]) {
		AIListObject *currentObject = [currentItem representedObject];
		if ([[currentObject uniqueObjectID] compare:[alertObject uniqueObjectID]] == 0) {
			[popUp_contact selectItem:currentItem];
			break;
		}
	}
}


- (BOOL)windowShouldClose:(id)sender
{    
	[[adium preferenceController] setPreference:[[self window] stringWithSavedFrame]
                                         forKey:KEY_NEW_ALERT_FRAME
                                          group:PREF_GROUP_WINDOW_POSITIONS];
	
	if ([(NSObject *)delegate respondsToSelector:@selector(contactAlertWindowFinished:)])
		[(id <NewContactAlertDelegate>)delegate contactAlertWindowFinished:self didCreate:NO];
	
	return YES;
}
 
#pragma mark Interface

- (IBAction)add:(id)sender
{
	[instance saveEventActionArray];
	if (delegate && [(NSObject *)delegate respondsToSelector:@selector(contactAlertWindowFinished:didCreate:)])
		[(id <NewContactAlertDelegate>)delegate contactAlertWindowFinished:self didCreate:YES];
	
	[[self window] performClose:self];
}

- (IBAction)cancel:(id)sender
{
	if (!editing)
		[instance deleteEventAction:self]; //get rid of it
	if ([(NSObject *)delegate respondsToSelector:@selector(contactAlertWindowFinished:didCreate:)])
		[(id <NewContactAlertDelegate>)delegate contactAlertWindowFinished:self didCreate:NO];

	[[self window] performClose:self];
}

#pragma mark Accessors

- (void)setContactAlertsInstance:(ESContactAlerts *)inInstance
{
	if (instance) {
		[instance release];
		instance = nil;
	}
	instance = [inInstance retain];
}

- (ESContactAlerts *)contactAlertsInstance
{
	return instance;
}

- (void)setDelegate:(id)inDelegate
{
	delegate = inDelegate;
}

- (id)delegate
{
	return delegate;
}

#pragma mark Alert Management

- (IBAction)contactChange:(id)sender
{
	NSMutableDictionary *oldDict = [instance dictAtIndex:[instance currentRow]];
	[oldDict retain];
	[instance deleteEventAction:nil];
	[instance configForObject:[sender representedObject]];
	[instance newEvent:nil];
	[instance replaceDictAtIndex:[instance currentRow] withDict:oldDict];
	[oldDict release];
}


#pragma mark Private
//builds an alphabetical menu of contacts for all online accounts; online contacts are sorted to the top and seperated
//from offline ones by a seperator reading "Offline"
//uses alphabeticalGroupOfflineSort and calls switchToContact: when a selection is made
- (NSMenu *)switchContactMenu
{
    NSMenu              *contactMenu = [[NSMenu alloc] init];
    //Build the menu items
    NSMutableArray              *contactArray =  [[adium contactController] allContactsInGroup:nil subgroups:YES];
    if ([contactArray count])
    {
        [contactArray sortUsingFunction:alphabeticalGroupOfflineSort_contactAlerts context:nil]; //online buddies will end up at the top, alphabetically
		
        NSEnumerator    *enumerator =   [contactArray objectEnumerator];
        AIListObject    *contact;
		//        NSString      *groupName = [[[NSString alloc] init] autorelease];
        BOOL            firstOfflineSearch = NO;
		
        while (contact = [enumerator nextObject])
        {
            NSMenuItem          *menuItem;
            NSString            *itemDisplay;
            NSString            *itemUID = [contact UID];
            itemDisplay = [contact displayName];
            if ( !([itemDisplay compare:itemUID] == 0) ) //display name and screen name aren't the same
                itemDisplay = [NSString stringWithFormat:@"%@ (%@)",itemDisplay,itemUID]; //show the UID along with the display name
            menuItem = [[[NSMenuItem alloc] initWithTitle:itemDisplay
                                                   target:self
                                                   action:@selector(contactChange:)
                                            keyEquivalent:@""] autorelease];
            [menuItem setRepresentedObject:contact];
			
#ifdef MAC_OS_X_VERSION_10_3
            if ([menuItem respondsToSelector:@selector(setIndentationLevel:)])
                [menuItem setIndentationLevel:1];
#endif
			
			
#warning Groups can not go into the menu this way anymore...
            /*
			 if ([groupName compare:[[contact containingGroup] displayName]] != 0)
			 {
				 NSMenuItem      *groupItem;
				 if ([contactMenu numberOfItems] > 0) [contactMenu addItem:[NSMenuItem separatorItem]];
				 groupItem = [[[NSMenuItem alloc] initWithTitle:[[contact containingGroup] displayName]
														 target:self
														 action:@selector(switchToContact:)
												  keyEquivalent:@""] autorelease];
				 [groupItem setRepresentedObject:[contact containingGroup]];
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
                    NSMenuItem  *separatorItem;
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
			
            //XXX EDS
			//            groupName = [[contact containingGroup] displayName];
        }
        [contactMenu setAutoenablesItems:NO];
    }
    return contactMenu;
}

@end

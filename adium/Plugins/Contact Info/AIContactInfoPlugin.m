//
//  AIContactInfoPlugin.m
//  Adium
//
//  Created by Adam Iser on Wed Jun 11 2003.
//

#import "AIContactInfoPlugin.h"
#import "AIInfoWindowController.h"

#define ALTERNATE_GET_INFO_MASK (NSCommandKeyMask | NSShiftKeyMask | NSAlternateKeyMask)

#define VIEW_CONTACTS_INFO  AILocalizedString(@"View Contact's Info",nil)
#define VIEW_INFO	    AILocalizedString(@"View Info",nil)

@interface AIContactInfoPlugin (PRIVATE)

@end

@implementation AIContactInfoPlugin

- (void)installPlugin
{
    //Install the Get Info menu item
	viewContactInfoMenuItem = [[NSMenuItem alloc] initWithTitle:VIEW_CONTACTS_INFO
														 target:self
														 action:@selector(showContactInfo:)
												  keyEquivalent:@"i"];
	[viewContactInfoMenuItem setKeyEquivalentModifierMask:(NSCommandKeyMask | NSShiftKeyMask)];
	[[adium menuController] addMenuItem:viewContactInfoMenuItem toLocation:LOC_Contact_Manage];
	
	if([NSApp isOnPantherOrBetter]) {
		//Install the alternate Get Info menu item which will let us mangle the shortcut as desired
        viewContactInfoMenuItem_alternate = [[NSMenuItem alloc] initWithTitle:VIEW_CONTACTS_INFO 
																	   target:self 
																	   action:@selector(showContactInfo:)
																keyEquivalent:@"i"];
        [viewContactInfoMenuItem_alternate setKeyEquivalentModifierMask:ALTERNATE_GET_INFO_MASK];
        [viewContactInfoMenuItem_alternate setAlternate:YES];
        [[adium menuController] addMenuItem:viewContactInfoMenuItem_alternate toLocation:LOC_Contact_Manage];      
        
        //Register for the contact list notifications
        [[adium notificationCenter] addObserver:self selector:@selector(contactListDidBecomeMain:) 
										   name:Interface_ContactListDidBecomeMain 
										 object:nil];
        [[adium notificationCenter] addObserver:self selector:@selector(contactListDidResignMain:)
										   name:Interface_ContactListDidResignMain 
										 object:nil];
		
		//Watch changes in viewContactInfoMenuItem_alternate's menu so we can maintain its alternate status
		//(it will expand into showing both the normal and the alternate items when the menu changes)
		[[adium notificationCenter] addObserver:self selector:@selector(menuChanged:)
										   name:Menu_didChange 
										 object:[viewContactInfoMenuItem_alternate menu]];
		
    }
    
    //Add our get info contextual menu item
    getInfoContextMenuItem = [[NSMenuItem alloc] initWithTitle:VIEW_INFO target:self action:@selector(showContextContactInfo:) keyEquivalent:@""];
    [[adium menuController] addContextualMenuItem:getInfoContextMenuItem toLocation:Context_Contact_Manage];

    //Add our get info toolbar item
    NSToolbarItem   *toolbarItem = [AIToolbarUtilities toolbarItemWithIdentifier:@"ShowInfo"
									   label:@"Info"
								    paletteLabel:@"Show Info"
									 toolTip:@"Show Info"
									  target:self
								 settingSelector:@selector(setImage:)
								     itemContent:[NSImage imageNamed:@"info" forClass:[self class]]
									  action:@selector(showContactInfo:)
									    menu:nil];
    [[adium toolbarController] registerToolbarItem:toolbarItem forToolbarType:@"ListObject"];
}

- (void)contactListDidBecomeMain:(NSNotification *)notification
{
    [[adium menuController] removeItalicsKeyEquivalent];
    [viewContactInfoMenuItem_alternate setKeyEquivalentModifierMask:(NSCommandKeyMask)];
	[viewContactInfoMenuItem_alternate setAlternate:YES];
}

- (void)contactListDidResignMain:(NSNotification *)notification
{
    //set our alternate modifier mask back to the obscure combination
    [viewContactInfoMenuItem_alternate setKeyEquivalent:@"i"];
    [viewContactInfoMenuItem_alternate setKeyEquivalentModifierMask:ALTERNATE_GET_INFO_MASK];
    [viewContactInfoMenuItem_alternate setAlternate:YES];
    //Now give the italics its combination back
    [[adium menuController] restoreItalicsKeyEquivalent];
}

- (void)menuChanged:(NSNotification *)notification
{
	[NSMenu updateAlternateMenuItem:viewContactInfoMenuItem_alternate];
}

- (IBAction)showContactInfo:(id)sender
{
    [AIInfoWindowController showInfoWindowForListObject:[[adium contactController] selectedListObject]];
}

- (IBAction)showContextContactInfo:(id)sender
{
    [AIInfoWindowController showInfoWindowForListObject:[[adium menuController] contactualMenuContact]];
}

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
    BOOL valid = YES;

    if(menuItem == viewContactInfoMenuItem || menuItem == viewContactInfoMenuItem_alternate){
        AIListObject	*selectedObject = [[adium contactController] selectedListObject];

        if(selectedObject && [selectedObject isKindOfClass:[AIListContact class]]){
            [menuItem setTitle:[NSString stringWithFormat:@"View %@'s Info",[selectedObject displayName]]];
        }else{
            [menuItem setTitle:@"View Contact's Info"];
            valid = NO;
        }
    }else if(menuItem == getInfoContextMenuItem){
        AIListContact	*selectedContact = [[adium menuController] contactualMenuContact];
        if ( !(selectedContact && [selectedContact isKindOfClass:[AIListContact class]]) )
            valid = NO;
    }
    return(valid);
}


@end

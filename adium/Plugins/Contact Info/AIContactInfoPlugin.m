//
//  AIContactInfoPlugin.m
//  Adium
//
//  Created by Adam Iser on Wed Jun 11 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIContactInfoPlugin.h"
#import "AIInfoWindowController.h"

#define ALTERNATE_GET_INFO_MASK (NSCommandKeyMask | NSShiftKeyMask | NSAlternateKeyMask)

@interface AIContactInfoPlugin (PRIVATE)

@end

@implementation AIContactInfoPlugin

- (void)installPlugin
{
    //Install the Get Info menu item
    viewContactInfoMenuItem = [[NSMenuItem alloc] initWithTitle:@"View Contact's Info" target:self action:@selector(showContactInfo:) keyEquivalent:@"i"];
    [viewContactInfoMenuItem setKeyEquivalentModifierMask:(NSCommandKeyMask | NSShiftKeyMask)];
    [[owner menuController] addMenuItem:viewContactInfoMenuItem toLocation:LOC_Contact_Manage];
    
    //Install the alternate Get Info menu item which will let us mangle the shortcut as desired
    if ([NSApp isOnPantherOrBetter]) {
        viewContactInfoMenuItem_alternate = [[NSMenuItem alloc] initWithTitle:@"View Contact's Info" target:self action:@selector(showContactInfo:) keyEquivalent:@"i"];
        [viewContactInfoMenuItem_alternate setKeyEquivalentModifierMask:ALTERNATE_GET_INFO_MASK];
        [viewContactInfoMenuItem_alternate setAlternate:YES];
        [[owner menuController] addMenuItem:viewContactInfoMenuItem_alternate toLocation:LOC_Contact_Manage];      
        
        //Register for the contact list notifications
        [[owner notificationCenter] addObserver:self selector:@selector(contactListDidBecomeMain:) name:Interface_ContactListDidBecomeMain object:nil];
        [[owner notificationCenter] addObserver:self selector:@selector(contactListDidResignMain:) name:Interface_ContactListDidResignMain object:nil];
    }
    
    //Add our get info contextual menu item
    getInfoContextMenuItem = [[NSMenuItem alloc] initWithTitle:@"View Info" target:self action:@selector(showContextContactInfo:) keyEquivalent:@""];
    [[owner menuController] addContextualMenuItem:getInfoContextMenuItem toLocation:Context_Contact_Manage];

    //Add our get info toolbar item
    NSToolbarItem   *toolbarItem = [AIToolbarUtilities toolbarItemWithIdentifier:@"ShowInfo"
									   label:@"Info"
								    paletteLabel:@"Show Info"
									 toolTip:@"Show Info"
									  target:self
								 settingSelector:@selector(setImage:)
								     itemContent:[AIImageUtilities imageNamed:@"info" forClass:[self class]]
									  action:@selector(showContactInfo:)
									    menu:nil];
    [[owner toolbarController] registerToolbarItem:toolbarItem forToolbarType:@"ListObject"];
}

- (void)contactListDidBecomeMain:(NSNotification *)notification
{
    [[owner menuController] removeItalicsKeyEquivalent];
    [viewContactInfoMenuItem_alternate setKeyEquivalentModifierMask:(NSCommandKeyMask)];
}

- (void)contactListDidResignMain:(NSNotification *)notification
{
    //set our alternate modifier mask back to the obscure combination
    [viewContactInfoMenuItem_alternate setKeyEquivalent:@"i"];
    [viewContactInfoMenuItem_alternate setKeyEquivalentModifierMask:ALTERNATE_GET_INFO_MASK];
    [viewContactInfoMenuItem_alternate setAlternate:YES];
    //Now give the italics its combination back
    [[owner menuController] restoreItalicsKeyEquivalent];
}

- (IBAction)showContactInfo:(id)sender
{
    [AIInfoWindowController showInfoWindowWithOwner:owner
                                         forContact:[[owner contactController] selectedContact]];
}

- (IBAction)showContextContactInfo:(id)sender
{
    [AIInfoWindowController showInfoWindowWithOwner:owner
                                         forContact:[[owner menuController] contactualMenuContact]];
}

- (BOOL)configureToolbarItem:(AIMiniToolbarItem *)inToolbarItem forObjects:(NSDictionary *)inObjects
{
    NSDictionary		*objects = [inToolbarItem configurationObjects];
    AIListContact		*object = [objects objectForKey:@"ContactObject"];

    BOOL			enabled = (object && [object isKindOfClass:[AIListContact class]]);

    [inToolbarItem setEnabled:enabled];
//    return(enabled);
    return(YES);
}

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
    BOOL valid = YES;

    if(menuItem == viewContactInfoMenuItem || menuItem == viewContactInfoMenuItem_alternate){
        AIListContact	*selectedContact = [[owner contactController] selectedContact];

        if(selectedContact && [selectedContact isKindOfClass:[AIListContact class]]){
            [menuItem setTitle:[NSString stringWithFormat:@"View %@'s Info",[selectedContact displayName]]];
        }else{
            [menuItem setTitle:@"View Contact's Info"];
            valid = NO;
        }
    }else if(menuItem == getInfoContextMenuItem){
        AIListContact	*selectedContact = [[owner menuController] contactualMenuContact];
        if ( !(selectedContact && [selectedContact isKindOfClass:[AIListContact class]]) )
            valid = NO;
    }
    return(valid);
}


@end

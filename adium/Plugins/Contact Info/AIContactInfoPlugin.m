//
//  AIContactInfoPlugin.m
//  Adium
//
//  Created by Adam Iser on Wed Jun 11 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIContactInfoPlugin.h"
#import "AIInfoWindowController.h"
#import <AIUtilities/AIUtilities.h>

@interface AIContactInfoPlugin (PRIVATE)

@end

@implementation AIContactInfoPlugin

- (void)installPlugin
{
    AIMiniToolbarItem *toolbarItem;

    //Install the 'view profile' menu item
    viewContactInfoMenuItem = [[NSMenuItem alloc] initWithTitle:@"View Contact's Info" target:self action:@selector(showContactInfo:) keyEquivalent:@"I"];
    [[owner menuController] addMenuItem:viewContactInfoMenuItem toLocation:LOC_Contact_Manage];

    //Add our get info contextual menu item
    getInfoContextMenuItem = [[NSMenuItem alloc] initWithTitle:@"View Info" target:self action:@selector(showContextContactInfo:) keyEquivalent:@""];
    [[owner menuController] addContextualMenuItem:getInfoContextMenuItem toLocation:Context_Contact_Manage];

    //Add our get info toolbar item
    toolbarItem = [[AIMiniToolbarItem alloc] initWithIdentifier:@"ShowInfo"];
    [toolbarItem setImage:[AIImageUtilities imageNamed:@"info" forClass:[self class]]];
    [toolbarItem setTarget:self];
    [toolbarItem setAction:@selector(toolbarShowInfo:)];
    [toolbarItem setEnabled:YES];
    [toolbarItem setToolTip:@"Show Info"];
    [toolbarItem setPaletteLabel:@"Show Info"];
    [toolbarItem setDelegate:self];
    [[AIMiniToolbarCenter defaultCenter] registerItem:[toolbarItem autorelease]];    
}

- (IBAction)toolbarShowInfo:(AIMiniToolbarItem *)toolbarItem
{
    NSDictionary		*objects = [toolbarItem configurationObjects];
    AIListContact		*object = [objects objectForKey:@"ContactObject"];

    if([object isKindOfClass:[AIListContact class]]){
        //Show the profile window
        [AIInfoWindowController showInfoWindowWithOwner:owner forContact:object];
    }
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

    if(menuItem == viewContactInfoMenuItem){
        AIListContact	*selectedContact = [[owner contactController] selectedContact];

        if(selectedContact && [selectedContact isKindOfClass:[AIListContact class]]){
            [viewContactInfoMenuItem setTitle:[NSString stringWithFormat:@"View %@'s Info",[selectedContact displayName]]];
        }else{
            [viewContactInfoMenuItem setTitle:@"View Contact's Info"];
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

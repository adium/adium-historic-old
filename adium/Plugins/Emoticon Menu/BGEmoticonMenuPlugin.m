//
//  BGEmoticonMenuPlugin.m
//  Adium XCode
//
//  Created by Brian Ganninger on Sun Dec 14 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//
//  *currently only organized with AIM in mind, needs to be redone for all GAIM-based services, or at least more than AIM*

#import "BGEmoticonMenuPlugin.h"

@implementation BGEmoticonMenuPlugin

- (void)installPlugin
{
    // load active emoticons and create menu
    emoticons = [[adium contentController] emoticonsArray];
    if(emoticons != nil)
    {
        eMenu = [[NSMenu alloc] initWithTitle:@""];
        menuButton = [[NSPopUpButton alloc] init];
        [menuButton setImage:[NSImage imageNamed:@"EmoticonMenu"]];
        [self buildMenu]; 
        [self buildContextualMenu];
        //[self buildToolbarItem];
        // add popup button to window's toolbar
        // register for menus
        [[adium menuController] addMenuItem:quickMenuItem toLocation:LOC_Format_Additions];
        // return the new menu for the text field(s) --> needs to pass back to the prototype/additions [brian message:duh]
    }
    else
    {
        NSLog(@"polish nikes... there's no emoticons for this menu!!");
    }
}

-(void)buildContextualMenu
{
    // newContextMenu = [[[adium contentController] textEntryView] menu];
    // [newContextMenu addItem:quickMenuItem];
}


-(void)buildToolbarItem
{   
    // add to popup button
    [menuButton setMenu:eMenu];

    // Set up the standard properties 
    [toolbarItem setLabel: @"Emoticons"];
    [toolbarItem setPaletteLabel: @"Emoticon Menu"];
    [toolbarItem setToolTip: @"Menu to insert emoticons"];
    
    // Use a custom view, a popup button, for the toolbar item
    [toolbarItem setView: menuButton];
    [toolbarItem setMinSize:NSMakeSize(16,16)];
    [toolbarItem setMaxSize:NSMakeSize(32,32)];
    
    [toolbarMenu setSubmenu: eMenu];
    [toolbarMenu setTitle: [toolbarItem label]];
    [toolbarItem setMenuFormRepresentation: toolbarMenu];
}

-(void)buildMenu
{
    NSEnumerator *emoteEnum = [emoticons objectEnumerator];
    AIEmoticon *anEmoticon;
    // loop through each emoticon and add a menu item for each
    while(anEmoticon = [emoteEnum nextObject])
    {
        if([anEmoticon isEnabled] == YES)
        {
            NSMenuItem *newItem = [[NSMenuItem alloc] initWithTitle:[anEmoticon name] target:self action:@selector(insertEmoticon:) keyEquivalent:@""];
            [newItem setImage:[anEmoticon image]];
            [eMenu addItem:[newItem copy]];
        }
    }    
    // create a menu item for the menu to attach to
    quickMenuItem = [[NSMenuItem alloc] initWithTitle:@"Insert" target:self action:@selector(insertEmoticon:) keyEquivalent:@""];
    [quickMenuItem setSubmenu:[eMenu copy]];

}

-(void)insertEmoticon:(id)sender
{
    // Actually, since sender can be a menu item or a button, it'd be better to look up the name in the emoticons array, then get
    // the emoticon itself and ask IT for the textEquivalents, instead of asking an id sender :P
    AIEmoticon *selectedEmoticon;
    // selectedEmoticon = some really fun call or other technique :P
    NSString *emoString = [[selectedEmoticon textEquivalents] objectAtIndex:0];
    [[[[adium interfaceController] currentChat] textEntryView] insertCharacters:emoString];
}

-(NSMenu *)eMenu
{
    return eMenu;
}

-(NSToolbarItem *)toolbarItem
{
    return toolbarItem;
}

-(void)uninstallPlugin
{
    // cleanup if needed, none yet
}

-(void)dealloc
{
    [emoticons release];
    [eMenu release];
}

@end

/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2003, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
                                              \---------------------------------------------------------------------------------------------------------/
| This program is free software; you can redistribute it and/or modify it under the terms of the GNU
| General Public License as published by the Free Software Foundation; either version 2 of the License,
| or (at your option) any later version.
|
| This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
| the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
| Public License for more details.
|
| You should have received a copy of the GNU General Public License along with this program; if not,
| write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
\------------------------------------------------------------------------------------------------------ */

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
        [[adium menuController] addMenuItem:quickMenuItem toLocation:Context_TextView_EmoticonAction];
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
    AIEmoticon *selectedEmoticon = [emoticons objectAtIndex:[[sender menu] indexOfItem:sender]];
    NSString *emoString = [[selectedEmoticon textEquivalents] objectAtIndex:0];
    //     [[[[adium interfaceController] currentChat] textEntryView] insertText:emoString];
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

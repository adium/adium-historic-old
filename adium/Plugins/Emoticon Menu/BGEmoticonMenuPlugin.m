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

#import "BGEmoticonMenuPlugin.h"

@implementation BGEmoticonMenuPlugin

#define PREF_GROUP_EMOTICONS			@"Emoticons"

- (void)installPlugin
{
    quickMenuItem = [[NSMenuItem alloc] initWithTitle:@"Emoticons" target:self action:nil keyEquivalent:@""];
    //Observe prefs    
    [[adium notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    [self configureEmoticonSupport];
}

- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil || [PREF_GROUP_EMOTICONS compare:[[notification userInfo] objectForKey:@"Group"]] == 0)
    {        
        [[adium menuController] removeMenuItem:quickMenuItem];
        [self configureEmoticonSupport];
    }
}

-(void)configureEmoticonSupport
{
    // load active emoticons and create menu
    emoticonPacks = [[adium contentController] emoticonPacks];
    if(emoticonPacks != nil && [emoticonPacks count] > 1)
    {
        id object;
        int locTrack = 0;
        NSEnumerator *packEnum = [emoticonPacks objectEnumerator];
        eMenu = [[NSMenu alloc] initWithTitle:@""];
        while(object = [packEnum nextObject])
        {
            // read out each pack, iterate it and add its contents to its menu, then add it to its menu item
            NSMenuItem *packItem = [[NSMenuItem alloc] initWithTitle:[object name] action:nil keyEquivalent:@""];
            [packItem setTag:locTrack];
            [packItem setSubmenu:[self buildMenu:object]]; 
            [eMenu addItem:packItem];
            locTrack++;
        }
        // create a menu item for the menu to attach to
        [quickMenuItem setSubmenu:eMenu];
        // register for menus
        [[adium menuController] addMenuItem:quickMenuItem toLocation:LOC_Format_Additions];
        [[adium menuController] addContextualMenuItem:quickMenuItem toLocation:Context_TextView_EmoticonAction];
    }
    else if([emoticonPacks count] == 1)
    {
        quickMenuItem = [[NSMenuItem alloc] initWithTitle:@"Emoticons" target:self action:nil keyEquivalent:@""];
        eMenu = [self buildMenu:[emoticonPacks objectAtIndex:0]];
        [quickMenuItem setSubmenu:eMenu];
        [[adium menuController] addMenuItem:quickMenuItem toLocation:LOC_Format_Additions];        
        [[adium menuController] addContextualMenuItem:quickMenuItem toLocation:Context_TextView_EmoticonAction];
    }
    else
    {
        quickMenuItem = [[NSMenuItem alloc] initWithTitle:@"Emoticons" target:self action:nil keyEquivalent:@""];
        [quickMenuItem setEnabled:NO];
        [[adium menuController] addMenuItem:quickMenuItem toLocation:LOC_Format_Additions];
        [[adium menuController] addContextualMenuItem:quickMenuItem toLocation:Context_TextView_EmoticonAction];
    }    
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

-(NSMenu *)buildMenu:(AIEmoticonPack *)incomingPack
{
    NSEnumerator *emoteEnum = [[incomingPack emoticons] objectEnumerator];
    AIEmoticon *anEmoticon;
    NSMenu *packMenu = [[NSMenu alloc] initWithTitle:@""];
    // loop through each emoticon and add a menu item for each
    while(anEmoticon = [emoteEnum nextObject])
    {
        if([anEmoticon isEnabled] == YES)
        {
            NSMenuItem *newItem = [[NSMenuItem alloc] initWithTitle:[anEmoticon name] target:self action:@selector(insertEmoticon:) keyEquivalent:@""];
            [newItem setImage:[anEmoticon image]];
            [packMenu addItem:newItem];
            //[eMenu addItem:[newItem copy]];
        }
    }    
    return packMenu;
}

-(void)insertEmoticon:(id)sender
{
    NSString *emoString;
    // Actually, since sender can be a menu item or a button, it'd be better to look up the name in the emoticon pack's emoticons array,
    // then get the emoticon itself and ask IT for the textEquivalents, instead of asking an id sender :P
    if([emoticonPacks count] == 1)
    {    
        AIEmoticon *selectedEmoticon = [[[emoticonPacks objectAtIndex:0] emoticons] objectAtIndex:[[sender menu] indexOfItem:sender]];
        emoString = [[selectedEmoticon textEquivalents] objectAtIndex:0];
    }
    else if([emoticonPacks count] > 1)
    {
        AIEmoticonPack *selectedPack;
        AIEmoticon *selectedEmoticon;
        id object;
        NSEnumerator *menuEnum = [[eMenu itemArray] objectEnumerator];
        while(object = [menuEnum nextObject])
        {
            if([object submenu] == [sender menu])
            {
                selectedPack = [emoticonPacks objectAtIndex:[[eMenu itemArray] indexOfObject:object]];
            }
        }
        selectedEmoticon = [[selectedPack emoticons] objectAtIndex:[[sender menu] indexOfItem:sender]];
        emoString = [[selectedEmoticon textEquivalents] objectAtIndex:0];
    }
    NSResponder *responder = [[[NSApplication sharedApplication] keyWindow] firstResponder];
    if([responder isKindOfClass:[NSTextView class]] && [(NSTextView *)responder isEditable]){
        [responder insertText:emoString];
    }
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
    [emoticonPacks release];
    [eMenu release];
}

@end

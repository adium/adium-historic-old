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
@interface BGEmoticonMenuPlugin(PRIVATE)
-(void)configureEmoticonSupport;
@end
@implementation BGEmoticonMenuPlugin

#define PREF_GROUP_EMOTICONS			@"Emoticons"

//some static declarations to make things easier. Only need to add to menus once.
static NSMenuItem   *quickMenuItem = nil;
static NSMenuItem   *quickContextualMenuItem = nil;
static NSMenu       *eMenu = nil;
static NSMenu       *eContextualMenu = nil;

- (void)installPlugin
{
    //init the menues and menuItems
    quickMenuItem = [[NSMenuItem alloc] initWithTitle:@"Insert Emoticon" target:self action:@selector(dummyTarget:) keyEquivalent:@""];
    quickContextualMenuItem = [[NSMenuItem alloc] initWithTitle:@"Insert Emoticon" target:self action:nil keyEquivalent:@""];
    eMenu = [[NSMenu alloc] initWithTitle:@""];
    eContextualMenu = [[NSMenu alloc] initWithTitle:@""];
    
    // configure emoticon menues
    [self configureEmoticonSupport];
    
    [quickMenuItem setSubmenu:eMenu];
    [quickContextualMenuItem setSubmenu:eContextualMenu];
    
    //add the items to their menus.
    [[adium menuController] addContextualMenuItem:quickContextualMenuItem toLocation:Context_TextView_EmoticonAction];    
    [[adium menuController] addMenuItem:quickMenuItem toLocation:LOC_Edit_Additions];
    
    //Observe prefs    
    [[adium notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
}

- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil || [PREF_GROUP_EMOTICONS compare:[[notification userInfo] objectForKey:@"Group"]] == 0)
    {        
        [self configureEmoticonSupport];
    }
}

-(void)configureEmoticonSupport
{
    [quickMenuItem setEnabled:YES];
    [quickContextualMenuItem setEnabled:YES];
    [eMenu removeAllItems];
    [eContextualMenu removeAllItems];
    
    // load active emoticons and create menu
    emoticonPacks = [[adium contentController] emoticonPacks];
    if(emoticonPacks != nil && [emoticonPacks count] > 1){
        id object;
        int locTrack = 0;
        NSEnumerator *packEnum = [emoticonPacks objectEnumerator];
       // eMenu = [[NSMenu alloc] initWithTitle:@""];
        while(object = [packEnum nextObject]){
            // read out each pack, iterate it and add its contents to its menu, then add it to its menu item
            NSMenuItem *packItem = [[NSMenuItem alloc] initWithTitle:[object name] action:nil keyEquivalent:@""];
            [packItem setTag:locTrack];
            [packItem setSubmenu:[self buildMenu:object]]; 
            [eMenu addItem:packItem];
            [eContextualMenu addItem:[packItem copy]];
            locTrack++;
        }
        // create a menu item for the menu to attach to
        //[quickMenuItem setSubmenu:eMenu];
        //[quickContextualMenuItem setSubmenu:eContextualMenu];
    }else if([emoticonPacks count] == 1){
        eMenu = [self buildMenu:[emoticonPacks objectAtIndex:0]];
        eContextualMenu = [self buildMenu:[emoticonPacks objectAtIndex:0]];
        [quickMenuItem setSubmenu:eMenu];
        [quickContextualMenuItem setSubmenu:eContextualMenu];
    }else{
        [quickMenuItem setEnabled:NO];
        [quickContextualMenuItem setEnabled:NO];
    }
    [[adium notificationCenter] postNotificationName:Menu_didChange object:quickMenuItem userInfo:nil];
    [[adium notificationCenter] postNotificationName:Menu_didChange object:quickContextualMenuItem userInfo:nil];
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

			//We need to make a copy of the emoticons for our menu, otherwise the menu flips them in an unpredictable
			//way, causing problems in the emoticon preferences
            [newItem setImage:[[[anEmoticon image] copy] autorelease]];
            [packMenu addItem:newItem];

        }
    }    
    return packMenu;
}

- (void)insertEmoticon:(id)sender
{
    NSString *emoString = nil;
    // Actually, since sender can be a menu item or a button, it'd be better to look up the name in the emoticon pack's emoticons array,
    // then get the emoticon itself and ask IT for the textEquivalents, instead of asking an id sender :P
    if([emoticonPacks count] == 1)
    {    
        AIEmoticon *selectedEmoticon = [[[emoticonPacks objectAtIndex:0] emoticons] objectAtIndex:[[sender menu] indexOfItem:sender]];
		NSLog(@"EMOTICONS 1");
        emoString = [[selectedEmoticon textEquivalents] objectAtIndex:0];
    }
    else if([emoticonPacks count] > 1)
    {
        AIEmoticonPack *selectedPack = nil;
        AIEmoticon *selectedEmoticon;
        id object;
        if([sender isKindOfClass:[NSMenuItem class]]){
            NSEnumerator *menuEnum = [[[[sender menu] supermenu] itemArray] objectEnumerator];
            while(object = [menuEnum nextObject])
            {
                if([object submenu] == [sender menu])
                {
                    selectedPack = [emoticonPacks objectAtIndex:[[[[sender menu] supermenu] itemArray] indexOfObject:object]];
                }
            }
            
            if (selectedPack) {
                    selectedEmoticon = [[selectedPack emoticons] objectAtIndex:[[sender menu] indexOfItem:sender]];
                    emoString = [[selectedEmoticon textEquivalents] objectAtIndex:0];
            }
        }

    }
		   
    NSResponder *responder = [[[NSApplication sharedApplication] keyWindow] firstResponder];
    if(emoString && [responder isKindOfClass:[NSTextView class]] && [(NSTextView *)responder isEditable]){
        NSRange tmpRange = [(NSTextView *)responder selectedRange];
        if(0 != tmpRange.length){
            [(NSTextView *)responder setSelectedRange:NSMakeRange((tmpRange.location + tmpRange.length),0)];
        }
        [responder insertText:emoString];
    }
}

//Just a target so we get the validateMenuItem: call for the emoticon menu
-(IBAction)dummyTarget:(id)sender{
}

//Disable the emoticon menu if a text field is not active
- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
	NSResponder	*responder = [[[NSApplication sharedApplication] keyWindow] firstResponder];
	return(responder && [responder isKindOfClass:[NSText class]]);
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

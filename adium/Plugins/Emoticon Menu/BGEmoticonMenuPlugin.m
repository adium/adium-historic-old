/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2004, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

- (void)installPlugin
{
    //init the menues and menuItems
    quickMenuItem = [[NSMenuItem alloc] initWithTitle:@"Insert Emoticon" target:self action:@selector(dummyTarget:) keyEquivalent:@""];
    quickContextualMenuItem = [[NSMenuItem alloc] initWithTitle:@"Insert Emoticon" target:self action:nil keyEquivalent:@""];

    //add the items to their menus.
    [[adium menuController] addContextualMenuItem:quickContextualMenuItem toLocation:Context_TextView_EmoticonAction];    
    [[adium menuController] addMenuItem:quickMenuItem toLocation:LOC_Edit_Additions];

    // configure emoticon menues
    [self configureEmoticonSupport];

    //Observe prefs    
    [[adium notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
}

- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil || [PREF_GROUP_EMOTICONS isEqualToString:[[notification userInfo] objectForKey:@"Group"]]){
        [self configureEmoticonSupport];
    }
}

- (void)configureEmoticonSupport
{
	int numberOfEmoticonPacks;
	
    // load active emoticons and create menu
    emoticonPacks = [[adium contentController] emoticonPacks];
	if(emoticonPacks && (numberOfEmoticonPacks = [emoticonPacks count])){
		
		NSMenu			*eMenu;
		//Enable the root menu items
		[quickMenuItem setEnabled:YES];
		[quickContextualMenuItem setEnabled:YES];
		
		if(numberOfEmoticonPacks == 1){
			//The submenu is just the menu for the lone emoticon pack
			eMenu = [self buildMenu:[emoticonPacks objectAtIndex:0]];
		
		}else{
			NSEnumerator	*packEnum = [emoticonPacks objectEnumerator];
			AIEmoticonPack  *pack;
			int				locTrack = 0;
			
			eMenu = [[[NSMenu alloc] initWithTitle:@""] autorelease];
			[eMenu setMenuChangedMessagesEnabled:NO];
			while(pack = [packEnum nextObject]){
				// read out each pack, iterate it and add its contents to its menu, then add it to its menu item
				NSMenuItem *packItem = [[NSMenuItem alloc] initWithTitle:[pack name] action:nil keyEquivalent:@""];
				
				[packItem setTag:locTrack];
				[packItem setSubmenu:[self buildMenu:pack]]; 
				
				[eMenu addItem:packItem];
				[packItem release];
				
				locTrack++;
			}
			[eMenu setMenuChangedMessagesEnabled:NO];
		}
		
		//Set the submenus to the menu we just created
		[quickMenuItem setSubmenu:eMenu];
		[quickContextualMenuItem setSubmenu:[[eMenu copy] autorelease]];
		
		//[self _buildToolbarItemWithMenu:[[eMenu copy] autorelease]];
    }else{
		//No emoticon packs, so disable the root menu items
        [quickMenuItem setEnabled:NO];
        [quickContextualMenuItem setEnabled:NO];
    }
}

/*
- (void)_buildToolbarItemWithMenu:(NSMenu *)eMenu
{   
    // add to popup button
    [menuButton setMenu:eMenu];

    // Set up the standard properties 
    [toolbarItem setLabel:AILocalizedString(@"Emoticons",nil)];
    [toolbarItem setPaletteLabel:AILocalizedString(@"Emoticon Menu",nil)];
    [toolbarItem setToolTip:AILocalizedString(@"Menu to insert emoticons",nil)];
    
    // Use a custom view, a popup button, for the toolbar item
    [toolbarItem setView: menuButton];
    [toolbarItem setMinSize:NSMakeSize(16,16)];
    [toolbarItem setMaxSize:NSMakeSize(32,32)];
    
    [toolbarMenu setSubmenu: eMenu];
    [toolbarMenu setTitle: [toolbarItem label]];
    [toolbarItem setMenuFormRepresentation: toolbarMenu];
}
*/

- (NSMenu *)buildMenu:(AIEmoticonPack *)incomingPack
{
    NSEnumerator	*emoteEnum = [[incomingPack emoticons] objectEnumerator];
    AIEmoticon		*anEmoticon;
    NSMenu			*packMenu = [[NSMenu alloc] initWithTitle:@""];
	
	[packMenu setMenuChangedMessagesEnabled:NO];
	
    // loop through each emoticon and add a menu item for each
    while(anEmoticon = [emoteEnum nextObject]){
        if([anEmoticon isEnabled] == YES){
            NSMenuItem *newItem = [[NSMenuItem alloc] initWithTitle:[anEmoticon name]
															 target:self
															 action:@selector(insertEmoticon:)
													  keyEquivalent:@""];

			//We need to make a copy of the emoticons for our menu, otherwise the menu flips them in an unpredictable
			//way, causing problems in the emoticon preferences
            [newItem setImage:[[[anEmoticon image] copy] autorelease]];

			[newItem setRepresentedObject:anEmoticon];
			[packMenu addItem:newItem];
			
			[newItem release];
        }
    }
    
	[packMenu setMenuChangedMessagesEnabled:YES];
	
    return([packMenu autorelease]);
}

- (void)insertEmoticon:(id)sender
{
	if([sender isKindOfClass:[NSMenuItem class]]){
		NSString *emoString = [[[sender representedObject] textEquivalents] objectAtIndex:0];
		
		NSResponder *responder = [[[NSApplication sharedApplication] keyWindow] firstResponder];
		if(emoString && [responder isKindOfClass:[NSTextView class]] && [(NSTextView *)responder isEditable]){
			NSRange tmpRange = [(NSTextView *)responder selectedRange];
			if(0 != tmpRange.length){
				[(NSTextView *)responder setSelectedRange:NSMakeRange((tmpRange.location + tmpRange.length),0)];
			}
			[responder insertText:emoString];
		}
    }
}

//Just a target so we get the validateMenuItem: call for the emoticon menu
- (IBAction)dummyTarget:(id)sender{
}

//Disable the emoticon menu if a text field is not active
- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
	NSResponder	*responder = [[[NSApplication sharedApplication] keyWindow] firstResponder];
	if(responder && [responder isKindOfClass:[NSText class]]){
            return [(NSText *)responder isEditable];
        }else{
            return NO;
        }
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
}

@end

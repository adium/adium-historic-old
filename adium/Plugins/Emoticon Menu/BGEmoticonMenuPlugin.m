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
- (void)preferencesChanged:(NSNotification *)notification;
- (void)registerToolbarItem;
@end

@implementation BGEmoticonMenuPlugin

#define PREF_GROUP_EMOTICONS			@"Emoticons"

- (void)installPlugin
{
    //init the menues and menuItems
    quickMenuItem = [[NSMenuItem alloc] initWithTitle:@"Insert Emoticon" target:self action:@selector(dummyTarget:) keyEquivalent:@""];
    quickContextualMenuItem = [[NSMenuItem alloc] initWithTitle:@"Insert Emoticon" target:self action:@selector(dummyTarget:) keyEquivalent:@""];
	needToRebuildMenus = YES;
	
    //add the items to their menus.
    [[adium menuController] addContextualMenuItem:quickContextualMenuItem toLocation:Context_TextView_EmoticonAction];    
    [[adium menuController] addMenuItem:quickMenuItem toLocation:LOC_Edit_Additions];

	
	//
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(toolbarWillAddItem:)
												 name:NSToolbarWillAddItemNotification
											   object:nil];

    
	
	
	//Observe prefs    
    [[adium notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
	[self preferencesChanged:nil];
}

//Add emoticon menu as item goes into toolbar
- (void)toolbarWillAddItem:(NSNotification *)notification
{
	NSToolbarItem	*item = [[notification userInfo] objectForKey:@"item"];
	
	if([[item itemIdentifier] isEqualToString:@"InsertEmoticon"]){
		NSMenu		*menu = [self emoticonMenu];
		
		//Add menu to view
		[[item view] setMenu:menu];
		
		//Add menu to toolbar item (for text mode)
		NSMenuItem	*mItem = [[[NSMenuItem alloc] init] autorelease];
		[mItem setSubmenu:menu];
		[mItem setTitle:[menu title]];
		[item setMenuFormRepresentation:mItem];
	}
}

//Emoticons changed
- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil || [PREF_GROUP_EMOTICONS isEqualToString:[[notification userInfo] objectForKey:@"Group"]]){		
		//Flush the cached emoticon menu
		[emoticonMenu release]; emoticonMenu = nil;
		
		//Flag our menus as dirty
		[self registerToolbarItem];
		needToRebuildMenus = YES;
    }
}

//Register our toolbar item with the most current emoticon menu
//We cannot change the menu dynamically because there is no reliable way to keep track of all the allocated toolbar
//items
- (void)registerToolbarItem
{
	MVMenuButton *button;
	
	//Unregister the existing toolbar item first
	if(toolbarItem){
		[[adium toolbarController] unregisterToolbarItem:toolbarItem forToolbarType:@"TextEntry"];
		[toolbarItem release]; toolbarItem = nil;
	}
	
	//Register our toolbar item
	button = [[[MVMenuButton alloc] initWithFrame:NSMakeRect(0,0,32,32)] autorelease];
	[button setImage:[NSImage imageNamed:@"emoticonToolbar" forClass:[self class]]];
	toolbarItem = [[AIToolbarUtilities toolbarItemWithIdentifier:@"InsertEmoticon"
														   label:@"Emoticon"
													paletteLabel:@"Insert Emoticon"
														 toolTip:@"Insert Emoticon"
														  target:self
												 settingSelector:@selector(setView:)
													 itemContent:button
														  action:@selector(insertEmoticon:)
															menu:nil] retain];
	[button setToolbarItem:toolbarItem];
    [[adium toolbarController] registerToolbarItem:toolbarItem forToolbarType:@"TextEntry"];
}


//Menu Generation ------------------------------------------------------------------------------------------------------
#pragma mark Menu Generation
//Build the entire emoticon menu
- (NSMenu *)emoticonMenu
{
	if(!emoticonMenu){
		NSArray		*emoticonPacks = [[adium contentController] emoticonPacks];
		NSLog(@"####### Buidling emoticon menu");
		if([emoticonPacks count] == 1){
			//If there is only 1 emoticon pack loaded, do not create submenus
			emoticonMenu = [[self flatEmoticonMenuForPack:[emoticonPacks objectAtIndex:0]] retain];

		}else{
			NSEnumerator	*packEnum = [emoticonPacks objectEnumerator];
			AIEmoticonPack  *pack;
			NSMenuItem 		*packItem;
			
			emoticonMenu = [[NSMenu alloc] initWithTitle:@""];
			
			[emoticonMenu setMenuChangedMessagesEnabled:NO];
			while(pack = [packEnum nextObject]){
				packItem = [[NSMenuItem alloc] initWithTitle:[pack name] action:nil keyEquivalent:@""];
				[packItem setSubmenu:[self flatEmoticonMenuForPack:pack]]; 
				[emoticonMenu addItem:packItem];
				[packItem release];
			}
			[emoticonMenu setMenuChangedMessagesEnabled:YES];
		}

		return(emoticonMenu);
	}else{
		NSLog(@"####### copying emoticon menu");
		return([[emoticonMenu copy] autorelease]);
	}
}

//Build a flat emoticon menu for a single pack
- (NSMenu *)flatEmoticonMenuForPack:(AIEmoticonPack *)incomingPack
{
    NSMenu			*packMenu = [[NSMenu alloc] initWithTitle:@"Emoticon"];
    NSEnumerator	*emoteEnum = [[incomingPack emoticons] objectEnumerator];
    AIEmoticon		*anEmoticon;
	
	[packMenu setMenuChangedMessagesEnabled:NO];
	
    //loop through each emoticon and add a menu item for each
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


//Menu Control ---------------------------------------------------------------------------------------------------------
#pragma mark Menu Control
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
- (IBAction)dummyTarget:(id)sender
{
	//Empty
}

//Disable the emoticon menu if a text field is not active
- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
	if(menuItem == quickMenuItem || menuItem == quickContextualMenuItem){
		BOOL	haveEmoticons = ([[[adium contentController] emoticonPacks] count] != 0);

		//Build the emoticon menus if necessary
		if(needToRebuildMenus){
			[quickMenuItem setSubmenu:[self emoticonMenu]];
			[quickContextualMenuItem setSubmenu:[self emoticonMenu]];
			needToRebuildMenus = NO;
		}

		//Disable the main emoticon menu items if no emoticons are available
		return(haveEmoticons);
		
	}else{
		//Disable the emoticon menu items if we're not in a text field
		NSResponder	*responder = [[[NSApplication sharedApplication] keyWindow] firstResponder];
		if(responder && [responder isKindOfClass:[NSText class]]){
			return([(NSText *)responder isEditable]);
		}else{
			return(NO);
		}
		
	}
}

@end

/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "AIContactController.h"
#import "AIContentController.h"
#import "AIInterfaceController.h"
#import "AIPreferenceController.h"
#import "AIToolbarController.h"
#import "ESUserIconHandlingPlugin.h"
#import <AIUtilities/AIFileManagerAdditions.h>
#import <AIUtilities/AIMutableOwnerArray.h>
#import <AIUtilities/AIToolbarUtilities.h>
#import <AIUtilities/ESImageAdditions.h>
#import <AIUtilities/ESImageButton.h>
#import <Adium/AIAccount.h>
#import <Adium/AIChat.h>
#import <Adium/AIListContact.h>
#import <Adium/AIListObject.h>
#import <Adium/AIServiceIcons.h>

@interface ESUserIconHandlingPlugin (PRIVATE)
- (BOOL)cacheAndSetUserIconFromPreferenceForListObject:(AIListObject *)inObject;
- (BOOL)_cacheUserIconData:(NSData *)inData forObject:(AIListObject *)inObject;
- (NSString *)_cachedImagePathForObject:(AIListObject *)inObject;
- (BOOL)destroyCacheForListObject:(AIListObject *)inObject;
- (void)registerToolbarItem;

- (void)_updateToolbarIconOfChat:(AIChat *)inChat inWindow:(NSWindow *)window;
@end

/*
 * @class ESUserIconHandlingPlugin
 * @brief User icon handling component
 *
 * This component manages the Adium user icon cache.  It also provides a toolbar icon which shows the user icon
 * or service icon of the current chat in its window.
 */
@implementation ESUserIconHandlingPlugin

/*
 * @brief Install
 */
- (void)installPlugin
{
	//Register our observers
    [[adium contactController] registerListObjectObserver:self];
	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_USERICONS];
	[[adium notificationCenter] addObserver:self selector:@selector(listObjectAttributesChanged:) 
									   name:ListObject_AttributesChanged
									 object:nil];

	//Toolbar item registration
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(toolbarWillAddItem:)
												 name:NSToolbarWillAddItemNotification
											   object:nil];
	[self registerToolbarItem];
}

/*
 * @brief Uninstall
 */
- (void)uninstallPlugin
{
    [[adium contactController] unregisterListObjectObserver:self];
}

/*
 * @brief Update list object
 *
 * Handle object creation and changes to the userIcon status object, which should be set by account code
 * when a user icon is retrieved for the object.
 */
- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{    
    if(inModifiedKeys == nil){
		//At object creation, load the user icon.
		
		//Only load the cached image file if we do not load from a preference
		if (![self cacheAndSetUserIconFromPreferenceForListObject:inObject]){

			//Load the cached image file by reference into the display array;
			//It will only be loaded into memory if needed
			NSString			*cachedImagePath = [self _cachedImagePathForObject:inObject];
			if ([[NSFileManager defaultManager] fileExistsAtPath:cachedImagePath]){
				NSImage				*cachedImage;
				
				cachedImage = [[NSImage alloc] initByReferencingFile:cachedImagePath];
				
				if (cachedImage) {
					
					//A cache image is used at lowest priority, since it is outdated data
					[inObject setDisplayUserIcon:cachedImage
									   withOwner:self
								   priorityLevel:Lowest_Priority];
					[inObject setStatusObject:cachedImagePath
									   forKey:@"UserIconPath"
									   notify:NotifyNever];
				}
				
				[cachedImage release];
			}
		}
		
	}else if([inModifiedKeys containsObject:KEY_USER_ICON]){
		//The status UserIcon object is set by account code; apply this to the display array and cache it if necesssary
		NSImage				*userIcon;
		NSImage				*statusUserIcon = [inObject statusObjectForKey:KEY_USER_ICON];
		
		//Apply the image at medium priority
		[inObject setDisplayUserIcon:statusUserIcon
						   withOwner:self
					   priorityLevel:Medium_Priority];
		
		//If the new objectValue is what we just set, notify and cache
		userIcon = [inObject displayUserIcon];

		if (userIcon == statusUserIcon){
			//Cache using the raw data if possible, otherwise create a TIFF representation to cache
			//Note: TIFF supports transparency but not animation
			NSData  *userIconData = [inObject statusObjectForKey:@"UserIconData"];
			[self _cacheUserIconData:(userIconData ? userIconData : [userIcon TIFFRepresentation]) forObject:inObject];

			[[adium contactController] listObjectAttributesChanged:inObject
													  modifiedKeys:[NSSet setWithObject:KEY_USER_ICON]];
		}
	}
	
	return(nil);
}

/*
 * @brief List object attributes changes
 *
 * A plugin, or this plugin, modified the display array for the object; ensure our cache is up to date.
 */
- (void)listObjectAttributesChanged:(NSNotification *)notification
{
    AIListObject	*inObject = [notification object];
    NSSet			*keys = [[notification userInfo] objectForKey:@"Keys"];
	
	if([keys containsObject:KEY_USER_ICON]){
		AIMutableOwnerArray *userIconDisplayArray = [inObject displayArrayForKey:KEY_USER_ICON];
		NSImage *userIcon = [userIconDisplayArray objectValue];
		NSImage *ownedUserIcon = [userIconDisplayArray objectWithOwner:self];
		
		//If the new user icon is not the same as the one we set in updateListObject: 
		//(either cached or not), update the cache
		if (userIcon != ownedUserIcon){
			AIChat	*chat;
			
			[self _cacheUserIconData:[userIcon TIFFRepresentation] forObject:inObject];

			//Update the icon in the toolbar for this contact if a chat is open and we have any toolbar items
			if(([toolbarItems count] > 0) &&
			   [inObject isKindOfClass:[AIListContact class]] &&
			   (chat = [[adium contentController] existingChatWithContact:(AIListContact *)inObject])){
				[self _updateToolbarIconOfChat:chat 
									  inWindow:[[adium interfaceController] windowForChat:chat]];
			}
		}
	}
}

/*
 * @brief The user icon preference was changed
 */
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	if(object){
		if(![self cacheAndSetUserIconFromPreferenceForListObject:object]){
			[self destroyCacheForListObject:object];
		}
	}
}

/*
 * @brief Cache and set the user icon from a listObject's preference
 *
 * This loads the user-set preference for a listObject, sets it at highest priority, and then caches the
 * newly set image.
 *
 * @param inObject The listObject to modify if necessary.
 * @result YES if the method resulted in setting an image
 */
- (BOOL)cacheAndSetUserIconFromPreferenceForListObject:(AIListObject *)inObject
{
	NSData  *imageData = [inObject preferenceForKey:KEY_USER_ICON 
											  group:PREF_GROUP_USERICONS
							  ignoreInheritedValues:YES];
	
	//A preference is used at highest priority
	if (imageData){
		NSImage	*image;
		
		image = [[NSImage alloc] initWithData:imageData];
		[inObject setDisplayUserIcon:image
						   withOwner:self
					   priorityLevel:Highest_Priority];
		[image release];
		
		return YES;
	}else{
		//If we had a preference set before (that is, there's an object set at Highest_Priority), clear it
		if ([[inObject displayArrayForKey:KEY_USER_ICON create:NO] priorityOfObjectWithOwner:self] == Highest_Priority){
			
			[inObject setDisplayUserIcon:nil
							   withOwner:self
						   priorityLevel:Highest_Priority];
		}
	}
	
	return NO;
}

/*
 - (BOOL)_cacheUserIcon:(NSImage *)inImage forObject:(AIListObject *)inObject
 {
	 BOOL		success = NO;
	 NSString	*cachedImagePath = [self _cachedImagePathForObject:inObject];
	 
	 
	 NSBitmapImageRep* imageRep = [[inImage representations] objectAtIndex:0];
	 unsigned char *imageBytes = [imageRep bitmapData];
	 NSData  *imageData = [NSData dataWithBytes:imageBytes 
										 length:[imageRep bytesPerRow] * [imageRep pixelsHigh]];
	 success = ([imageData writeToFile:cachedImagePath
							atomically:YES]);
	 if (success){
		 [inObject setStatusObject:cachedImagePath 
							forKey:@"UserIconPath"
							notify:YES];
	 }
	 
	 return success;
 }
 */

/*
 * @brief Cache user icon data for an object
 *
 * @param inData Image data to cache
 * @param inObject AIListObject to cache the data for
 *
 * @result YES if successful
 */
- (BOOL)_cacheUserIconData:(NSData *)inData forObject:(AIListObject *)inObject
{
	BOOL		success;
	NSString	*cachedImagePath = [self _cachedImagePathForObject:inObject];

	success = ([inData writeToFile:cachedImagePath
						atomically:YES]);
	if (success){
		[inObject setStatusObject:cachedImagePath 
						   forKey:@"UserIconPath"
						   notify:YES];
	}
	
	return success;
}
/*
 * @brief Trash a list object's cached icon
 *
 * @result YES if successful
 */
- (BOOL)destroyCacheForListObject:(AIListObject *)inObject
{
	NSString	*cachedImagePath = [self _cachedImagePathForObject:inObject];
	BOOL		success;
	
	if(success = [[NSFileManager defaultManager] trashFileAtPath:cachedImagePath]){
		[inObject setStatusObject:nil 
						   forKey:@"UserIconPath"
						   notify:YES];
	}
	
	return (success);
}

/*
 * @brief Retrieve the path at which to cache an <tt>AIListObject</tt>'s image
 */
- (NSString *)_cachedImagePathForObject:(AIListObject *)inObject
{
	return [[adium cachesPath] stringByAppendingPathComponent:[inObject internalObjectID]];
}

#pragma mark Toolbar Item

/*
 * @brief Register our toolbar item
 *
 * Our toolbar item shows an image for the current chat, displaying it full size/animating if clicked.
 */
- (void)registerToolbarItem
{
	ESImageButton	*button;
	NSToolbarItem	*toolbarItem;
	
	toolbarItems = [[NSMutableSet alloc] init];
	
	//Toolbar item registration
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(toolbarWillAddItem:)
												 name:NSToolbarWillAddItemNotification
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(toolbarDidRemoveItem:)
												 name:NSToolbarDidRemoveItemNotification
											   object:nil];

	button = [[ESImageButton alloc] initWithFrame:NSMakeRect(0,0,32,32)];
	toolbarItem = [AIToolbarUtilities toolbarItemWithIdentifier:@"UserIcon"
														  label:AILocalizedString(@"Icon",nil)
												   paletteLabel:AILocalizedString(@"Contact Icon",nil)
														toolTip:AILocalizedString(@"Show this contact's icon",nil)
														 target:self
												settingSelector:@selector(setView:)
													itemContent:button
														 action:@selector(dummyAction:)
														   menu:nil];

	[toolbarItem setMinSize:NSMakeSize(32,32)];
	[toolbarItem setMaxSize:NSMakeSize(32,32)];
	[button setToolbarItem:toolbarItem];
	[button setImage:[NSImage imageNamed:@"userIconToolbar" forClass:[self class]]];
	[button release];

	//Register our toolbar item
	[[adium toolbarController] registerToolbarItem:toolbarItem forToolbarType:@"MessageWindow"];
}

/*
 * @brief After the toolbar has added the item we can set up the submenus
 */
- (void)toolbarWillAddItem:(NSNotification *)notification
{
	NSToolbarItem	*item = [[notification userInfo] objectForKey:@"item"];
	
	if([[item itemIdentifier] isEqualToString:@"UserIcon"]){
		[item setEnabled:YES];
		
		//If this is the first item added, start observing for chats becoming visible so we can update the icon
		if([toolbarItems count] == 0){
			[[adium notificationCenter] addObserver:self
										   selector:@selector(chatDidBecomeVisible:)
											   name:@"AIChatDidBecomeVisible"
											 object:nil];
		}
		
		[toolbarItems addObject:item];
	}
}

/*
 * @brief Toolbar removed an item.
 *
 * If the item is one of ours, stop tracking it.
 *
 * @param notification Notification with an @"item" userInfo key for an NSToolbarItem.
 */
- (void)toolbarDidRemoveItem: (NSNotification *)notification
{
	NSToolbarItem	*item = [[notification userInfo] objectForKey:@"item"];
	if([toolbarItems containsObject:item]){
		[toolbarItems removeObject:item];
		
		if([toolbarItems count] == 0){
			[[adium notificationCenter] removeObserver:self
												  name:@"AIChatDidBecomeVisible"
												object:nil];
		}
	}
}

/*
 * @brief A chat became visible in a window.
 *
 * Update the item with the @"UserIcon" identifier if necessary
 *
 * @param notification Notification with an AIChat object and an @"NSWindow" userInfo key 
 */
- (void)chatDidBecomeVisible:(NSNotification *)notification
{
	[self _updateToolbarIconOfChat:[notification object]
						  inWindow:[[notification userInfo] objectForKey:@"NSWindow"]];
}

/*
 * @brief Update the user image toolbar icon in a chat
 *
 * @param chat The chat for which to retrieve an image
 * @param window The window in which the chat resides
 */
- (void)_updateToolbarIconOfChat:(AIChat *)chat inWindow:(NSWindow *)window
{
	NSToolbar		*toolbar = [window toolbar];
	NSEnumerator	*enumerator = [[toolbar items] objectEnumerator];
	NSToolbarItem	*item;
	
	while(item = [enumerator nextObject]){
		if([[item itemIdentifier] isEqualToString:@"UserIcon"]){
			AIListContact	*listContact;
			NSImage			*image;
			
			if((listContact = [chat listObject]) && ![chat name]){
				image = [listContact userIcon];
				
				//Use the serviceIcon if no image can be found
				if(!image) image = [AIServiceIcons serviceIconForObject:listContact
																   type:AIServiceIconLarge
															  direction:AIIconNormal];
			}else{
				//If we have no listObject or we have a name, we are a group chat and
				//should use the account's service icon
				image = [AIServiceIcons serviceIconForObject:[chat account]
														type:AIServiceIconLarge
												   direction:AIIconNormal];
			}
			
			[(ESImageButton *)[item view] setImage:image];
			
			break;
		}
	}	
}

/*
 * @brief Empty action for menu item validation purposes
 */
- (IBAction)dummyAction:(id)sender {};

@end

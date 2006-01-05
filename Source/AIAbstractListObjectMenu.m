//
//  AIAbstractListObjectMenu.m
//  Adium
//
//  Created by Adam Iser on 5/31/05.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "AIAbstractListObjectMenu.h"
#import <AIUtilities/AIImageAdditions.h>
#import <Adium/AIListObject.h>
#import <Adium/AIServiceIcons.h>
#import <Adium/AIStatusIcons.h>

@interface AIAbstractListObjectMenu (PRIVATE)
- (void)_destroyMenuItems;
@end

@implementation AIAbstractListObjectMenu

/*!
 * @brief Init
 */
- (id)init
{
	if((self = [super init])){
		//Rebuild our menu when Adium's status or service icon set changes
		[[adium notificationCenter] addObserver:self
									   selector:@selector(rebuildMenu)
										   name:AIStatusIconSetDidChangeNotification
										 object:nil];
		
		[[adium notificationCenter] addObserver:self
									   selector:@selector(rebuildMenu)
										   name:AIServiceIconSetDidChangeNotification
										 object:nil];
	}
	
	return self;
}

/*!
 * @brief Dealloc
 */
- (void)dealloc
{
	[[adium notificationCenter] removeObserver:self name:AIStatusIconSetDidChangeNotification object:nil];
	[[adium notificationCenter] removeObserver:self name:AIServiceIconSetDidChangeNotification object:nil];
	[self _destroyMenuItems];

	[super dealloc];
}

/*!
 * @brief Returns an array of menu items
 */
- (NSArray *)menuItems
{
	if(!menuItems){
		menuItems = [[self buildMenuItems] retain];
	}
	
	return menuItems;
}

/*!
 * @brief Returns a menu containing our menu items
 *
 * Remember that menu items can only be in one menu at a time, so if you use this functions you cannot do anything
 * manually the menu items
 */
- (NSMenu *)menu
{
	if(!menu){
		NSEnumerator	*enumerator = [[self menuItems] objectEnumerator];
		NSMenuItem		*menuItem;
		
		menu = [[NSMenu allocWithZone:[NSMenu zone]] init];
		
		[menu setMenuChangedMessagesEnabled:NO];
		while((menuItem = [enumerator nextObject])) [menu addItem:menuItem];
		[menu setMenuChangedMessagesEnabled:YES];
	}
	
	return menu;
}

/*!
 * @brief Returns the existing menu item
 *
 * @param object 
 * @return NSMenuItem 
 */
- (NSMenuItem *)menuItemWithRepresentedObject:(id)object
{
	NSEnumerator	*enumerator = [[self menuItems] objectEnumerator];
	NSMenuItem		*menuItem;
	
	while((menuItem = [enumerator nextObject])){    
		if([menuItem representedObject] == object) return menuItem;
	}
	
	return nil;
}

/*!
 * @brief Rebuild the menu
 */
- (void)rebuildMenu
{
	[self _destroyMenuItems];
}

/*!
 * @brief Destroy menu items
 */
- (void)_destroyMenuItems
{
	[menu release]; menu = nil;
	[menuItems release]; menuItems = nil;	
}


//For Subclasses -------------------------------------------------------------------------------------------------------
#pragma mark For Subclasses
/*!
 * @brief Builds and returns an array of menu items which should be in the listObjectMenu
 *
 * Subclass this method to build and return the menu items you want.
 */
- (NSArray *)buildMenuItems
{
	return [NSArray array];
}

/*!
 * @brief Returns a menu image for the account
 */
- (NSImage *)imageForListObject:(AIListObject *)listObject
{
	NSImage	*statusIcon, *serviceIcon;
	NSSize	statusSize, serviceSize, compositeSize;
	NSRect	compositeRect;
	
	//Get the service and status icons
	statusIcon = [AIStatusIcons statusIconForListObject:listObject type:AIStatusIconList direction:AIIconNormal];
	statusSize = [statusIcon size];
	serviceIcon = [AIServiceIcons serviceIconForObject:listObject type:AIServiceIconSmall direction:AIIconNormal];	
	serviceSize = [serviceIcon size];
	
	//Composite them side by side (since we're only allowed one image in a menu and we want to see both)
	compositeSize = NSMakeSize(statusSize.width + serviceSize.width + 1,
							   statusSize.height > serviceSize.height ? statusSize.height : serviceSize.height);
	compositeRect = NSMakeRect(0, 0, compositeSize.width, compositeSize.height);
	
	//Render the image
	NSImage	*composite = [[NSImage alloc] initWithSize:compositeSize];
	[composite lockFocus];
	[statusIcon drawInRect:compositeRect atSize:[statusIcon size] position:IMAGE_POSITION_LEFT fraction:1.0];
	[serviceIcon drawInRect:compositeRect atSize:[serviceIcon size] position:IMAGE_POSITION_RIGHT fraction:1.0];
	[composite unlockFocus];
	
	return [composite autorelease];
}

@end

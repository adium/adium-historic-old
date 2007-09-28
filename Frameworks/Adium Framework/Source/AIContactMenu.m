//
//  AIContactMenu.m
//  Adium
//
//  Created by Adam Iser on 5/31/05.
//  Copyright 2006 The Adium Team. All rights reserved.
//

#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AISortController.h>
#import <Adium/AIContactMenu.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <Adium/AIListContact.h>
#import <Adium/AIListGroup.h>

@interface AIContactMenu (PRIVATE)
- (id)initWithDelegate:(id)inDelegate forContactsInObject:(AIListObject *)inContainingObject;
- (NSArray *)contactMenusForListObjects:(NSArray *)listObjects;
- (NSArray *)listObjectsForContainedObjects:(NSArray *)listObjects;
- (void)_updateMenuItem:(NSMenuItem *)menuItem;
@end

@implementation AIContactMenu

/*!
 * @brief Create a new contact menu
 * @param inDelegate Delegate in charge of adding menu items
 * @param inContainingObject Containing contact whose contents will be displayed in the menu
 */
+ (id)contactMenuWithDelegate:(id)inDelegate forContactsInObject:(AIListObject *)inContainingObject
{
	return [[[self alloc] initWithDelegate:inDelegate forContactsInObject:inContainingObject] autorelease];
}

/*!
 * @brief Init
 * @param inDelegate Delegate in charge of adding menu items
 * @param inContainingObject Containing contact whose contents will be displayed in the menu
 */
- (id)initWithDelegate:(id)inDelegate forContactsInObject:(AIListObject *)inContainingObject
{
	if ((self = [super init])) {
		[self setDelegate:inDelegate];
		containingObject = [inContainingObject retain];

		// Register as a list observer
		[[adium contactController] registerListObjectObserver:self];
		
		// Register for contact list order notifications (so we can update our sorting)
		[[adium notificationCenter] addObserver:self
								   selector:@selector(rebuildMenu)
									   name:Contact_OrderChanged
									 object:nil];

		[self rebuildMenu];
	}
	
	return self;
}

- (void)dealloc
{
	[[adium contactController] unregisterListObjectObserver:self];
	[[adium notificationCenter] removeObserver:self];

	[containingObject release]; containingObject = nil;
	delegate = nil;
	
	[super dealloc];
}

/*!
 * @brief Returns the existing menu item for a specific contact
 *
 * @param contact AIListContact whose menu item to return
 * @return NSMenuItem instance for the contact
 */
- (NSMenuItem *)menuItemForContact:(AIListContact *)contact
{
	return [self menuItemWithRepresentedObject:contact];
}


//Delegate -------------------------------------------------------------------------------------------------------------
#pragma mark Delegate
/*!
 * @brief Set our contact menu delegate
 */
- (void)setDelegate:(id)inDelegate
{
	delegate = inDelegate;
	
	//Ensure the the delegate implements all required selectors and remember which optional selectors it supports.
	NSParameterAssert([inDelegate respondsToSelector:@selector(contactMenu:didRebuildMenuItems:)]);
	delegateRespondsToDidSelectContact = [inDelegate respondsToSelector:@selector(contactMenu:didSelectContact:)];
	delegateRespondsToShouldIncludeContact = [inDelegate respondsToSelector:@selector(contactMenu:shouldIncludeContact:)];	
}
- (id)delegate
{
	return delegate;
}

/*!
 * @brief Inform our delegate when the menu is rebuilt
 */
- (void)rebuildMenu
{
	[super rebuildMenu];
	[delegate contactMenu:self didRebuildMenuItems:[self menuItems]];
}	

/*!
 * @brief Inform our delegate of menu selections
 */
- (void)selectContactMenuItem:(NSMenuItem *)menuItem
{
	if (delegateRespondsToDidSelectContact) {
		[delegate contactMenu:self didSelectContact:[menuItem representedObject]];
	}
}


//Contact Menu ---------------------------------------------------------------------------------------------------------
#pragma mark Contact Menu
/*!
 * @brief Build our contact menu items
 */
- (NSArray *)buildMenuItems
{
	NSArray *listObjects = [self listObjectsForContainedObjects:([containingObject conformsToProtocol:@protocol(AIContainingObject)] ?
						   [(AIListObject<AIContainingObject> *)containingObject listContacts] :
						   [NSArray arrayWithObject:containingObject])];
	
	// Sort the list objects
	listObjects = [[[adium contactController] activeSortController] sortListObjects:listObjects];
	
	// Create menus for them
	return [self contactMenusForListObjects:listObjects];
}

/*!
* @brief Creates an array of list objects which should be presented in the menu, expanding any containing objects
 */
- (NSArray *)listObjectsForContainedObjects:(NSArray *)listObjects
{
	NSMutableArray	*listObjectArray = [NSMutableArray array];
	NSEnumerator	*enumerator = [listObjects objectEnumerator];
	AIListObject	*listObject;
	
	while ((listObject = [enumerator nextObject])) {
		if ([listObject isKindOfClass:[AIListContact class]]) {
			if (!delegateRespondsToShouldIncludeContact || [delegate contactMenu:self shouldIncludeContact:(AIListContact *)listObject]) {
				[listObjectArray addObject:listObject];
			}
		} else if ([listObject conformsToProtocol:@protocol(AIContainingObject)]) {
			[listObjectArray addObjectsFromArray:[self listObjectsForContainedObjects:[(AIListObject<AIContainingObject> *)listObject listContacts]]];
		}
	}
	
	return listObjectArray;
}

/*!
* @brief Creates an array of NSMenuItems for each AIListObject
 */
- (NSArray *)contactMenusForListObjects:(NSArray *)listObjects
{
	NSMutableArray	*menuItemArray = [NSMutableArray array];
	NSEnumerator	*enumerator = [listObjects objectEnumerator];
	AIListObject	*listObject;
	
	while ((listObject = [enumerator nextObject])) {
		NSMenuItem *menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@""
																					target:self
																					action:@selector(selectContactMenuItem:)
																			 keyEquivalent:@""
																		 representedObject:listObject];
		[self _updateMenuItem:menuItem];
		[menuItemArray addObject:menuItem];
		[menuItem release];
	}
	
	return menuItemArray;
}

/*!
 * @brief Update a menu item to reflect its contact's current status
 */
- (void)_updateMenuItem:(NSMenuItem *)menuItem
{
	AIListObject	*listObject = [menuItem representedObject];
	
	if (listObject) {
		[[menuItem menu] setMenuChangedMessagesEnabled:NO];
		[menuItem setImage:[self imageForListObject:listObject]];		

		static NSDictionary *titleAttributes = nil;
		if (!titleAttributes) {
			//The default font size seems to be slightly smaller than the real font; seems to be an AppKit bug
			titleAttributes = [[NSDictionary dictionaryWithObject:[NSFont menuFontOfSize:14.0f]
														   forKey:NSFontAttributeName] retain];
		}
		NSAttributedString *title = [[NSAttributedString alloc] initWithString:[listObject displayName]
																	attributes:titleAttributes];
		[menuItem setAttributedTitle:title];
		[title release];		

		[[menuItem menu] setMenuChangedMessagesEnabled:YES];
	}
}

/*!
 * @brief Update menu when a contact's status changes
 */
- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
	if ([inObject isKindOfClass:[AIListContact class]]) {
		NSMenuItem	*menuItem = [self menuItemForContact:(AIListContact *)inObject];
		
		//Update menu items to reflect status changes
		if ([inModifiedKeys containsObject:@"Online"] ||
		   [inModifiedKeys containsObject:@"Connecting"] ||
		   [inModifiedKeys containsObject:@"Disconnecting"] ||
		   [inModifiedKeys containsObject:@"IdleSince"] ||
		   [inModifiedKeys containsObject:@"StatusType"]) {
			
			//Update the changed menu item (or rebuild the entire menu if this item should be removed or added)
			if (delegateRespondsToShouldIncludeContact) {
				BOOL shouldIncludeContact = [delegate contactMenu:self shouldIncludeContact:(AIListContact *)inObject];
				BOOL menuItemExists		  = (menuItem != nil);
				//If we disagree on item inclusion and existence, rebuild the menu.
				if (shouldIncludeContact != menuItemExists) {
					[self rebuildMenu];
				} else { 
					[self _updateMenuItem:menuItem];
				}
			} else {
				[self _updateMenuItem:menuItem];
			}
		}
	}
	
    return nil;
}

@end

//
//  AIContactList.m
//  Adium
//
//  Created by Nick Peshek on 7/15/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "AIContactList.h"
#import "AIListController.h"
#import "AIAbstractListController.h"
#import "AIListWindowController.h"
#import "AIStandardListWindowController.h"
#import "AIBorderlessListWindowController.h"
//#import "AIContactListOutlineView.h"

@implementation AIContactList
+ (AIContactList *)createWithStyle:(LIST_WINDOW_STYLE)windowStyle
{
	return [[[self alloc] createContactList:windowStyle] autorelease];
}

- (AIContactList *)createContactList:(LIST_WINDOW_STYLE)windowStyle
{
	if (windowStyle == WINDOW_STYLE_STANDARD) {
		contactListWindowController = [[AIStandardListWindowController listWindowController] retain];
	} else {
		contactListWindowController = [[AIBorderlessListWindowController listWindowController] retain];
	}
	
	return self;
}

//This has to be done after the window loads so that the List Controller is created.
- (void)finishLoading
{
	contactListController = [contactListWindowController listController];
	contactListView = [contactListController contactListView];
	groups = [[NSMutableArray array] retain];
	[self setContactListRoot:contactListRoot];
}

- (void)dealloc
{	
	[contactListWindowController release];
	[contactListRoot release];
	[groups release];
	
	[super dealloc];
}

- (void)setContactListRoot:(AIListObject<AIContainingObject> *)contactList
{
	if(contactListRoot)
	{
		contactListRoot = nil; [contactListRoot release];
	}
	contactListRoot = [contactList retain];
	
	[contactListController setContactListRoot:contactListRoot];
	[[adium notificationCenter] postNotificationName:ListObject_AttributesChanged
											  object:nil
											userInfo:nil];
	[contactListController contactListDesiredSizeChanged];
}

- (void)addContactListObject:(AIListObject *)listObject
{
	AIListObject<AIContainingObject>	*tempObject = [[self listController] contactListRoot];
	
	[tempObject addObject:listObject];
	[self setContactListRoot:tempObject];
}

- (AIListObject<AIContainingObject> *)contactList
{
	return contactListRoot;
}

- (AIOutlineView *)contactListView
{
	return contactListView;
}

- (AIListWindowController *)listWindowController
{
	return contactListWindowController;
}

- (AIListController *)listController
{
	return contactListController;
}

- (NSString *)name
{	
	AIListObject	*listObject;
	NSEnumerator	*contactEnumerator;
	if (contactListController == nil) {
		contactEnumerator = [[contactListRoot containedObjects] objectEnumerator];
	} else {
		contactEnumerator = [[[[self listController] contactListRoot] containedObjects] objectEnumerator];	
	}
	NSString		*returnString = [NSString stringWithString:@"Contacts"];
	
	while((listObject = [contactEnumerator nextObject])) {
		returnString = [returnString stringByAppendingString:[NSString stringWithFormat:@":%@", [listObject UID]]];
	}
	
	return returnString;
}

- (void)selector:(SEL)aSelector withArgument:(id)argument toItem:(CONTACT_LIST_ITEM)item
{
	switch(item)
	{
		case CONTACT_LIST_OUTLINE_VIEW: [[self contactListView] performSelector:aSelector withObject:argument]; break;
		case CONTACT_LIST_WINDOW_CONTROLLER: [[self listWindowController] performSelector:aSelector withObject:argument]; break;
		case CONTACT_LIST_CONTROLLER: [[self listController] performSelector:aSelector withObject:argument]; break;
		case CONTACT_LIST_ROOT_OBJECT: [[self contactList] performSelector:aSelector withObject:argument]; break;
		case CONTACT_LIST_WINDOW: [[[self listWindowController] window] performSelector:aSelector withObject:argument]; break;
		default: break;
	}
}
@end

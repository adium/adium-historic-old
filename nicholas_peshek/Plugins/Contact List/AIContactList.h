//
//  AIContactList.h
//  Adium
//
//  Created by Nick Peshek on 7/15/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "AIContactController.h"
#import "AIListWindowController.h"
#import "AIStandardListWindowController.h"
#import "AIBorderlessListWindowController.h"
#import "AIContactListOutlineView.h"

typedef enum {
	CONTACT_LIST_OUTLINE_VIEW = 0,
    CONTACT_LIST_WINDOW_CONTROLLER,
    CONTACT_LIST_CONTROLLER,
    CONTACT_LIST_ROOT_OBJECT,
	CONTACT_LIST_WINDOW
} CONTACT_LIST_ITEM;

@interface AIContactList : AIObject {
	
	AIListObject<AIContainingObject>	*contactListRoot;
	AIOutlineView						*contactListView;
	AIListWindowController				*contactListWindowController;
	AIListController					*contactListController;
	
	NSMutableArray						*groups;

}
+ (AIContactList *)createWithStyle:(LIST_WINDOW_STYLE)windowStyle;
- (AIContactList *)createContactList:(LIST_WINDOW_STYLE)windowStyle;
- (void)finishLoading;

- (void)setContactListRoot:(AIListObject<AIContainingObject> *)contactList;
- (void)addContactListObject:(AIListObject *)listObject;
- (AIListObject<AIContainingObject> *)contactList;
- (AIOutlineView *)contactListView;
- (AIListWindowController *)listWindowController;
- (AIListController *)listController;
- (NSString *)name;
- (void)selector:(SEL)aSelector withArgument:(id)argument toItem:(CONTACT_LIST_ITEM)item;

@end

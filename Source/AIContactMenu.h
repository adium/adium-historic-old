//
//  AIContactMenu.h
//  Adium
//
//  Created by Adam Iser on 5/31/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Adium/AIAbstractListObjectMenu.h>

@class AIAccount, AIListContact;
@protocol AIContainingObject;

@interface AIContactMenu : AIAbstractListObjectMenu <AIListObjectObserver> {
	id <AIContainingObject>	containingObject;
	
	id						delegate;
	BOOL					delegateRespondsToDidSelectContact;
	BOOL					delegateRespondsToShouldIncludeContact;	
}

+ (id)contactMenuWithDelegate:(id)inDelegate forContactsInObject:(id <AIContainingObject>)inContainingObject;

- (void)setDelegate:(id)inDelegate;
- (id)delegate;

@end

@interface NSObject (AIContactMenuDelegate)
- (void)contactMenu:(AIContactMenu *)inContactMenu didRebuildMenuItems:(NSArray *)menuItems;
- (void)contactMenu:(AIContactMenu *)inContactMenu didSelectContact:(AIListContact *)inContact; //Optional
- (BOOL)contactMenu:(AIContactMenu *)inContactMenu shouldIncludeContact:(AIListContact *)inContact; //Optional
@end

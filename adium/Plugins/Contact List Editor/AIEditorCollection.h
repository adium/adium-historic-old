//
//  AIEditorCollection.h
//  Adium
//
//  Created by Adam Iser on Sat Mar 15 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AIEditorListGroup, AIEditorListObject;

@protocol AIEditorCollection <NSObject>

- (NSString *)name;			//Large black drawer label
- (NSString *)subLabel;			//Small gray drawer text label
- (NSString *)UID;			//Used to store group collapse/expand state
- (NSImage *)icon;			//Drawer Icon
- (BOOL)enabled;			//Enabled?
- (BOOL)showOwnershipColumns;		//Display ownership/checkbox column?
- (BOOL)showCustomEditorColumns;	//Display custom columns (alias, ...)?
- (NSString *)collectionDescription;	//Window title when collection is selected
- (BOOL)includeInOwnershipColumn;	//Does this collection get a check box in the ownership column?

- (AIEditorListGroup *)list;		//Return an editor list group containing all objects

- (BOOL)containsHandleWithUID:(NSString *)UID serviceID:(NSString *)serviceID;	//Do you have this handle?

- (void)addObject:(AIEditorListObject *)inObject;					//Add the object
- (void)deleteObject:(AIEditorListObject *)inObject;					//Delete the object
- (void)renameObject:(AIEditorListObject *)inObject to:(NSString *)newName;		//Rename the object
- (void)moveObject:(AIEditorListObject *)inObject toGroup:(AIEditorListGroup *)inGroup;	//Move the object


@end

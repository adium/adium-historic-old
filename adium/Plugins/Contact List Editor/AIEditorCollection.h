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

#import <Cocoa/Cocoa.h>

@class AIEditorListGroup, AIEditorListObject, AIEditorListHandle;

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

- (NSString *)serviceID;		//The service ID of handles in this collection
- (AIEditorListGroup *)list;		//Return an editor list group containing all objects

- (BOOL)containsHandleWithUID:(NSString *)UID serviceID:(NSString *)serviceID;	//Do you have this handle?
- (AIEditorListGroup *)groupWithUID:(NSString *)UID;
- (AIEditorListHandle *)handleWithUID:(NSString *)UID serviceID:(NSString *)serviceID;

- (void)addObject:(AIEditorListObject *)inObject;					//Add the object
- (void)deleteObject:(AIEditorListObject *)inObject;					//Delete the object
- (void)renameObject:(AIEditorListObject *)inObject to:(NSString *)newName;		//Rename the object
- (void)moveObject:(AIEditorListObject *)inObject toGroup:(AIEditorListGroup *)inGroup;	//Move the object


@end

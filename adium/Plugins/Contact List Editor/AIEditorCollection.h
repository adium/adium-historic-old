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

typedef enum {
    AISortByName = 0,
    AISortByIndex
} AICollectionSortMode;
    
@class AIEditorListHandle, AIEditorListGroup;

@interface AIEditorCollection : AIObject {
    NSMutableArray	*list;
    int			sortMode;
    BOOL		controlledChanges;
}

- (id)init;

- (NSString *)name;			//Large black drawer label
- (NSString *)UID;			//Used to store group collapse/expand state
- (NSImage *)icon;			//Drawer Icon
- (BOOL)enabled;			//Enabled?
- (BOOL)editable;			//Editable?
- (BOOL)showOwnershipColumns;		//Display ownership/checkbox column?
- (BOOL)showCustomEditorColumns;	//Display custom columns (alias, ...)?
- (BOOL)showIndexColumn;		//Display index/manual order column?
- (NSString *)collectionDescription;	//Window title when collection is selected
- (BOOL)includeInOwnershipColumn;	//Does this collection get a check box in the ownership column?

- (NSString *)serviceID;		//The service ID of handles in this collection
- (NSMutableArray *)list;		//Return an array containing all objects

- (void)sortUsingMode:(AICollectionSortMode)mode;
- (AICollectionSortMode)sortMode;
- (void)sortGroupArray;
- (void)sortGroup:(AIEditorListGroup *)group;

//Groups
- (AIEditorListGroup *)groupWithUID:(NSString *)targetGroupName;	//Find a group
- (AIEditorListGroup *)addGroupNamed:(NSString *)name temporary:(BOOL)temporary;
- (void)moveGroup:(AIEditorListGroup *)inGroup toIndex:(int)index;
- (void)renameGroup:(AIEditorListGroup *)inGroup to:(NSString *)newName;
- (void)deleteGroup:(AIEditorListGroup *)inGroup;

//Handles
- (BOOL)containsHandleWithUID:(NSString *)targetHandleName;
- (AIEditorListHandle *)handleWithUID:(NSString *)targetHandleName;	//Find a handle
- (AIEditorListHandle *)addHandleNamed:(NSString *)inName inGroup:(AIEditorListGroup *)group index:(int)index temporary:(BOOL)temporary;
- (void)moveHandle:(AIEditorListHandle *)inHandle toGroup:(AIEditorListGroup *)inGroup index:(int)index;
- (void)deleteHandle:(AIEditorListHandle *)inHandle;
- (void)renameHandle:(AIEditorListHandle *)inHandle to:(NSString *)newName;

//For subclassers
- (void)_addGroup:(AIEditorListGroup *)group;
- (void)_moveGroup:(AIEditorListGroup *)group toIndex:(int)index;
- (void)_renameGroup:(AIEditorListGroup *)group to:(NSString *)name;
- (void)_deleteGroup:(AIEditorListGroup *)group;
- (void)_addHandle:(AIEditorListHandle *)handle toGroup:(AIEditorListGroup *)group index:(int)index;
- (void)_deleteHandle:(AIEditorListHandle *)handle;
- (void)_renameHandle:(AIEditorListHandle *)handle to:(NSString *)name;
- (void)_moveHandle:(AIEditorListHandle *)handle toGroup:(AIEditorListGroup *)group index:(int)index;
        
@end










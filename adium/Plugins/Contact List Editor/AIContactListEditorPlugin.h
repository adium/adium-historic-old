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

#define CONTACT_EDITOR_REGISTER_COLUMNS		@"CONTACT_EDITOR_REGISTER_COLUMNS"

#define Editor_CollectionStatusChanged		@"Editor_CollectionStatusChanged"
#define Editor_AddedObjectToCollection		@"Editor_AddedObjectToCollection"
#define Editor_RemovedObjectFromCollection	@"Editor_RemovedObjectFromCollection"
#define Editor_RenamedObjectOnCollection	@"Editor_RenamedObjectOnCollection"
#define Editor_CollectionContentChanged		@"Editor_CollectionContentChanged"
#define Editor_CollectionArrayChanged		@"Editor_CollectionArrayChanged"
#define Editor_ActiveCollectionChanged		@"Editor_ActiveCollectionChanged"

@class AIEditorListObject, AIEditorListHandle, AIEditorListGroup, AIEditorCollection;

@protocol AIListEditorColumnController <NSObject>
- (NSString *)editorColumnLabel;
- (NSString *)editorColumnStringForServiceID:(NSString *)inServiceID UID:(NSString *)inUID;
- (BOOL)editorColumnSetStringValue:(NSString *)value forServiceID:(NSString *)inServiceID UID:(NSString *)inUID;
@end

@protocol AIListEditor
- (void)registerListEditorColumnController:(id <AIListEditorColumnController>)inController;
@end

@interface AIContactListEditorPlugin : AIPlugin {
    NSMutableArray	*listEditorColumnControllerArray;
    NSMutableArray	*collectionsArray;
}

- (NSArray *)listEditorColumnControllers;
- (void)registerListEditorColumnController:(id <AIListEditorColumnController>)inController;
- (NSArray *)collectionsArray;
//- (AIEditorListHandle *)handleNamed:(NSString *)targetHandleName onCollection:(AIEditorCollection *)collection;
//- (AIEditorListHandle *)createHandleNamed:(NSString *)name inGroup:(AIEditorListGroup *)group onCollection:(AIEditorCollection *)collection temporary:(BOOL)temporary;
//- (AIEditorListGroup *)createGroupNamed:(NSString *)name onCollection:(AIEditorCollection *)collection temporary:(BOOL)temporary;
//- (BOOL)renameObject:(AIEditorListObject *)object onCollection:(AIEditorCollection *)collection to:(NSString *)inName;
//- (void)moveHandle:(AIEditorListHandle *)handle fromCollection:(AIEditorCollection *)sourceCollection toGroup:(AIEditorListGroup *)destGroup collection:(AIEditorCollection *)destCollection;
//- (void)deleteObject:(AIEditorListObject *)object fromCollection:(AIEditorCollection *)collection;
//- (AIEditorListGroup *)groupNamed:(NSString *)targetGroupName onCollection:(AIEditorCollection *)collection;
- (void)importFile:(NSString *)inPath;

@end

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
#import "AIEditorListHandle.h"

@interface AIEditorListGroup : NSObject {
    BOOL		temporary;
    NSMutableArray	*contents;
    NSString		*UID;
    float		orderIndex;
}

- (id)initWithUID:(NSString *)inUID temporary:(BOOL)inTemporary;
- (NSString *)UID;
- (void)setUID:(NSString *)inUID;
- (BOOL)temporary;
- (void)setTemporary:(BOOL)inTemporary;
- (void)addHandle:(AIEditorListHandle *)inHandle toIndex:(int)index;
- (void)removeHandle:(AIEditorListHandle *)inHandle;
- (AIEditorListHandle *)handleAtIndex:(unsigned)index;
- (AIEditorListHandle *)handleNamed:(NSString *)inName;
- (NSEnumerator *)handleEnumerator;
- (unsigned)count;
- (NSMutableArray *)contentArray;
- (void)addHandle:(AIEditorListHandle *)inHandle;
- (int)indexOfHandle:(AIEditorListHandle *)handle;
- (float)orderIndex;
- (void)setOrderIndex:(float)inIndex;

@end

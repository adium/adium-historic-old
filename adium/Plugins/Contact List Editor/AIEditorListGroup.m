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

#import "AIEditorListGroup.h"
#import "AIEditorListHandle.h"

int alphabeticalSort(id objectA, id objectB, void *context);

@implementation AIEditorListGroup

- (id)initWithUID:(NSString *)inUID temporary:(BOOL)inTemporary
{
    [super init];

    temporary = inTemporary;
    UID = [inUID retain];
    contents = [[NSMutableArray alloc] init];
    orderIndex = -1;
 
    return(self);
}

- (void)dealloc
{
    [contents release];
    [UID release];
    
    [super dealloc];
}


//UID
- (NSString *)UID
{
    return(UID);
}
- (void)setUID:(NSString *)inUID
{
    [UID release];
    UID = [inUID retain];
}


//orderIndex
- (float)orderIndex
{
    return(orderIndex);
}
- (void)setOrderIndex:(float)inIndex
{
    orderIndex = inIndex;
}


//Temporary
- (BOOL)temporary
{
    return(temporary);
}
- (void)setTemporary:(BOOL)inTemporary
{
    temporary = inTemporary;
}


//Contents
- (void)addHandle:(AIEditorListHandle *)inHandle
{
    [contents addObject:inHandle];
    [inHandle setContainingGroup:self];
}

- (void)addHandle:(AIEditorListHandle *)inHandle toIndex:(int)index
{
    [contents insertObject:inHandle atIndex:index];
    [inHandle setContainingGroup:self];
}

- (void)removeHandle:(AIEditorListHandle *)inHandle
{
    [inHandle setContainingGroup:nil];
    [contents removeObject:inHandle];
}

- (AIEditorListHandle *)handleAtIndex:(unsigned)index
{
    return([contents objectAtIndex:index]);
}

- (AIEditorListHandle *)handleNamed:(NSString *)inName
{
    NSEnumerator	*enumerator;
    AIEditorListHandle	*handle;
    
    enumerator = [contents objectEnumerator];
    while((handle = [enumerator nextObject])){
        if([inName compare:[handle UID]] == 0) return(handle);
    }

    return(nil);
}

- (NSEnumerator *)handleEnumerator
{
    return([contents objectEnumerator]);
}

- (unsigned)count
{
    return([contents count]);
}

- (int)indexOfHandle:(AIEditorListHandle *)handle
{
    return([contents indexOfObject:handle]);    
}

- (NSMutableArray *)contentArray
{
    return(contents);
}

@end




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
    [super initWithUID:inUID temporary:inTemporary];

    contents = [[NSMutableArray alloc] init];
    expanded = YES;
    
    return(self);
}

- (void)dealloc
{
    [contents release];
    
    [super dealloc];
}

- (void)addObject:(AIEditorListObject *)inObject
{
    [contents addObject:inObject];
    [inObject setContainingGroup:self];

    [self sort]; //resort
}

- (void)removeObject:(AIEditorListObject *)inObject
{
    [inObject setContainingGroup:nil];
    [contents removeObject:inObject];
    
    [self sort]; //resort
}

- (AIEditorListObject *)objectAtIndex:(unsigned)index
{
    return([contents objectAtIndex:index]);
}

- (AIEditorListObject *)objectNamed:(NSString *)inName isGroup:(BOOL)isGroup
{
    NSEnumerator	*enumerator;
    AIEditorListObject	*object;
    
    enumerator = [contents objectEnumerator];
    while((object = [enumerator nextObject])){
        if((isGroup && [object isKindOfClass:[AIEditorListGroup class]]) || (!isGroup && [object isKindOfClass:[AIEditorListHandle class]])){
            if([inName compare:[object UID]] == 0) return(object);
        }
    }

    return(nil);
}

- (NSEnumerator *)objectEnumerator
{
    return([contents objectEnumerator]);
}

- (unsigned)count
{
    return([contents count]);
}

- (void)sort
{
    [contents sortUsingFunction:alphabeticalSort context:nil];
}

int alphabeticalSort(id objectA, id objectB, void *context)
{
    BOOL	groupA = [objectA isKindOfClass:[AIEditorListGroup class]];
    BOOL	groupB = [objectB isKindOfClass:[AIEditorListGroup class]];

    if(groupA && !groupB){
        return(NSOrderedAscending);
    }else if(!groupA && groupB){
        return(NSOrderedDescending);
    }else{
        return([[objectA UID] caseInsensitiveCompare:[objectB UID]]);
    }
}


@end




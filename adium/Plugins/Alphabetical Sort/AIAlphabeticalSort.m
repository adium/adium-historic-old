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

#import "AIAlphabeticalSort.h"

int alphabeticalSort(id objectA, id objectB, void *context);

@implementation AIAlphabeticalSort

- (NSString *)description{
    return(@"Sort contacts and groups alphabetically.");
}
- (NSString *)identifier{
    return(@"Alphabetical");
}
- (NSString *)displayName{
    return(@"Alphabetical");
}

- (BOOL)shouldSortForModifiedStatusKeys:(NSArray *)inModifiedKeys
{
    return(NO); //Ignore
}

- (BOOL)shouldSortForModifiedAttributeKeys:(NSArray *)inModifiedKeys
{
    if([inModifiedKeys containsObject:@"Hidden"] || [inModifiedKeys containsObject:@"Display Name"]){
        return(YES);
    }else{
        return(NO);
    }
}

- (void)sortListObjects:(NSMutableArray *)inObjects
{
    [inObjects sortUsingFunction:alphabeticalSort context:nil];
}

int alphabeticalSort(id objectA, id objectB, void *context)
{
    BOOL	invisibleA = [[objectA displayArrayForKey:@"Hidden"] containsAnyIntegerValueOf:1];
    BOOL	invisibleB = [[objectB displayArrayForKey:@"Hidden"] containsAnyIntegerValueOf:1];

    if(invisibleA && !invisibleB){
        return(NSOrderedDescending);
    }else if(!invisibleA && invisibleB){
        return(NSOrderedAscending);
    }else{
        BOOL	groupA = [objectA isKindOfClass:[AIListGroup class]];
        BOOL	groupB = [objectB isKindOfClass:[AIListGroup class]];

        if(groupA && !groupB){
            return(NSOrderedAscending);
        }else if(!groupA && groupB){
            return(NSOrderedDescending);
        }else{
            return([[objectA longDisplayName] caseInsensitiveCompare:[objectB longDisplayName]]);
        }
    }
}

@end

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

#import "AIAlphabeticalSortNoGroups.h"
#import "AIAdium.h"
#import <AIUtilities/AIUtilities.h>
#import <Adium/Adium.h>

int alphabeticalSortNoGroups(id objectA, id objectB, void *context);

@implementation AIAlphabeticalSortNoGroups

- (NSString *)description{
    return(@"Sort contacts alphabetically.  Groups are not sorted.");
}
- (NSString *)identifier{
    return(@"Alphabetical_NoGroup");
}
- (NSString *)displayName{
    return(@"Alphabetical (Groups Not Sorted)");
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
    [inObjects sortUsingFunction:alphabeticalSortNoGroups context:nil];
}

int alphabeticalSortNoGroups(id objectA, id objectB, void *context)
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
        }else if(!groupA && !groupB){
            return([[objectA displayName] caseInsensitiveCompare:[objectB displayName]]);
        }else{
            AIListGroup	*group = [objectA containingGroup];

            //Keep groups in manual order
            if([group indexOfObject:objectA] > [group indexOfObject:objectB]){
                return(NSOrderedDescending);
            }else{
                return(NSOrderedAscending);
            }
        }
    }
}

@end

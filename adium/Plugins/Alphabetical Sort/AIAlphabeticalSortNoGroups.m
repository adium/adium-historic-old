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

int alphabeticalSortNoGroups(id objectA, id objectB, BOOL groups);

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
- (NSArray *)statusKeysRequiringResort{
	return(nil);
}
- (NSArray *)attributeKeysRequiringResort{
	return([NSArray arrayWithObject:@"Display Name"]);
}
- (sortfunc)sortFunction{
	return(&alphabeticalSortNoGroups);
}

int alphabeticalSortNoGroups(id objectA, id objectB, BOOL groups)
{
	if(!groups){
		return([[objectA longDisplayName] caseInsensitiveCompare:[objectB longDisplayName]]);
	}else{
		//Keep groups in manual order
		if([objectA orderIndex] > [objectB orderIndex]){
			return(NSOrderedDescending);
		}else{
			return(NSOrderedAscending);
		}
	}
}

@end

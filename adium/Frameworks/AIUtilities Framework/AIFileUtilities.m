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

/*
    Assists with loading and saving dictionaries.
*/

#import "AIFileUtilities.h"
#import "AIAdium.h"

@interface AIFileUtilities (PRIVATE)

@end

@implementation AIFileUtilities

// creates all the folders specified in 'fullPath' (if they don't exist)
+ (void)createDirectory:(NSString *)fullPath
{
    BOOL		isDir;
    NSMutableArray	*neededFolders = [[NSMutableArray alloc] init];
    short		folder;

    NSParameterAssert(fullPath != nil && [fullPath length] != 0);

    while(![[NSFileManager defaultManager]fileExistsAtPath:fullPath isDirectory:&isDir] || !isDir){
        [neededFolders addObject:[fullPath lastPathComponent]]; //remember it
        fullPath = [fullPath stringByDeletingLastPathComponent]; //delete it
    }

    for(folder = [neededFolders count]-1;folder >= 0;folder--){
        fullPath = [fullPath stringByAppendingPathComponent:[neededFolders objectAtIndex:folder]];
        [[NSFileManager defaultManager] createDirectoryAtPath:fullPath attributes:nil];
    }

    [neededFolders release];
}

@end

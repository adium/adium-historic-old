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

#import "AIEmoticon.h"
#import "AIEmoticonPack.h"
#import "AIEmoticonsPlugin.h"

#define EMOTICON_PATH_EXTENSION			@"emoticon"

@interface AIEmoticonPack (PRIVATE)
- (AIEmoticonPack *)initFromPath:(NSString *)inPath;
- (void)setEmoticonArray:(NSArray *)inArray;
@end

@implementation AIEmoticonPack

//Create a new emoticon pack
+ (id)emoticonPackFromPath:(NSString *)inPath
{
    return([[[self alloc] initFromPath:inPath] autorelease]);
}

//Init
- (AIEmoticonPack *)initFromPath:(NSString *)inPath
{
    [super init];
    path = [inPath retain];
    name = [[[inPath lastPathComponent] stringByDeletingPathExtension] retain];
    emoticonArray = nil;
	enabled = NO;
    
    return(self);
}

//Copy
- (id)copyWithZone:(NSZone *)zone
{
    AIEmoticonPack	*newPack = [[AIEmoticonPack alloc] initFromPath:path];   
    
    [newPack setEmoticonArray:emoticonArray];

    return(newPack);
}

//Dealloc
- (void)dealloc
{
    [path release];
    [name release];
    [emoticonArray release];
    
    [super dealloc];
}

//Returns the name of this pack
- (NSString *)name
{
    return(name);
}

//Returns the path of this pack
- (NSString *)path
{
    return(path);
}

//Returns the emoticons in this pack
- (NSArray *)emoticons
{
    if(!emoticonArray){
        NSDirectoryEnumerator   *enumerator;
        NSString                *fileName;
        NSFileManager           *mgr = [NSFileManager defaultManager];
        
        //
        emoticonArray = [[NSMutableArray alloc] init];
        
        //Build the array of emoticons for this set
        enumerator = [[NSFileManager defaultManager] enumeratorAtPath:path];
        while((fileName = [enumerator nextObject])){        

            //Ignore invisible files, and anything that doesn't end with .emoticon
            if([[fileName lastPathComponent] characterAtIndex:0] != '.' &&
               [[fileName pathExtension] caseInsensitiveCompare:EMOTICON_PATH_EXTENSION] == 0){
                NSString        *fullPath = [path stringByAppendingPathComponent:fileName];
                BOOL            isDirectory;
                
                //Ensure that this is a folder and that it is non-empty
                [mgr fileExistsAtPath:fullPath isDirectory:&isDirectory];
                if(isDirectory && [[mgr enumeratorAtPath:fullPath] nextObject]) {
                    [emoticonArray addObject:[AIEmoticon emoticonFromPath:fullPath]];
                }
            }
        }
    }

    return(emoticonArray);
}

//Set the emoticons that are disabled in this pack
- (void)setDisabledEmoticons:(NSArray *)inArray
{
    NSEnumerator    *enumerator;
    AIEmoticon      *emoticon;
    
    //Flag our emoticons as enabled/disabled
    enumerator = [[self emoticons] objectEnumerator];
    while(emoticon = [enumerator nextObject]){
        [emoticon setEnabled:(![inArray containsObject:[emoticon name]])];
    }
}

//Used for copying, set this pack's emoticon array
- (void)setEmoticonArray:(NSArray *)inArray
{
    [emoticonArray release]; emoticonArray = nil;
    emoticonArray = [inArray mutableCopy];
}

//Flush any cached emoticon images (and image attachment strings)
- (void)flushEmoticonImageCache
{
    NSEnumerator    *enumerator;
    AIEmoticon      *emoticon;
    
    //Flag our emoticons as enabled/disabled
    enumerator = [[self emoticons] objectEnumerator];
    while(emoticon = [enumerator nextObject]){
        [emoticon flushEmoticonImageCache];
    }
}

- (void)setIsEnabled:(BOOL)inEnabled
{
	enabled = inEnabled;
}
- (BOOL)isEnabled
{
	return enabled;
}

@end

/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2004, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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
    Allows easy access to the elements of a dictionary
*/

#import "AIDictionaryAdditions.h"
#import "AIColorAdditions.h"
#import "AIFileManagerAdditions.h"

@implementation NSDictionary (AIDictionaryAdditions)

// Returns a dictionary from the owners bundle with the specified name
+ (NSDictionary *)dictionaryNamed:(NSString *)name forClass:(Class)inClass
{
    NSBundle		*ownerBundle;
    NSString		*dictPath;
    NSDictionary	*dict;

    //Get the bundle
    ownerBundle = [NSBundle bundleForClass:inClass];

    //Open the image
    dictPath = [ownerBundle pathForResource:name ofType:@"plist"];    
    dict = [NSDictionary dictionaryWithContentsOfFile:dictPath];

    return(dict);
}

// returns the dictionary from the specified path
+ (NSDictionary *)dictionaryAtPath:(NSString *)path withName:(NSString *)name create:(BOOL)create
{
    NSDictionary	*dictionary;

    NSParameterAssert(path != nil); NSParameterAssert([path length] != 0);
    NSParameterAssert(name != nil); NSParameterAssert([name length] != 0);
    
    //open the dictionary
    dictionary = [NSDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"%@/%@.plist",path,name]];

    //if the dictionary doesn't exist, create and return a new one
    if(dictionary == nil && create){
        dictionary = [[[NSDictionary alloc] init] autorelease];
    }

    return(dictionary);
}

// saves this dictionary to the specified path
- (BOOL)writeToPath:(NSString *)path withName:(NSString *)name
{
    NSParameterAssert(path != nil); NSParameterAssert([path length] != 0);
    NSParameterAssert(name != nil); NSParameterAssert([name length] != 0);

	[[NSFileManager defaultManager] createDirectoriesForPath:path]; //make sure the path exists
    return ([self writeToFile:[NSString stringWithFormat:@"%@/%@.plist",path,name] atomically:YES]);
}

- (BOOL)boolForKey:(NSString *)inKey{
    BOOL value = [[self objectForKey:inKey] boolValue];

    return(value);
}

- (NSString *)stringForKey:(NSString *)inKey{
    NSString *string = [self objectForKey:inKey];

    return(string ? string : @"");
}

- (int)intForKey:(NSString *)inKey{
    int value = [[self objectForKey:inKey] intValue];

    return(value);
}

- (NSColor *)colorForKey:(NSString *)inKey{
    NSString *colorString = [self objectForKey:inKey];

	return (colorString ? [colorString representedColor] : [NSColor whiteColor]);
}

- (id)objectForIntegerKey:(int)aKey
{
    return([self objectForKey:[NSNumber numberWithInt:aKey]]);
}

@end

@implementation NSMutableDictionary (AIDictionaryAdditions)

// returns the dictionary from the specified path
+ (NSMutableDictionary *)dictionaryAtPath:(NSString *)path withName:(NSString *)name create:(BOOL)create
{
    NSMutableDictionary	*dictionary;

    NSParameterAssert(path != nil); NSParameterAssert([path length] != 0);
    NSParameterAssert(name != nil); NSParameterAssert([name length] != 0);
    
    //open the dictionary
    dictionary = [NSMutableDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"%@/%@.plist",path,name]];

    //if the dictionary doesn't exist, create and return a new one
    if(dictionary == nil && create){
        dictionary = [[[NSMutableDictionary alloc] init] autorelease];
    }

    return(dictionary);
}

- (void)setBool:(BOOL)inValue forKey:(NSString *)inKey{
    [self setObject:[NSNumber numberWithBool:inValue] forKey:inKey];
}

- (void)setString:(NSString *)inString forKey:(NSString *)inKey{
    [self setObject:inString forKey:inKey];
}

- (void)setInt:(int)inValue forKey:(NSString *)inKey{
    [self setObject:[NSNumber numberWithInt:inValue] forKey:inKey];
}

- (void)setColor:(NSColor *)inColor forKey:(NSString *)inKey{
    if(inColor != nil){
        [self setObject:[inColor stringRepresentation] forKey:inKey];
    }
}

- (id)objectForIntegerKey:(int)aKey
{
    return([self objectForKey:[NSNumber numberWithInt:aKey]]);
}

@end

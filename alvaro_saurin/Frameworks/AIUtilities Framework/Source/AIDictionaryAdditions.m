/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2005, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

    return dict;
}

// returns the dictionary from the specified path
+ (NSDictionary *)dictionaryAtPath:(NSString *)path withName:(NSString *)name create:(BOOL)create
{
    NSDictionary	*dictionary;

    NSParameterAssert(path != nil); NSParameterAssert([path length] != 0);
    NSParameterAssert(name != nil); NSParameterAssert([name length] != 0);

	NSData *plistData;
	NSString *error;

	plistData = [[NSData alloc] initWithContentsOfFile:[[path stringByAppendingPathComponent:name] stringByAppendingPathExtension:@"plist"]];
	
	dictionary = [NSPropertyListSerialization propertyListFromData:plistData
												  mutabilityOption:NSPropertyListImmutable
															format:NULL
												  errorDescription:&error];
	[plistData release];

	if (!dictionary && create) dictionary = [NSDictionary dictionary];

    return dictionary;
}

// saves this dictionary to the specified path
- (BOOL)writeToPath:(NSString *)path withName:(NSString *)name
{
    NSParameterAssert(path != nil); NSParameterAssert([path length] != 0);
    NSParameterAssert(name != nil); NSParameterAssert([name length] != 0);

	[[NSFileManager defaultManager] createDirectoriesForPath:path]; //make sure the path exists
	
	NSData *plistData;
	plistData = [NSPropertyListSerialization dataFromPropertyList:self
														   format:NSPropertyListBinaryFormat_v1_0
												 errorDescription:NULL];
	if (plistData) {
		return [plistData writeToFile:[[path stringByAppendingPathComponent:name] stringByAppendingPathExtension:@"plist"]
						   atomically:YES];
	} else {
		return NO;
	}
}

- (NSDictionary *)dictionaryByTranslating:(NSDictionary *)translation adding:(NSDictionary *)addition removing:(NSSet *)removal
{
	NSDictionary *result;

	//only do work if we have work to do.
	if (translation || addition || removal) {
		NSMutableDictionary *mutable = [self mutableCopy];

		[mutable translate:translation add:addition remove:removal];

		result = [[self class] dictionaryWithDictionary:mutable];
		[mutable release];
	} else {
		result = [[self retain] autorelease];
	}

	return result;
}

@end

@implementation NSMutableDictionary (AIDictionaryAdditions)

// returns the dictionary from the specified path
+ (NSMutableDictionary *)dictionaryAtPath:(NSString *)path withName:(NSString *)name create:(BOOL)create
{
	NSMutableDictionary	*dictionary;
	
    NSParameterAssert(path != nil); NSParameterAssert([path length] != 0);
    NSParameterAssert(name != nil); NSParameterAssert([name length] != 0);
	
	NSData *plistData;
	NSString *error;
	
	plistData = [[NSData alloc] initWithContentsOfFile:[[path stringByAppendingPathComponent:name] stringByAppendingPathExtension:@"plist"]];
	
	dictionary = [NSPropertyListSerialization propertyListFromData:plistData
												  mutabilityOption:NSPropertyListMutableContainers
															format:NULL
												  errorDescription:&error];
	[plistData release];

	if (!dictionary && create) dictionary = [NSMutableDictionary dictionary];
	
    return dictionary;
}


- (void)translate:(NSDictionary *)translation add:(NSDictionary *)addition remove:(NSSet *)removal
{
	//only do work if we have work to do.
	if (translation || addition || removal) {
		NSEnumerator *keyEnum = [self keyEnumerator];
		NSString *key;
		NSDictionary *selfCopy = [self copy];

		while ((key = [keyEnum nextObject])) {
			NSString *newKey = [translation objectForKey:key];
			if (newKey) {
				[self setObject:[selfCopy objectForKey:key] forKey:newKey];
			} else {
				id newObj = [addition objectForKey:key];
				if (newObj) {
					[self setObject:newObj forKey:key];
				} else if (removal && [removal containsObject:key]) {
					[self removeObjectForKey:key];
				}
			}
		}

		[selfCopy release];		
	}
}

@end

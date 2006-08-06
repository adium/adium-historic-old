/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "AIEmoticon.h"
#import "AIEmoticonPack.h"
#import "AIEmoticonController.h"
#import <AIUtilities/AIFileManagerAdditions.h>
#import <AIUtilities/AIImageAdditions.h>

#define EMOTICON_PATH_EXTENSION			@"emoticon"
#define EMOTICON_PACK_TEMP_EXTENSION	@"AdiumEmoticonOld"

#define EMOTICON_PLIST_FILENAME	   		@"Emoticons.plist"
#define EMOTICON_PACK_VERSION			@"AdiumSetVersion"
#define EMOTICON_LIST					@"Emoticons"

#define EMOTICON_EQUIVALENTS			@"Equivalents"
#define EMOTICON_NAME					@"Name"

#define	EMOTICON_SERVICE_CLASS			@"Service Class"

#define EMOTICON_LOCATION				@"Location"
#define EMOTICON_LOCATION_SEPARATOR		@"////"

@interface AIEmoticonPack (PRIVATE)
- (AIEmoticonPack *)initFromPath:(NSString *)inPath;
- (void)setEmoticonArray:(NSArray *)inArray;
- (void)loadEmoticons;
- (void)loadAdiumEmoticons:(NSDictionary *)emoticons;
- (void)loadProteusEmoticons:(NSDictionary *)emoticons;
- (void)_upgradeEmoticonPack:(NSString *)packPath;
- (NSString *)_imagePathForEmoticonPath:(NSString *)inPath;
- (NSArray *)_equivalentsForEmoticonPath:(NSString *)inPath;
- (NSString *)_stringWithMacEndlines:(NSString *)inString;
@end

@implementation AIEmoticonPack

//Create a new emoticon pack
+ (id)emoticonPackFromPath:(NSString *)inPath
{
    return [[[self alloc] initFromPath:inPath] autorelease];
}

//Init
- (AIEmoticonPack *)initFromPath:(NSString *)inPath
{
    if ((self = [super init])) {
		path = [inPath retain];
		name = [[[inPath lastPathComponent] stringByDeletingPathExtension] retain];
		NSBundle * xtraBundle = [NSBundle bundleWithPath:path];
		if (xtraBundle && ([[xtraBundle objectForInfoDictionaryKey:@"XtraBundleVersion"] intValue] == 1)) {//This checks for a new-style xtra
			path = [xtraBundle resourcePath]; //new style xtras store the same info, but it's in Contents/Resources/ so that we can have an info.plist file and use NSBundle
		}
		emoticonArray = nil;
		emoticonLocation = [path retain];
		enabled = NO;
	}
    
    return self;
}

//Dealloc
- (void)dealloc
{
    [path release];
    [name release];
    [emoticonArray release];
    [emoticonLocation release];
	[serviceClass release];

    [super dealloc];
}

//Our name
- (NSString *)name
{
    return name;
}

//Our path
- (NSString *)path
{
    return path;
}

/*!
 * @brief Service class of this emoticon pack
 *
 * @result A service class, or nil if the emoticon pack is not associated with any service class
 */
- (NSString *)serviceClass
{
	return serviceClass;
}

//Our emoticons
- (NSArray *)emoticons
{
	if (!emoticonArray) [self loadEmoticons];
	return emoticonArray;
}

/*
 * @brief Return the preview image to use within a menu for this emoticon
 *
 * It tries to be the emoticon for text equivalent :) or :-). Failing that, any emoticon will do.
 */
- (NSImage *)menuPreviewImage
{
	NSArray		 *myEmoticons = [self emoticons];
	NSEnumerator *enumerator;
	AIEmoticon	 *emoticon;

	enumerator = [myEmoticons objectEnumerator];
	while ((emoticon = [enumerator nextObject])) {
		NSArray *equivalents = [emoticon textEquivalents];
		if ([equivalents containsObject:@":)"] || [equivalents containsObject:@":-)"]) {
			break;
		}
	}

	//If we didn't find a happy emoticon, use the first one in the array
	if (!emoticon && [myEmoticons count]) {
		emoticon = [myEmoticons objectAtIndex:0];
	}

	return [[emoticon image] imageByScalingToSize:NSMakeSize(16,16)];
}

//Set the emoticons that are disabled in this pack
- (void)setDisabledEmoticons:(NSArray *)inArray
{
    NSEnumerator    *enumerator;
    AIEmoticon      *emoticon;
    
    //Flag our emoticons as enabled/disabled
    enumerator = [[self emoticons] objectEnumerator];
    while ((emoticon = [enumerator nextObject])) {
        [emoticon setEnabled:(![inArray containsObject:[emoticon name]])];
    }
}

//Enable/Disable this pack
- (void)setIsEnabled:(BOOL)inEnabled
{
	enabled = inEnabled;
}
- (BOOL)isEnabled{
	return enabled;
}

//Copying --------------------------------------------------------------------------------------------------------------
#pragma mark Copying
//Copy
- (id)copyWithZone:(NSZone *)zone
{
    AIEmoticonPack	*newPack = [[AIEmoticonPack alloc] initFromPath:path];   

	newPack->emoticonArray = [emoticonArray mutableCopy];
	newPack->serviceClass = [serviceClass retain];
	newPack->path = [path retain];
	newPack->name = [name retain];
	newPack->emoticonLocation = [emoticonLocation retain];

    return newPack;
}

//Loading Emoticons ----------------------------------------------------------------------------------------------------
#pragma mark Loading Emoticons
//Returns the emoticons in this pack
- (void)loadEmoticons
{
//	NSBundle	*emoticonPackBundle;
	
	[emoticonArray release]; emoticonArray = [[NSMutableArray alloc] init];
	[serviceClass release]; serviceClass = nil;

#warning Localization
//	if (emoticonPackBundle = [NSBundle bundleWithPath:
	//
	NSString		*infoDictPath = [path stringByAppendingPathComponent:EMOTICON_PLIST_FILENAME];
	NSDictionary	*infoDict = [NSDictionary dictionaryWithContentsOfFile:infoDictPath];
	
	//If no info dict was found, assume that this is an old emoticon pack and try to upgrade it
	if (!infoDict) {
		[self _upgradeEmoticonPack:path];
		infoDict = [NSDictionary dictionaryWithContentsOfFile:infoDictPath];
	}
	
	//Load the emoticons
	if (infoDict) {
		/* Handle optional location key, which allows emoticons to be loaded
		 * from arbitrary directories. This is only used by the iChat emoticon
		 * pack.
		 */
		id possiblePaths = [infoDict objectForKey:EMOTICON_LOCATION];
		if (possiblePaths) {
			if ([possiblePaths isKindOfClass:[NSString class]]) {
				possiblePaths = [NSArray arrayWithObjects:possiblePaths, nil];
			}

			NSEnumerator *pathEnumerator = [possiblePaths objectEnumerator];
			NSString *aPath;

			while ((aPath = [pathEnumerator nextObject])) {
				NSString *possiblePath;
				NSArray *splitPath = [aPath componentsSeparatedByString:EMOTICON_LOCATION_SEPARATOR];

				/* Two possible formats:
				 *
				 * <string>/absolute/path/to/directory</string>
				 * <string>CFBundleIdentifier////relative/path/from/bundle/to/directory</string>
				 *
				 * The separator in the latter is ////, defined as EMOTICON_LOCATION_SEPARATOR.
				 */
				if ([splitPath count] == 1) {
					possiblePath = [splitPath objectAtIndex:0];
				} else {
					NSArray *components = [NSArray arrayWithObjects:
						[[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:[splitPath objectAtIndex:0]],
						[splitPath objectAtIndex:1],
						nil];
					possiblePath = [NSString pathWithComponents:components];
				}

				/* If the directory exists, then we've found the location. If we
				 * make it all the way through the list without finding a valid
				 * directory, then the standard location will be used.
				 */
				BOOL isDir;
				if ([[NSFileManager defaultManager] fileExistsAtPath:possiblePath isDirectory:&isDir] && isDir) {
					[emoticonLocation release];
					emoticonLocation = [possiblePath retain];
					break;
				}
			}
		}

		int version = [[infoDict objectForKey:EMOTICON_PACK_VERSION] intValue];
		
		switch (version) {
			case 0: [self loadProteusEmoticons:infoDict]; break;
			case 1: [self loadAdiumEmoticons:[infoDict objectForKey:EMOTICON_LIST]]; break;
			default: break;
		}
		
		serviceClass = [[infoDict objectForKey:EMOTICON_SERVICE_CLASS] retain];
		if (!serviceClass) {
			if ([name rangeOfString:@"AIM"].location != NSNotFound) {
				serviceClass = [@"AIM-compatible" retain];
			} else if ([name rangeOfString:@"MSN"].location != NSNotFound) {
				serviceClass = [@"MSN" retain];
			} else if ([name rangeOfString:@"Yahoo"].location != NSNotFound) {
				serviceClass = [@"Yahoo!" retain];
			}
		}
	}
	
	//Sort the emoticons in this pack using the AIEmoticon compare: selector
	[emoticonArray sortUsingSelector:@selector(compare:)];
}

//Adium version 1 emoticon pack
- (void)loadAdiumEmoticons:(NSDictionary *)emoticons
{
	NSEnumerator	*enumerator = [emoticons keyEnumerator];
	NSString		*fileName;
	
	while ((fileName = [enumerator nextObject])) {
		id	dict = [emoticons objectForKey:fileName];
		
		if ([dict isKindOfClass:[NSDictionary class]]) {
			[emoticonArray addObject:[AIEmoticon emoticonWithIconPath:[emoticonLocation stringByAppendingPathComponent:fileName]
														  equivalents:[(NSDictionary *)dict objectForKey:EMOTICON_EQUIVALENTS]
																 name:[(NSDictionary *)dict objectForKey:EMOTICON_NAME]
																 pack:self]];
		}
	}
}

//Proteus emoticon pack :)
- (void)loadProteusEmoticons:(NSDictionary *)emoticons
{
	NSEnumerator	*enumerator = [emoticons keyEnumerator];
	NSString		*fileName;
	
	while ((fileName = [enumerator nextObject])) {
		NSDictionary	*dict = [emoticons objectForKey:fileName];
		
		[emoticonArray addObject:[AIEmoticon emoticonWithIconPath:[path stringByAppendingPathComponent:fileName]
													  equivalents:[dict objectForKey:@"String Representations"]
															 name:[dict objectForKey:@"Meaning"]
															 pack:self]];
	}
}

//Flush any cached emoticon images (and image attachment strings)
- (void)flushEmoticonImageCache
{
    NSEnumerator    *enumerator;
    AIEmoticon      *emoticon;
    
    //Flag our emoticons as enabled/disabled
    enumerator = [[self emoticons] objectEnumerator];
    while ((emoticon = [enumerator nextObject])) {
        [emoticon flushEmoticonImageCache];
    }
}


//Upgrading ------------------------------------------------------------------------------------------------------------
//Methods for opening and converting old format Adium emoticon packs
#pragma mark Upgrading
//Upgrade an emoticon pack from the old format (where every emoticon is a separate file) to the new format
- (void)_upgradeEmoticonPack:(NSString *)packPath
{
	NSString				*packName, *workingDirectory, *tempPackName, *tempPackPath, *fileName;
	NSDirectoryEnumerator   *enumerator;
	NSFileManager           *mgr = [NSFileManager defaultManager];
	NSMutableDictionary		*infoDict = [NSMutableDictionary dictionary];
	NSMutableDictionary		*emoticonDict = [NSMutableDictionary dictionary];
	
	//
	packName = [[packPath lastPathComponent] stringByDeletingPathExtension];
	workingDirectory = [packPath stringByDeletingLastPathComponent];
	
	//Rename the existing pack to .AdiumEmoticonOld
	tempPackName = [packName stringByAppendingPathExtension:EMOTICON_PACK_TEMP_EXTENSION];
	tempPackPath = [workingDirectory stringByAppendingPathComponent:tempPackName];
	[mgr movePath:packPath toPath:tempPackPath handler:nil];
	
	//Create ourself a new pack
	[mgr createDirectoryAtPath:packPath attributes:nil];
	
	//Version this pack as 1
	[infoDict setObject:[NSNumber numberWithInt:1] forKey:EMOTICON_PACK_VERSION];
	
	//Process all .emoticons in the old pack
	enumerator = [[NSFileManager defaultManager] enumeratorAtPath:tempPackPath];
	while ((fileName = [enumerator nextObject])) {        
		if ([[fileName lastPathComponent] characterAtIndex:0] != '.' &&
		   [[fileName pathExtension] caseInsensitiveCompare:EMOTICON_PATH_EXTENSION] == 0) {
			NSString        *emoticonPath = [tempPackPath stringByAppendingPathComponent:fileName];
			BOOL            isDirectory;
			
			//Ensure that this is a folder and that it is non-empty
			[mgr fileExistsAtPath:emoticonPath isDirectory:&isDirectory];
			if (isDirectory) {
				NSString	*emoticonName = [fileName stringByDeletingPathExtension];
				
				//Get the text equivalents out of this .emoticon
				NSArray		*emoticonStrings = [self _equivalentsForEmoticonPath:emoticonPath];
				
				//Get the image out of this .emoticon
				NSString 	*imagePath = [self _imagePathForEmoticonPath:emoticonPath];
				NSString	*imageExtension = [imagePath pathExtension];
				
				if (emoticonStrings && imagePath) {
					NSString	*newImageName = [emoticonName stringByAppendingPathExtension:imageExtension];
					
					//Move the image into our new pack (with a unique name)
					NSString	*newImagePath = [packPath stringByAppendingPathComponent:newImageName];
					[mgr copyPath:imagePath toPath:newImagePath handler:nil];
					
					//Add to our emoticon plist
					[emoticonDict setObject:[NSDictionary dictionaryWithObjectsAndKeys:
						emoticonStrings, EMOTICON_EQUIVALENTS,
						emoticonName, EMOTICON_NAME, nil] 
									 forKey:newImageName];
				}
			}
		}
	}
	
	//Write our plist to the new pack
	[infoDict setObject:emoticonDict forKey:EMOTICON_LIST];
	[infoDict writeToFile:[packPath stringByAppendingPathComponent:EMOTICON_PLIST_FILENAME] atomically:NO];
	
	//Move the old/temp pack to the trash
	[mgr trashFileAtPath:tempPackPath];
}

//Returns the path to our emoticon image
- (NSString *)_imagePathForEmoticonPath:(NSString *)inPath
{
    NSDirectoryEnumerator   *enumerator;
    NSString		    	*fileName;
    
    //Search for the file named Emoticon in our bundle (It can be in any image format)
    enumerator = [[NSFileManager defaultManager] enumeratorAtPath:inPath];
    while ((fileName = [enumerator nextObject])) {
		if ([fileName hasPrefix:@"Emoticon"]) return [inPath stringByAppendingPathComponent:fileName];
    }
    
    return nil;
}

//Text equivalents from a pack
- (NSArray *)_equivalentsForEmoticonPath:(NSString *)inPath
{
	NSString    *equivFilePath = [inPath stringByAppendingPathComponent:@"TextEquivalents.txt"];
	NSArray 	*textEquivalents = nil;
	
	//Fetch the text equivalents
	if ([[NSFileManager defaultManager] fileExistsAtPath:equivFilePath]) {
		NSString	*equivString;
		
		//Convert the text file into an array of strings
		equivString = [NSMutableString stringWithContentsOfFile:equivFilePath];
		equivString = [self _stringWithMacEndlines:equivString];
		textEquivalents = [[equivString componentsSeparatedByString:@"\r"] retain];
	}
	
	return textEquivalents;
}

//Convert any unix/windows line endings to mac line endings
- (NSString *)_stringWithMacEndlines:(NSString *)inString
{
    NSCharacterSet      *newlineSet = [NSCharacterSet characterSetWithCharactersInString:@"\n"];
    NSMutableString     *newString = nil; //We avoid creating a new string if not necessary
    NSRange             charRange;
    
    //Step through all the invalid endlines
    charRange = [inString rangeOfCharacterFromSet:newlineSet];
    while (charRange.length != 0) {
        if (!newString) newString = [[inString mutableCopy] autorelease];
		
        //Replace endline and continue
        [newString replaceCharactersInRange:charRange withString:@"\r"];
        charRange = [newString rangeOfCharacterFromSet:newlineSet];
    }
    
    return newString ? newString : inString;
}

- (NSString *)description
{
	return ([NSString stringWithFormat:@"[%@: ServiceClass %@]",[super description],serviceClass]);
}

@end

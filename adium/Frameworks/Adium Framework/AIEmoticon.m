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

@interface AIEmoticon (PRIVATE)
- (AIEmoticon *)initFromPath:(NSString *)inPath;
- (NSString *)_stringWithMacEndlines:(NSString *)inString;
- (void)setTextEquivalents:(NSArray *)inArray;
- (void)setCachedString:(NSAttributedString *)inString image:(NSImage *)inImage;
- (NSString *)_pathToEmoticonImage;
@end

@implementation AIEmoticon

//Create a new emoticon
+ (id)emoticonFromPath:(NSString *)inPath
{
    return([[[self alloc] initFromPath:inPath] autorelease]);
}

//Init
- (AIEmoticon *)initFromPath:(NSString *)inPath
{
    [super init];
    path = [inPath retain];
    textEquivalents = nil;
    _cachedAttributedString = nil;
    
    return(self);
}

//Dealloc
- (void)dealloc
{
    [path release];
    [textEquivalents release];
    [_cachedAttributedString release];
    [_cachedImage release];
}

//Returns an array of the text equivalents for this emoticon
- (NSArray *)textEquivalents
{
    if(!textEquivalents){
        NSString    *equivFilePath = [path stringByAppendingPathComponent:@"TextEquivalents.txt"];
        
        //Fetch the text equivalents
        if([[NSFileManager defaultManager] fileExistsAtPath:equivFilePath]){
            NSString	*equivString;
            
            //Convert the text file into an array of strings
            equivString = [NSMutableString stringWithContentsOfFile:equivFilePath];
            equivString = [self _stringWithMacEndlines:equivString];
            textEquivalents = [[equivString componentsSeparatedByString:@"\r"] retain];
        }

        //If we didn't get any equivelants, just create an empty array
        if(!textEquivalents) textEquivalents = [[NSMutableArray alloc] init];
    }
    
    return(textEquivalents);
}

//Flush any cached emoticon images (and image attachment strings)
- (void)flushEmoticonImageCache
{
    [_cachedAttributedString release]; _cachedAttributedString = nil;
    [_cachedImage release]; _cachedImage = nil;
}
    
//Convert any unix/windows line endings to mac line endings
- (NSString *)_stringWithMacEndlines:(NSString *)inString
{
    NSCharacterSet      *newlineSet = [NSCharacterSet characterSetWithCharactersInString:@"\n"];
    NSMutableString     *newString = nil; //We avoid creating a new string if not necessary
    NSRange             charRange;
    
    //Step through all the invalid endlines
    charRange = [inString rangeOfCharacterFromSet:newlineSet];
    while(charRange.length != 0){
        if(!newString) newString = [[inString mutableCopy] autorelease];

        //Replace endline and continue
        [newString replaceCharactersInRange:charRange withString:@"\r"];
        charRange = [newString rangeOfCharacterFromSet:newlineSet];
    }
    
    return(newString ? newString : inString);
}

//Returns the display name of this emoticon
- (NSString *)name
{
    return([[path lastPathComponent] stringByDeletingPathExtension]);
}

//Enable/Disable this emoticon
- (void)setEnabled:(BOOL)inEnabled
{
    enabled = inEnabled;
}
- (BOOL)isEnabled{
    return(enabled);
}

//Returns the image for this emoticon (cached)
- (NSImage *)image
{
	NSLog(@"Emoticon %@ image",self);
	if(!_cachedImage){
		NSLog(@"   Loading & Caching");
        _cachedImage = [[NSImage alloc] initWithContentsOfFile:[self _pathToEmoticonImage]];
    }

    return(_cachedImage);
}

//Returns an attributed string containing this emoticon
- (NSMutableAttributedString *)attributedStringWithTextEquivalent:(NSString *)textEquivalent
{
    NSMutableAttributedString   *attributedString;
    AITextAttachmentExtension   *attachment;
    
    //Cache this attachment for ourself
    if(!_cachedAttributedString){
        NSFileWrapper               *emoticonFileWrapper = [[[NSFileWrapper alloc] initWithPath:[self _pathToEmoticonImage]] autorelease];
        AITextAttachmentExtension   *emoticonAttachment = [[[AITextAttachmentExtension alloc] init] autorelease];
        
		[emoticonAttachment setImagePath:[self _pathToEmoticonImage]];
		[emoticonAttachment setImageSize:[[self image] size]];
        [emoticonAttachment setFileWrapper:emoticonFileWrapper];
		[emoticonAttachment setHasAlternate:YES];
        _cachedAttributedString = [[NSAttributedString attributedStringWithAttachment:emoticonAttachment] retain];
    }
    
    //Create a copy of our cached string, and update it for the new text equivalent
    attributedString = [_cachedAttributedString mutableCopy];
    attachment = [attributedString attribute:NSAttachmentAttributeName atIndex:0 effectiveRange:nil];
    [attachment setString:textEquivalent];
    
    return([attributedString autorelease]);
}

//Returns the path to our emoticon image
- (NSString *)_pathToEmoticonImage
{
    NSDirectoryEnumerator   *enumerator;
    NSString		    *fileName;
    
    //Search for the file named Emoticon in our bundle (It can be in any image format)
    enumerator = [[NSFileManager defaultManager] enumeratorAtPath:path];
    while(fileName = [enumerator nextObject]){
		if([fileName hasPrefix:@"Emoticon"]) return([path stringByAppendingPathComponent:fileName]);
    }
    
    return(nil);
}

//A more useful debug description
- (NSString *)description
{
    return([NSString stringWithFormat:@"%@ (%@)", [[path lastPathComponent] stringByDeletingPathExtension], [[self textEquivalents] objectAtIndex:0]]);
}

@end

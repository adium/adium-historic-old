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

#import "AIEmoticon.h"

@interface AIEmoticon (PRIVATE)
- (AIEmoticon *)initWithIconPath:(NSString *)inPath equivalents:(NSArray *)inTextEquivalents name:(NSString *)inName;
- (NSString *)_stringWithMacEndlines:(NSString *)inString;
- (void)setTextEquivalents:(NSArray *)inArray;
- (void)setCachedString:(NSAttributedString *)inString image:(NSImage *)inImage;
- (NSString *)_pathToEmoticonImage;
@end

@implementation AIEmoticon

//Create a new emoticon
+ (id)emoticonWithIconPath:(NSString *)inPath equivalents:(NSArray *)inTextEquivalents name:(NSString *)inName
{
    return([[[self alloc] initWithIconPath:inPath equivalents:inTextEquivalents name:inName] autorelease]);
}

//Init
- (AIEmoticon *)initWithIconPath:(NSString *)inPath equivalents:(NSArray *)inTextEquivalents name:(NSString *)inName
{
    [super init];
    path = [inPath retain];
	name = [inName retain];
    textEquivalents = [inTextEquivalents retain];
    _cachedAttributedString = nil;
    
    return(self);
}

//Dealloc
- (void)dealloc
{
    [path release];
	[name release];
    [textEquivalents release];
    [_cachedAttributedString release];
    [_cachedImage release];

	[super dealloc];
}

//Returns an array of the text equivalents for this emoticon
- (NSArray *)textEquivalents
{
    return(textEquivalents);
}

//Flush any cached emoticon images (and image attachment strings)
- (void)flushEmoticonImageCache
{
    [_cachedAttributedString release]; _cachedAttributedString = nil;
    [_cachedImage release]; _cachedImage = nil;
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

//Returns the image for this emoticon
- (NSImage *)image
{
    return([[[NSImage alloc] initWithContentsOfFile:path] autorelease]);
}

//Returns an attributed string containing this emoticon
- (NSMutableAttributedString *)attributedStringWithTextEquivalent:(NSString *)textEquivalent
{
    NSMutableAttributedString   *attributedString;
    AITextAttachmentExtension   *attachment;
    
    //Cache this attachment for ourself
    if(!_cachedAttributedString){
        NSFileWrapper               *emoticonFileWrapper = [[[NSFileWrapper alloc] initWithPath:path] autorelease];
        AITextAttachmentExtension   *emoticonAttachment = [[[AITextAttachmentExtension alloc] init] autorelease];
        
		[emoticonAttachment setImagePath:path];
		[emoticonAttachment setImageSize:[[self image] size]];
        [emoticonAttachment setFileWrapper:emoticonFileWrapper];
		[emoticonAttachment setHasAlternate:YES];
		
		//Emoticons should not ever be sent out as images
		[emoticonAttachment setShouldAlwaysSendAsText:YES];
		
        _cachedAttributedString = [[NSAttributedString attributedStringWithAttachment:emoticonAttachment] retain];
    }
    
    //Create a copy of our cached string, and update it for the new text equivalent
    attributedString = [_cachedAttributedString mutableCopy];
    attachment = [attributedString attribute:NSAttachmentAttributeName atIndex:0 effectiveRange:nil];
    [attachment setString:textEquivalent];
    
    return([attributedString autorelease]);
}

//A more useful debug description
- (NSString *)description
{
    return([NSString stringWithFormat:@"%@ (%@)", [[path lastPathComponent] stringByDeletingPathExtension], [[self textEquivalents] objectAtIndex:0]]);
}

@end

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
#import <AIUtilities/AIUtilities.h>

@interface AIEmoticon (PRIVATE)
- (void)updateAttributedEmoticon;
@end

@implementation AIEmoticon

+ (id)emoticon
{
    return([[[self alloc] init] autorelease]);
}

- (id)init
{
    [super init];

    path = nil;
    representedText = nil;

    return(self);
}

- (id)initWithPath:(NSString *)inPath andText:(NSString *)inText
{
    [self setRepresentedText:inText];
    [self setPath:inPath];

    return(self);
}

- (void)dealloc
{
    [path release];
    [representedText release];
    [attributedEmoticon release];

    [super dealloc];
}

- (NSString *)path
{
    return path;
}

- (NSEnumerator *)representedTextEnumerator
{
    return [representedText objectEnumerator];
}
- (NSAttributedString *)attributedEmoticon
{
    return attributedEmoticon;
}

- (NSString *)string
{
    if([representedText count] != 0){
	return [representedText objectAtIndex:0];
    }else{
	return nil;
    }
}

- (void)setRepresentedText:(NSString *)returnDelimitedString
{
    NSArray		*textStrings = [returnDelimitedString componentsSeparatedByString:@"\r"];
    NSEnumerator	*enumerator = [textStrings objectEnumerator];
    NSString		*currentString = nil;

    [representedText release]; representedText = [[NSMutableArray alloc] init];

    while(currentString = [enumerator nextObject]){
	[representedText addObject:[currentString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
    }
}

- (void)setPath:(NSString *)inPath
{
    if(path != inPath){
        [path release];
        path = [inPath retain];
    }

    [self updateAttributedEmoticon];
}

- (void)updateAttributedEmoticon
{
    NSFileWrapper		*emoticonFileWrapper = [[[NSFileWrapper alloc] initWithPath:path] autorelease];
    AITextAttachmentExtension	*emoticonAttachment = [[[AITextAttachmentExtension alloc] init] autorelease];

    [emoticonAttachment setFileWrapper:emoticonFileWrapper];
    [emoticonAttachment setString:[self string]];

    [attributedEmoticon release];
    attributedEmoticon = [[NSAttributedString attributedStringWithAttachment:emoticonAttachment] retain];
}

@end

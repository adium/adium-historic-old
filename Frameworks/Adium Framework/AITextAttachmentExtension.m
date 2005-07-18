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

#import "AITextAttachmentExtension.h"

@implementation AITextAttachmentExtension

- (id)init
{
    if ((self = [super init]))
	{
		stringRepresentation = nil;
		shouldSaveImageForLogging = NO;
		hasAlternate = NO;
		shouldAlwaysSendAsText = NO;
		imagePath = nil;
		imageSize = NSMakeSize(0,0);
	}
	
    return self;
}

- (void)dealloc
{
	[imagePath release];
	[stringRepresentation release];
	[super dealloc];
}
    
- (void)setString:(NSString *)inString
{
    if (stringRepresentation != inString) {
        [stringRepresentation release];
        stringRepresentation = [inString retain];
    }
}

/*!
 * @brief If asked for a string and we don't have one available, set and return a globally unique string
 */
- (NSString *)string
{
	if (stringRepresentation == nil) {
		[self setString:[[NSProcessInfo processInfo] globallyUniqueString]];
    }
	
    return (stringRepresentation);
}

- (void)setImagePath:(NSString *)inPath
{
	if (imagePath != inPath) {
		[imagePath release];
		imagePath = [inPath retain];
	}
}
- (NSString *)imagePath
{
	return imagePath;
}

- (void)setImageSize:(NSSize)inSize
{
	imageSize = inSize;
}
- (NSSize)imageSize
{
	return imageSize;
}

- (BOOL)shouldSaveImageForLogging
{
    return shouldSaveImageForLogging;
}
- (void)setShouldSaveImageForLogging:(BOOL)flag
{
    shouldSaveImageForLogging = flag;
}

- (BOOL)hasAlternate
{
	return hasAlternate;
}
- (void)setHasAlternate:(BOOL)flag
{
	hasAlternate = flag;
}

- (BOOL)shouldAlwaysSendAsText
{
	return shouldAlwaysSendAsText;
}
- (void)setShouldAlwaysSendAsText:(BOOL)flag
{
	shouldAlwaysSendAsText = flag;	
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"%@<%x>: %@",NSStringFromClass([self class]),self,[super description]];
}

@end

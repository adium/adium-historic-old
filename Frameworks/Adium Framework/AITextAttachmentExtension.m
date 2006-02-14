/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2006, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AITextAttachmentAdditions.h>

@implementation AITextAttachmentExtension

- (id)init
{
    if ((self = [super init])) {
		stringRepresentation = nil;
		shouldSaveImageForLogging = NO;
		hasAlternate = NO;
		shouldAlwaysSendAsText = NO;
		path = nil;
		image = nil;
	}
	
    return self;
}

/*
 * @brief Deallocate
 */
- (void)dealloc
{
	[image release];
	[path release];
	[stringRepresentation release];
	[super dealloc];
}

/*
 * @brief Set the path represented by this text attachment
 *
 * If an image has not been set, and this path points to an image, [self image] will return the image, loading it from this path
 */
- (void)setPath:(NSString *)inPath
{
	if (inPath != path) {
		[path release];
		path = [inPath retain];
	}
}

- (NSString *)path
{
	return path;
}

/*
 * @brief Set the image represented by this text attachment
 */
- (void)setImage:(NSImage *)inImage
{
	if (inImage != image) {
		[image release];
		image = [inImage retain];
	}
}

/*
 * @brief Returns YES if this attachment is for an image
 */
- (BOOL)attachesAnImage
{
	BOOL attachesAnImage = (image != nil);
	
	if (!attachesAnImage && path) {
		NSArray			*imageFileTypes = [NSImage imageFileTypes];
		OSType			HFSTypeCode = [[[NSFileManager defaultManager] fileAttributesAtPath:path traverseLink:YES] fileHFSTypeCode];
		NSString		*pathExtension;
		
		attachesAnImage = ([imageFileTypes containsObject:NSFileTypeForHFSTypeCode(HFSTypeCode)] ||
					  ((pathExtension = [path pathExtension]) && [imageFileTypes containsObject:pathExtension]));
	}

	return attachesAnImage;
}

- (NSImage *)image
{
	if (!image && [self wrapsImage]) {
		image = [[NSImage alloc] initWithContentsOfFile:[self path]];
	}
	
	return image;
}

/*
 * @brief Return a 32x32 image representing this attachment
 */
- (NSImage *)iconImage
{
	NSImage *originalImage;
	NSImage *iconImage;

	if ((originalImage = [self image])) {
		iconImage = [originalImage imageByScalingToSize:NSMakeSize(32, 32)];

	} else {
		iconImage = [[NSWorkspace sharedWorkspace] iconForFile:[self path]];
	}
	
	return iconImage;
}

- (void)setString:(NSString *)inString
{
    if (stringRepresentation != inString) {
        [stringRepresentation release];
        stringRepresentation = [inString retain];
    }
}

/*
 * @brief Return a fileWrapper for the file/image we represent, creating and caching it if necessary
 *
 * @result An NSFileWrapper
 */
- (NSFileWrapper *)fileWrapper
{
	NSFileWrapper *myFilewrapper = [super fileWrapper];
	
	if (!myFilewrapper) {
		if ([self path]) {
			myFilewrapper = [[[NSFileWrapper alloc] initWithPath:[self path]] autorelease];

		} else if ([self image]) {
			myFilewrapper = [[[NSFileWrapper alloc] initWithSerializedRepresentation:[[self image] TIFFRepresentation]] autorelease];
		}

		[self setFileWrapper:myFilewrapper];
	}
	
	return myFilewrapper;
}

/*!
 * @brief Return a string which represents our object
 *
 * If asked for a string and we don't have one available, create, cache, and return a globally unique string
 */
- (NSString *)string
{
	if (stringRepresentation == nil) {
		[self setString:[[NSProcessInfo processInfo] globallyUniqueString]];
    }
	
    return (stringRepresentation);
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

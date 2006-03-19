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

#define ICON_WIDTH	64
#define ICON_HEIGHT	64

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
		imageClass = nil;
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

- (void)encodeWithCoder:(NSCoder *)encoder
{
	if ([encoder allowsKeyedCoding]) {
        [encoder encodeObject:stringRepresentation forKey:@"AITextAttachmentExtension_stringRepresentation"];
        [encoder encodeObject:[NSNumber numberWithBool:shouldSaveImageForLogging] forKey:@"AITextAttachmentExtension_shouldSaveImageForLogging"];
        [encoder encodeObject:[NSNumber numberWithBool:hasAlternate] forKey:@"AITextAttachmentExtension_hasAlternate"];
        [encoder encodeObject:[NSNumber numberWithBool:shouldAlwaysSendAsText] forKey:@"AITextAttachmentExtension_shouldAlwaysSendAsText"];
		[encoder encodeObject:path forKey:@"AITextAttachmentExtension_path"];
		[encoder encodeObject:image forKey:@"AITextAttachmentExtension_image"];
		
    } else {
        [encoder encodeObject:stringRepresentation];
        [encoder encodeObject:[NSNumber numberWithBool:shouldSaveImageForLogging]];
        [encoder encodeObject:[NSNumber numberWithBool:hasAlternate]];
        [encoder encodeObject:[NSNumber numberWithBool:shouldAlwaysSendAsText]];
		[encoder encodeObject:path];
		[encoder encodeObject:image];
    }
}

/*!
* @brief Initialize with coder
 */
- (id)initWithCoder:(NSCoder *)decoder
{
	if ((self = [super init]))
	{
		if ([decoder allowsKeyedCoding]) {
			// Can decode keys in any order		
			[self setString:[decoder decodeObjectForKey:@"AITextAttachmentExtension_stringRepresentation"]];
			[self setShouldSaveImageForLogging:[[decoder decodeObjectForKey:@"AITextAttachmentExtension_shouldSaveImageForLogging"] boolValue]];
			[self setHasAlternate:[[decoder decodeObjectForKey:@"AITextAttachmentExtension_hasAlternate"] boolValue]];
			[self setShouldAlwaysSendAsText:[[decoder decodeObjectForKey:@"AITextAttachmentExtension_shouldAlwaysSendAsText"] boolValue]];
			[self setPath:[decoder decodeObjectForKey:@"AITextAttachmentExtension_path"]];
			[self setImage:[decoder decodeObjectForKey:@"AITextAttachmentExtension_image"]];
			
		} else {
			// Must decode keys in same order as encodeWithCoder:		
			[self setString:[decoder decodeObject]];
			[self setShouldSaveImageForLogging:[[decoder decodeObject] boolValue]];
			[self setHasAlternate:[[decoder decodeObject] boolValue]];
			[self setShouldAlwaysSendAsText:[[decoder decodeObject] boolValue]];
			[self setPath:[decoder decodeObject]];
			[self setImage:[decoder decodeObject]];
		}
	}
	
	return self;
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
	if (!image && [self attachesAnImage]) {
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
		NSSize currentSize = [originalImage size];
		if ((currentSize.width > ICON_WIDTH) || (currentSize.height > ICON_HEIGHT)) {
			iconImage = [originalImage imageByScalingToSize:NSMakeSize(ICON_WIDTH, ICON_WIDTH)];

		} else {
			iconImage = [[originalImage copy] autorelease];
		}

	} else {
		iconImage = [[NSWorkspace sharedWorkspace] iconForFile:[self path]];
	}
	
	return iconImage;
}

- (void)setString:(NSString *)inString
{
    if (stringRepresentation != inString) {
        [stringRepresentation autorelease];
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

- (void)setImageClass:(NSString *)inString
{
	if (imageClass != inString) {
        [imageClass autorelease];
        imageClass = [inString retain];
    }
}

- (NSString *)imageClass
{
	return imageClass;
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

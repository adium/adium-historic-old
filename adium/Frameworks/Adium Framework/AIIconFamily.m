/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2002, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

#import "AIIconFamily.h"
#import "AIAdium.h"

@interface AIIconFamily (PRIVATE)
- (id)initWithClosedImage:(NSImage *)newClosedImage openedImage:(NSImage *)newOpenedImage alertImage:(NSImage *)newAlertImage;
- (id)initFromFolder:(NSString *)folderPath;
- (id)initFromFolderNamed:(NSString *)folderName;
@end


@implementation AIIconFamily

// Public creation methods
+ (id)iconFamilyWithClosedImage:(NSImage *)newClosedImage openedImage:(NSImage *)newOpenedImage alertImage:(NSImage *)newAlertImage
{
    return [[[AIIconFamily alloc] initWithClosedImage:newClosedImage openedImage:newOpenedImage alertImage:newAlertImage] autorelease];
}

+ (id)iconFamilyFromFolder:(NSString *)folderPath {
    return [[[AIIconFamily alloc] initFromFolder:folderPath] autorelease];
}

+ (id)iconFamilyNamed:(NSString *)folderName {
    return [[[AIIconFamily alloc] initFromFolderNamed:folderName] autorelease];
}

// Private creation methods
- (id)initWithClosedImage:(NSImage *)newClosedImage openedImage:(NSImage *)newOpenedImage alertImage:(NSImage *)newAlertImage {
    if (newClosedImage == nil || openedImage == nil || alertImage == nil) {
        NSLog(@"Warning: Unable to create icon family object (one or more of the provided images were nil).");
        return nil;
    }
    
    closedImage = [newClosedImage retain];
    openedImage = [newOpenedImage retain];
    alertImage = [newAlertImage retain];

    return self;
}

- (id)initFromFolder:(NSString *)folderPath {
    NSString *closedImagePath = [folderPath stringByAppendingPathComponent:@"closed.tif"];
    NSString *openedImagePath = [folderPath stringByAppendingPathComponent:@"opened.tif"];
    NSString *alertImagePath = [folderPath stringByAppendingPathComponent:@"alert.tif"];

    return [self initWithClosedImage:[[NSImage alloc] initWithContentsOfFile:closedImagePath] openedImage:[[NSImage alloc] initWithContentsOfFile:openedImagePath] alertImage:[[NSImage alloc] initWithContentsOfFile:alertImagePath]];
}

- (id)initFromFolderNamed:(NSString *)folderName {
    NSString *iconFamiliesPath = [[[NSString stringWithString:@"~/Library/Application Support/Adium 2.0"] stringByExpandingTildeInPath] stringByAppendingPathComponent:@"Icon Families"];

    return [self initFromFolder:[iconFamiliesPath stringByAppendingPathComponent:folderName]];
}

// Public accessor functions
- (NSImage *)closedImage {
    return closedImage;
}

- (NSImage *)openedImage {
    return openedImage;
}

- (NSImage *)alertImage {
    return alertImage;
}

- (void)dealloc {
    [closedImage release];
    [openedImage release];
    [alertImage release];
}

@end

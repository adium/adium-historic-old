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

#import "NSImage+AIBookmarksImport.h"

#import <ApplicationServices/ApplicationServices.h>

static NSDictionary *defaultBookmarkIcons = nil;

@implementation NSImage (AIBookmarksImport)

+ (NSImage *)folderIcon
{
	return [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericFolderIcon)];
}
+ (NSImage *)iconForURLScheme:(NSString *)scheme {
	NSParameterAssert(scheme != nil);

	if(!defaultBookmarkIcons) {
		NSWorkspace *workspace = [NSWorkspace sharedWorkspace];

		//icons for multiple schemes
		NSImage *webIcon  = [workspace iconForFileType:NSFileTypeForHFSTypeCode(kInternetLocationHTTPIcon)];
		NSImage *ftpIcon  = [workspace iconForFileType:NSFileTypeForHFSTypeCode(kInternetLocationFTPIcon)];
		NSImage *newsIcon = [workspace iconForFileType:NSFileTypeForHFSTypeCode(kInternetLocationNewsIcon)];

		defaultBookmarkIcons = [[NSDictionary alloc] initWithObjectsAndKeys:
			webIcon, @"http",
			webIcon, @"https",
			ftpIcon, @"ftp",
			ftpIcon, @"ftps",
			ftpIcon, @"sftp",
			[workspace iconForFileType:NSFileTypeForHFSTypeCode(kInternetLocationAppleShareIcon)], @"afp", 
			[workspace iconForFileType:NSFileTypeForHFSTypeCode(kInternetLocationFileIcon)], @"file",
			[workspace iconForFileType:NSFileTypeForHFSTypeCode(kInternetLocationMailIcon)], @"mailto",
			newsIcon, @"nntp",
			newsIcon, @"news",
			[workspace iconForFileType:NSFileTypeForHFSTypeCode(kInternetLocationGenericIcon)], ADIUM_GENERIC_ICON_SCHEME,
			//kInternetLocationNSLNeighborhoodIcon and kInternetLocationAppleTalkZoneIcon are not represented here because Mac OS X has no icon for them.
			nil];
	}

	return [defaultBookmarkIcons objectForKey:scheme];
}

@end

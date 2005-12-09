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

#import "AIXtraInfo.h"


@implementation AIXtraInfo

- (NSString *)type
{
	return type;
}

- (NSString *)name
{
	return name;
}

- (void) setName:(NSString *)inName
{
	name = inName;
}

- (NSString *) description
{
	return [NSString stringWithFormat:@"%@, %@, %@, retaincount=%d", [self name], [self path], [self type], [self retainCount]];
}

+ (AIXtraInfo *) infoWithURL:(NSURL *)url
{
	return [[[self alloc] initWithURL:url] autorelease];
}

- (id) initWithURL:(NSURL *)url
{
	if((self = [super init]))
	{
		path = [[url path] retain];
		type = [[[[url path] pathExtension] lowercaseString] retain];
		NSBundle * xtraBundle = [[NSBundle alloc] initWithPath:path];
		if (xtraBundle && ([[xtraBundle objectForInfoDictionaryKey:@"XtraBundleVersion"] intValue] == 1)) { //This checks for a new-style xtra
			name = [xtraBundle objectForInfoDictionaryKey:(NSString *)kCFBundleNameKey];
			resourcePath = [[xtraBundle resourcePath] retain];
			icon = [[NSImage alloc] initByReferencingFile:[xtraBundle pathForResource:@"Icon" ofType:@"icns"]];
			readMePath = [[xtraBundle pathForResource:@"ReadMe" ofType:@"rtf"] retain];
			if (!readMePath)
				readMePath = [[[NSBundle mainBundle] pathForResource:@"DefaultXtraReadme" ofType:@"rtf"] retain];

		}
		else {
			name = [[[path lastPathComponent] stringByDeletingPathExtension]retain];
			resourcePath = @"";//root of the xtra
			readMePath = [[[NSBundle mainBundle] pathForResource:@"DefaultXtraReadme" ofType:@"rtf"] retain];
		}	
		if(!icon)
			icon = [[[NSWorkspace sharedWorkspace] iconForFile:path]retain];
	}
	return self;
}

- (NSImage *) icon
{
	return icon;
}

- (void) dealloc
{
	[icon release];
	[path release];
	[name release];
	[resourcePath release];
	[type release];
	[readMePath release];
	[super dealloc];
}

- (NSString *)resourcePath
{
	return resourcePath;
}

- (NSString *)path
{
	return path;
}

- (NSString *)readMePath
{
	return readMePath;
}

@end

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

- (NSString *)name
{
	return name;
}

- (void) setName:(NSString *)inName
{
	name = inName;
}

+ (AIXtraInfo *) infoWithURL:(NSURL *)url
{
	return [[[self alloc] initWithURL:url] autorelease];
}

- (id) initWithURL:(NSURL *)url//url to a plist with info
{
	if((self = [super init]))
	{
		/*NSDictionary * info = [NSDictionary dictionaryWithContentsOfURL:
		name = [info objectForKey:@"Name"];*/
		path = [[url path] retain];
		name = [[[path lastPathComponent] stringByDeletingPathExtension]retain];
		NSBundle * xtraBundle = [[NSBundle alloc] initWithPath:path];
		if(xtraBundle && ([[xtraBundle objectForInfoDictionaryKey:@"XtraBundleVersion] intValue == 1))//This checks for a new-style xtra
		{
			readMePath = [[xtraBundle pathForResource:@"ReadMe" ofType:@"rtf"]retain];
			icon = [[NSImage alloc] initByReferencingFile:[xtraBundle pathForResource:@"Icon" ofType:@"icns"]];
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
	[readMePath release];
	[super dealloc];
}

- (NSString *)readMePath
{
	return readMePath;
}

- (NSString *)path
{
	return path;
}
@end

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

#import "BDImporter.h"

@interface BDImporter(PRIVATE)


@end

@implementation BDImporter

#pragma mark Initialization & Deallocation
#pragma mark -

- (id)initWithIdentifier:(NSString *)clientName
{
	clientIcon = [[NSWorkspace sharedWorkspace]iconForFile:[[NSWorkspace sharedWorkspace] fullPathForApplication:clientName]];
	
	return self;
}

- (void)dealloc
{
	[super dealloc];
}

#pragma mark Simple accessors
#pragma mark -

- (NSImage *)iconAtSize:(int)iconSize
{
	[clientIcon setSize:NSMakeSize(iconSize,iconSize)];
	return clientIcon;
}

#pragma mark -
#pragma mark Data interaction methods

- (NSString *)versionForApplication:(NSString *)applicationName
{
	NSString *path = [NSString stringWithString:[[NSWorkspace sharedWorkspace] fullPathForApplication:applicationName]];
	NSBundle *appBundle = [NSBundle bundleWithPath:path];
	return [[appBundle infoDictionary] objectForKey:@"CFBundleVersion"];
}

@end

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

#import "AIBookmarksImporter.h"
#import "AIBookmarksImporterController.h"

@interface AIBookmarksImporter (PRIVATE)

- (void)insertBookmarks:(NSDictionary *)bookmarks intoMenu:(NSMenu *)inMenu;
- (void)insertMenuItemForBookmark:(NSDictionary *)object intoMenu:(NSMenu *)inMenu;

@end

@implementation AIBookmarksImporter

+ (AIBookmarksImporter *)importer
{
	return [[[self alloc] init] autorelease];
}

- (id)init
{
	if((self = [super init])) {
		lastModDate = nil;

		[[AIBookmarksImporterController sharedController] addImporter:self];
	}
	return self;
}

- (void)dealloc
{
	[[AIBookmarksImporterController sharedController] removeImporter:self];
	[lastModDate release];
	[super dealloc];
}

#pragma mark -
#pragma mark Abstract methods

+ (NSString *)bookmarksPath
{
	return nil;
}
- (NSArray *)availableBookmarks
{
	return nil;
}
- (BOOL)bookmarksHaveChanged
{
	NSString *bookmarksPath = [[self class] bookmarksPath];

	/*-bookmarksPath should return a path to an existing file.
	 *if it existed in the past, lastModDate will be nil. ceasing to exist
	 *	counts as a change.
	 *if it does exist, but lastModDate is nil, then the file has been created
	 *	(or we never looked before); this, too, counts as a change.
	 */
	if(!bookmarksPath)    return (lastModDate != nil);
	else if(!lastModDate) return YES;

    NSDictionary *fileProps = [[NSFileManager defaultManager] fileAttributesAtPath:bookmarksPath
																	  traverseLink:YES];
    NSDate *modDate = [fileProps objectForKey:NSFileModificationDate];
    
    return ((!lastModDate) || (![modDate isEqualToDate:lastModDate]));
}

#pragma mark -

+ (BOOL)browserIsAvailable
{
	return [self bookmarksPath] != nil;
}

+ (NSString *)browserName
{
	return nil;
}
+ (NSImage  *)browserIcon
{
	NSString *browserPath = [self browserPath];
	return browserPath ? [[NSWorkspace sharedWorkspace] iconForFile:browserPath] : nil;
}
+ (NSString *)browserSignature
{
	return nil;
}
+ (NSString *)browserBundleIdentifier
{
	return nil;
}
+ (NSString *)browserPath
{
	NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
	NSString *path = nil;

	NSString *bundleID = [self browserBundleIdentifier];
	if(bundleID) {
		path = [workspace absolutePathForAppBundleWithIdentifier:bundleID];
	}

	if(!path) {
		NSString *signatureString = [self browserSignature];
		OSType signature = signatureString ? NSHFSTypeCodeFromFileType(signatureString) : 0;
		if(signature) {
			NSURL *URL = nil;
			OSStatus err = LSGetApplicationForInfo('APPL', signature,
												   /*inExtension*/ NULL,
												   /*inRolesMask*/ kLSRolesAll,
												   /*outAppRef*/ NULL,
												   (CFURLRef *)&URL);
			if(err == noErr) {
				path = [URL path];
			}
			//note: despite the name, LSGetApplicationForInfo implicitly retains URL. don't remove this release call.
			[URL release];
		}
	}

	if(!path) {
		NSString *appName = [self browserName];
		path = [workspace fullPathForApplication:appName];
	}

	return path;
}
+ (NSURL    *)browserURL
{
	return [NSURL fileURLWithPath:[self browserPath]];
}

//by default: bundle identifier, signature, name, filename (in that order of preference)
- (NSString *)importerIdentifier
{
	NSString       *identifier =  [[self class] browserBundleIdentifier];
	if(!identifier) identifier =  [[self class] browserSignature];
	if(!identifier) identifier =  [[self class] browserName];
	if(!identifier) identifier = [[[self class] browserPath] lastPathComponent];

	return identifier;
}

- (NSView *)customView
{
	return nil;
}

#pragma mark Useful methods

+ (NSDictionary *)dictionaryForBookmarksItemWithTitle:(NSString *)inTitle content:(id)inContent image:(NSImage *)inImage
{
	return [self dictionaryForBookmarksItemWithTitle:inTitle content:inContent image:inImage appendURIToTitle:NO];
}
+ (NSDictionary *)dictionaryForBookmarksItemWithTitle:(NSString *)inTitle content:(id)inContent image:(NSImage *)inImage appendURIToTitle:(BOOL)appendURI
{
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:4];
	if(inTitle)   [dict setObject:inTitle   forKey:ADIUM_BOOKMARK_DICT_TITLE];
	if(inContent) [dict setObject:inContent forKey:ADIUM_BOOKMARK_DICT_CONTENT];
	if(inImage)   [dict setObject:inImage   forKey:ADIUM_BOOKMARK_DICT_FAVICON];
	[dict setObject:[NSNumber numberWithBool:appendURI] forKey:ADIUM_BOOKMARK_DICT_APPENDURI];
	return dict;
}

#pragma mark Menu creation

/*!
 * @brief Insert a bookmark (or a group of bookmarks) into the menu
 *
 * Adds a menu item to the menu, containing a hierarchical submenu with at least one leaf menu item within it.
 * This method is recursive - if <tt>bookmarks</tt> is a group, and another group is within it, this method will be called again on the subgroup.
 */
- (void)insertBookmarks:(NSDictionary *)bookmarks intoMenu:(NSMenu *)inMenu
{	
	//Recursively add the contents of the group to the parent menu
	NSMenu			*menu = [[[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:@""] autorelease];
	id				content = [bookmarks objectForKey:ADIUM_BOOKMARK_DICT_CONTENT];
	if([content isKindOfClass:[NSURL class]]) {
		//it's a single link
		[self insertMenuItemForBookmark:bookmarks intoMenu:menu];
	} else {
		//it's a group
		NSEnumerator	*enumerator = [content objectEnumerator];
		id				object;
	
		while((object = [enumerator nextObject])) {
			[self insertBookmarks:object intoMenu:menu];
		}
	}

	//Insert the submenu we built into the menu
	NSMenuItem		*item = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:[bookmarks objectForKey:ADIUM_BOOKMARK_DICT_TITLE] 
																				  action:nil
																		   keyEquivalent:@""] autorelease];
	[item setImage:[bookmarks objectForKey:ADIUM_BOOKMARK_DICT_FAVICON]];
	[item setSubmenu:menu];
	[menu setAutoenablesItems:NO];
	[inMenu addItem:item];
}

/*!
 * @brief Insert a single bookmark into the menu
 */
- (void)insertMenuItemForBookmark:(NSDictionary *)object intoMenu:(NSMenu *)inMenu
{
	NSString	*title = [object objectForKey:ADIUM_BOOKMARK_DICT_TITLE];
	if(title && [title length]){
		NSMenuItem	*theMenuItem;
		
		theMenuItem = [[NSMenuItem alloc] initWithTitle:title
												 action:@selector(injectBookmarkFrom:)
										  keyEquivalent:@""];
		[theMenuItem setTarget:[AIBookmarksImporterController sharedController]];
		[theMenuItem setRepresentedObject:object];
		
		[inMenu addItem:theMenuItem];

		[theMenuItem release];
	}
}

@end

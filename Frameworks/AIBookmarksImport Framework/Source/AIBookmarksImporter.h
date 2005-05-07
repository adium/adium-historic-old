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

#define ADIUM_BOOKMARK_DICT_TITLE      @"Title"
#define ADIUM_BOOKMARK_DICT_CONTENT    @"Content"
#define ADIUM_BOOKMARK_DICT_FAVICON    @"Favicon"
#define ADIUM_BOOKMARK_DICT_APPENDURI  @"AppendURIToTitle"

/*this is an abstract class.
 *
 *SUBCLASSING INSTRUCTIONS
 *
 *you need to override:
 *	+browserName
 *	+bookmarksPath
 *	-availableBookmarks
 *you should also override:
 *	+browserSignature
 *	+browserBundleIdentifier
 *you may also override:
 *	-importerIdentifier
 *	-customView
 *see below for further details.
 */

@interface AIBookmarksImporter : NSObject {
	NSDate	*lastModDate;
}

#pragma mark -

/*the abstract version of this method simply looks up the browser's location
 *	using -browserPath, returning YES if a location is found.
 *your subclass should probably use the location of the bookmarks instead.
 *if you do simply use the abstract implementation, be sure to implement one of:
 *	- +browserName
 *	- +browserSignature
 *	- +browserBundleIdentifier
 *or override +browserPath.
 */
+ (BOOL)browserIsAvailable;

+ (NSString *)browserName;
+ (NSImage  *)browserIcon;
+ (NSString *)browserSignature; //returns an NSString-encoded HFS file type.
+ (NSString *)browserBundleIdentifier;
+ (NSString *)browserPath; //uses +browser{Name,Signature,BundleIdentifier}
+ (NSURL    *)browserURL; //uses +browserPath

//+bookmarksPath should return a path to a file that exists (i.e. not a directory or a 404).
+ (NSString *)bookmarksPath;

//by default, this returns the first one found (non-nil) of: bundle identifier; signature; name; filename.
- (NSString *)importerIdentifier;

/*this view is used in place of the outline view in the Bookmarks panel.
 *it's OK to return nil from this method, or to not implement it at all.
 */
- (NSView *)customView;

#pragma mark -

//inContent should be either an array of sub-items (for a group) or an URL.
+ (NSDictionary *)dictionaryForBookmarksItemWithTitle:(NSString *)inTitle content:(id)inContent image:(NSImage *)inImage;
+ (NSDictionary *)dictionaryForBookmarksItemWithTitle:(NSString *)inTitle content:(id)inContent image:(NSImage *)inImage appendURIToTitle:(BOOL)appendURI;

/*return an array of bookmark dictionaries.
 *
 *a bookmark dictionary contains these keys:
 *-	ADIUM_BOOKMARK_DICT_TITLE
 *		an NSString or NSAttributedString which is the bookmark's title.
 *- ADIUM_BOOKMARK_DICT_CONTENT
 *		either an NSURL (for individual bookmarks), or an NSArray such as this method returns (for groups).
 *- ADIUM_BOOKMARK_DICT_FAVICON (optional)
 *		an NSImage.
 *- ADIUM_BOOKMARK_DICT_APPENDURI (optional; default: NO)
 *		an NSNumber containing a BOOL. when YES, the bookmark's title when inserted will be 'Title <URI>' rather than just the title.
 */
- (NSArray *)availableBookmarks;

- (BOOL)bookmarksHaveChanged;

#pragma mark -

//convenience factory method
+ (AIBookmarksImporter *)importer;

@end

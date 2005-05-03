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

//#import <Adium/AIObject.h>

@class SHMarkedHyperlink;

#define ADIUM_BOOKMARK_DICT_TITLE      @"Title"
#define ADIUM_BOOKMARK_DICT_CONTENT    @"Content"
#define ADIUM_BOOKMARK_DICT_FAVICON    @"Favicon"

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

+ (NSDictionary *)menuDictWithTitle:(NSString *)inTitle content:(id)inContent image:(NSImage *)inImage;
+ (SHMarkedHyperlink *)hyperlinkForTitle:(NSString *)inString URL:(NSString *)inURLString;

#pragma mark -

- (NSArray *)availableBookmarks;
- (NSMenu *)menuWithAvailableBookmarks;
- (BOOL)bookmarksHaveChanged;

#pragma mark -

//convenience factory method
+ (AIBookmarksImporter *)importer;

@end

/* @function addBookmarksImporter_CFTimer
 *
 *callback function for a CFRunLoopTimer.
 *this function takes the 'info' argument as a Class object for a subclass of
 *	AIBookmarksImporter.
 *it then calls [info browserIsAvailable], and if that returns non-NO, calls
 *	[[info alloc] init] and passes that to -[AIBookmarksImporterPlugin addImporter:]
 *	(if it's non-nil, of course).
 *finally, it autoreleases the timer ([timer autorelease]).
 *this function is intended to be called from a +load method. see below.
 *the idea is to allow time for the shared AIBookmarksImporterPlugin to be
 *	created. note that NSTimer cannot be used for the above because the Cocoa
 *	docs explicitly do not guarantee the existence of any other class when +load is called.
 *(see: http://developer.apple.com/documentation/Cocoa/Reference/Foundation/ObjC_classic/Classes/NSObject.html#//apple_ref/occ/clm/NSObject/load )
 *--boredzo
 */
extern void addBookmarksImporter_CFTimer(CFRunLoopTimerRef timer, void *info);

#ifdef OLD_VERSION

/* @defined AIBOOKMARKSIMPORTER_REGISTERWITHCONTROLLER
 *
 *when writing a subclass of AIBookmarksImporter, use this macro somewhere in
 *	your +load method to get your subclass registered with the bookmarks
 *	importer controller.
 *this macro sets up a CFRunLoopTimer that calls addBookmarksImporter_CFTimer. 
 */
#define AIBOOKMARKSIMPORTER_REGISTERWITHCONTROLLER() \
do { \
	CFRunLoopTimerContext context = { \
		.version         = 0, \
		.info            = self, \
		.retain          = NULL, \
		.release         = NULL, \
		.copyDescription = NULL \
	}; \
	CFRunLoopTimerRef timer = CFRunLoopTimerCreate(kCFAllocatorDefault, \
												   CFAbsoluteTimeGetCurrent() + 0.1, /*fireDate*/ \
												   0.0, /*interval (0 = do not repeat)*/ \
												   0, /*flags*/ \
												   0, /*order*/ \
												   addBookmarksImporter_CFTimer,  \
												   &context); \
	CFRunLoopAddTimer(CFRunLoopGetCurrent(), timer, kCFRunLoopCommonModes); \
} while(0)

#else

#define AIBOOKMARKSIMPORTER_REGISTERWITHCONTROLLER() /*remove me*/

#endif

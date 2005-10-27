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
#import <Cocoa/Cocoa.h>
#import <Adium/AIObject.h>

@class AIXtraInfo;

@interface AIXtrasManager : AIObject {
	NSMutableDictionary				*disabledXtras;
	NSMutableArray					*categoryNames;
	NSMutableArray					*categories;
	NSMutableArray					*categoryImages;
	NSMutableArray					*selectedCategory;
	IBOutlet NSWindow				*window;
	IBOutlet NSTableView			*sidebar;
	IBOutlet NSTableView			*xtraList;
	IBOutlet NSTextView				*infoView;
	NSString						*infoPath;
}

+ (AIXtrasManager *) sharedManager;
- (void) showXtras;
- (void) loadXtras;
- (IBAction) setCategory:(id)sender;
- (NSArray *) arrayOfXtrasAtPaths:(NSArray *)paths;
- (IBAction) browseXtras:(id)sender;
- (IBAction) deleteXtra:(id)sender;
- (IBAction) checkForUpdates:(id)sender;

+ (void) createXtraBundleAtPath:(NSString *)path;

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)row;
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row;
- (int)numberOfRowsInTableView:(NSTableView *)tableView;
@end

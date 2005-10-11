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
#import <Adium/AIObject.h>
#import <Cocoa/Cocoa.h>

@interface AIXtrasManager : AIObject {
	NSMutableDictionary				*disabledXtras;
	NSMutableArray					*categoryNames;
	NSMutableArray					*xtrasCategories;
	int								selectionIndex;
	IBOutlet NSArrayController		*categoryController;
	IBOutlet NSArrayController		*nameController;
	IBOutlet NSWindow				*window;
}

+ (AIXtrasManager *) sharedManager;
- (void) showXtras;
- (void) loadXtras;
- (NSArray *) categoryNames;
- (NSIndexSet *) selectedCategoryIndex;
- (IBAction) setSelectedCategoryIndex:(NSIndexSet *)index;
- (NSArray *) arrayOfXtrasAtPaths:(NSArray *)paths;
- (IBAction) browseXtras:(id)sender;

- (IBAction) deleteXtra:(id)sender;
- (IBAction) checkForUpdates:(id)sender;
@end

/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2003, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

typedef int(*sortfunc)(id, id, BOOL);

#define PREF_GROUP_CONTACT_SORTING			@"Sorting"

@interface AISortController : AIObject {
	NSArray					*statusKeysRequiringResort;
	NSArray					*attributeKeysRequiringResort;
	BOOL					alwaysSortGroupsToTop;
	
	sortfunc				sortFunction;
	
	IBOutlet	NSView		*configureView;
}

- (BOOL)shouldSortForModifiedStatusKeys:(NSArray *)inModifiedKeys;
- (BOOL)shouldSortForModifiedAttributeKeys:(NSArray *)inModifiedKeys;
- (BOOL)alwaysSortGroupsToTop;
- (int)indexForInserting:(AIListObject *)inObject intoObjects:(NSMutableArray *)inObjects;
- (void)sortListObjects:(NSMutableArray *)inObjects;
- (NSView *)configureView;

//For subclasses to override
- (NSString *)identifier;
- (NSString *)displayName;
- (NSArray *)statusKeysRequiringResort;
- (NSArray *)attributeKeysRequiringResort;
- (sortfunc)sortFunction;
- (NSString *)configureSortMenuItemTitle;
- (NSString *)configureSortWindowTitle;
- (NSString *)configureNibName;
- (void)viewDidLoad;
- (IBAction)changePreference:(id)sender;
@end

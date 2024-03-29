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

#import <AIUtilities/AIMultiCellOutlineView.h>
#import <Adium/AIAbstractListController.h>
#import <Adium/AIContactControllerProtocol.h>

@class AIListObject;

typedef enum {
	AINormalBackground = 0,
	AITileBackground,
	AIFillProportionatelyBackground,
	AIFillStretchBackground
} AIBackgroundStyle;

@interface AIListOutlineView : AIMultiCellOutlineView <ContactListOutlineView> {    
	BOOL				groupsHaveBackground;
	BOOL				updateShadowsWhileDrawing;	

	NSImage				*backgroundImage;
	float				backgroundFade;
	BOOL				_drawBackground;
	AIBackgroundStyle	backgroundStyle;
	AIContactListWindowStyle windowStyle;
	
	NSColor				*backgroundColor;
	NSColor				*_backgroundColorWithOpacity;
	float				backgroundOpacity;
	
	NSColor				*highlightColor;

	NSColor				*rowColor;
	NSColor				*_rowColorWithOpacity;
	
	float				minimumDesiredWidth;
	BOOL	 			desiredHeightPadding;
	
	BOOL				unlockingGroup;
	NSPasteboard		*dragContent;
	
	NSArray				*draggedItems;
}

- (void)setDelegate:(id)delegate;
- (int)desiredHeight;
- (int)desiredWidth;
- (void)setMinimumDesiredWidth:(int)inMinimumDesiredWidth;
- (void)setDesiredHeightPadding:(int)inPadding;

//Selection Hiding
- (void)configureSelectionHidingForNewSuperview:(NSView *)newSuperview;
- (void)windowBecameMain:(NSNotification *)notification;
- (void)windowResignedMain:(NSNotification *)notification;

//Contact menu
- (AIListObject *)listObject;
- (NSArray *)arrayOfListObjects;

//Contacts
/*!
 * @brief Index of the first visible list contact
 *
 * @result The index, or -1 if no list contact is visible
 */
- (int)indexOfFirstVisibleListContact;

//Shadows
- (void)setUpdateShadowsWhileDrawing:(BOOL)update;

//Backgrounds
- (void)setBackgroundImage:(NSImage *)inImage;
- (void)setBackgroundStyle:(AIBackgroundStyle)inBackgroundStyle;
- (void)setBackgroundOpacity:(float)opacity forWindowStyle:(AIContactListWindowStyle)windowStyle;
- (void)setBackgroundFade:(float)fade;
- (void)setBackgroundColor:(NSColor *)inColor;
- (NSColor *)backgroundColor;
- (void)setHighlightColor:(NSColor *)inColor;
- (NSColor *)highlightColor;
- (void)setAlternatingRowColor:(NSColor *)color;
- (NSColor *)alternatingRowColor;

//Drag & Drop
- (void)setUnlockGroup:(NSNotification *)notification;
- (BOOL)moveGroup:(AIListGroup *)group to:(AIListObject<AIContainingObject> *)list;

@end

@interface NSObject (AIStandardListOutlineViewDelegate)
- (NSCell *)outlineViewDataCellForContent:(NSOutlineView *)outlineView;
- (NSCell *)outlineViewDataCellForGroup:(NSOutlineView *)outlineView;
@end



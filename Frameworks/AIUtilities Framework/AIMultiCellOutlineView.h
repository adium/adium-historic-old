//
//  AIMultiCellOutlineView.h
//  Adium
//
//  Created by Adam Iser on Tue Mar 23 2004.
//

#import "AIVariableHeightOutlineView.h"

/*!
	@class AIMultiCellOutlineView
	@abstract An outline view with two different cells, one each for expandable and nonexpandable items
	@discussion This outline view is a subclass of <tt>AIVariableHeightOutlineView</tt> which simplifies its implementation into the case with two different cells, one for expandable items ("groups") and one for nonexpandable items ("content").
*/
@interface AIMultiCellOutlineView : AIVariableHeightOutlineView {
	NSCell	*contentCell;
	NSCell	*groupCell;
	
	float   groupRowHeight;
	float   contentRowHeight;
}

/*!
	@method setContentCell:
	@abstract Set the cell used for nonexpandable items
	@discussion Set the cell used for displaying nonexpandable items ("content")
	@param cell The <tt>NSCell</tt> to use for content.
*/
- (void)setContentCell:(NSCell *)cell;
/*!
	@method contentCell
	@abstract Returns the cell used for nonexpandable items
	@discussion Returns the cell used for displaying nonexpandable items ("content")
	@result The <tt>NSCell</tt> used for content.
*/
- (NSCell *)contentCell;

/*!
	@method setGroupCell:
	@abstract Set the cell used for expandable items
	@discussion Set the cell used for displaying expandable items ("groups")
	@param cell The <tt>NSCell</tt> to use for groups.
*/
- (void)setGroupCell:(NSCell *)cell;
/*!
	@method groupCell
	@abstract Returns the cell used for expandable items
	@discussion Returns the cell used for displaying expandable items ("groups")
	@result The <tt>NSCell</tt> used for groups.
*/
- (NSCell *)groupCell;

@end

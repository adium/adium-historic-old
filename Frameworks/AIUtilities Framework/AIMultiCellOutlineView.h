//
//  AIMultiCellOutlineView.h
//  Adium
//
//  Created by Adam Iser on Tue Mar 23 2004.
//

#import "AIVariableHeightOutlineView.h"

@interface AIMultiCellOutlineView : AIVariableHeightOutlineView {
	id		contentCell;
	id		groupCell;
	
	float   groupRowHeight;
	float   contentRowHeight;
}

- (void)setContentCell:(id)cell;
- (void)setGroupCell:(id)cell;
- (id)contentCell;
- (id)groupCell;

@end

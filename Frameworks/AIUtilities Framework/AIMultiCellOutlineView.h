//
//  AIMultiCellOutlineView.h
//  Adium
//
//  Created by Adam Iser on Tue Mar 23 2004.
//

#import "AIOutlineView.h"

@interface AIMultiCellOutlineView : AIAlternatingRowOutlineView {
	int 	*rowHeightCache;
	int 	*rowOriginCache;
	int		totalHeight;
	int 	cacheSize;
	int		entriesInCache;
	
	id		contentCell;
	id		groupCell;
	
	float   groupRowHeight;
	float   contentRowHeight;
	
	BOOL		drawHighlightOnlyWhenMain;
	BOOL		drawsSelectedRowHighlight;
}

- (void)setContentCell:(id)cell;
- (void)setGroupCell:(id)cell;
- (int)totalHeight;
- (id)contentCell;
- (id)groupCell;

- (void)setDrawHighlightOnlyWhenMain:(BOOL)inFlag;
- (BOOL)drawHighlightOnlyWhenMain;
- (void)setDrawsSelectedRowHighlight:(BOOL)inFlag;

@end

@interface NSObject (AIMultiCellVariableHeightCell)
- (int)cellHeightForGroup;
- (int)cellHeightForContent;
@end

@interface NSObject (AIMultiCellGridSupport)
- (BOOL)drawGridBehindCell;
@end

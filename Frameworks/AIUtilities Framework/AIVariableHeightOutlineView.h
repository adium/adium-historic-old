//
//  AIVariableHeightOutlineView.h
//  AIUtilities.framework
//
//  Created by Evan Schoenberg on 11/25/04.
//  Copyright 2004 The Adium Team. All rights reserved.
//

#import "AIAlternatingRowOutlineView.h"

@interface AIVariableHeightOutlineView : AIAlternatingRowOutlineView {
	int 	*rowHeightCache;
	int 	*rowOriginCache;
	int		totalHeight;
	int 	cacheSize;
	int		entriesInCache;

	BOOL	drawHighlightOnlyWhenMain;
	BOOL	drawsSelectedRowHighlight;	
}

- (int)totalHeight;

- (void)setDrawHighlightOnlyWhenMain:(BOOL)inFlag;
- (BOOL)drawHighlightOnlyWhenMain;
- (void)setDrawsSelectedRowHighlight:(BOOL)inFlag;

@end

@interface AIVariableHeightOutlineView (AIVariableHeightOutlineViewAndSubclasses)
- (void)resetRowHeightCache;
@end

@interface NSObject (AIVariableHeightCellSupport)
- (int)cellHeightForGroup;
- (int)cellHeightForContent;
@end

@interface NSObject (AIVariableHeightGridSupport)
- (BOOL)drawGridBehindCell;
@end

@interface NSObject (AIVariableHeightOutlineViewDelegate)
- (int)outlineView:(NSOutlineView *)inOutlineView heightForItem:(id)item atRow:(int)row;
@end

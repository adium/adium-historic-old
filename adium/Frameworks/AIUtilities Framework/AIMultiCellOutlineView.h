//
//  AIMultiCellOutlineView.h
//  Adium
//
//  Created by Adam Iser on Tue Mar 23 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "AIOutlineView.h"

@interface AIMultiCellOutlineView : AIOutlineView {
	int 	*rowHeightCache;
	int 	*rowOriginCache;
	int		totalHeight;
	int 	cacheSize;
	int		entriesInCache;
	
	float   groupRowHeight;
	float   contentRowHeight;
}

- (void)setContentRowHeight:(float)rowHeight;
- (void)setGroupRowHeight:(float)rowHeight;
- (void)setRowHeight:(float)rowHeight;
			
@end

@interface NSObject (AIMultiCellVariableHeightCell)
- (int)cellHeightForGroup;
- (int)cellHeightForContent;
@end

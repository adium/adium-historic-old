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

#import <Cocoa/Cocoa.h>

@class AIAdium, AIContactHandle, AIFlexibleTableColumn, AIFlexibleTableCell;

@protocol AIFlexibleTableViewDelegate <NSObject>
- (AIFlexibleTableCell *)cellForColumn:(AIFlexibleTableColumn *)inCol row:(int)inRow;
- (int)numberOfRows;
@end
//Optional
//I've created additional protocols here ONLY for the reason of stopping compiler warnings.  There is no reason to claim conformance to these protocols.
@protocol AIFlexibleTableViewDelegate_shouldEditTableColumn
- (BOOL)shouldEditTableColumn:(AIFlexibleTableColumn *)inCol row:(int)inRow;
@end
@protocol AIFlexibleTableViewDelegate_setObjectValue
- (void)setObjectValue:(id)object forTableColumn:(AIFlexibleTableColumn *)inCol row:(int)inRow;
@end
@protocol AIFlexibleTableViewDelegate_shouldSelectRow
- (BOOL)shouldSelectRow:(int)inRow;
@end


@interface AIFlexibleTableView : NSControl {
    //Display
    int					oldWidth;		//Used to avoid unnecessary cell resizes calculations
    float				contentsHeight;		//Total height of our content
    NSMutableArray			*rowHeightArray; 	//Height of every row
    AIFlexibleTableColumn		*flexibleColumn;	//Our variable-width column

    //Delegate
    id <AIFlexibleTableViewDelegate>	delegate;		//Our delegate

    //Configuration
    NSMutableArray			*columnArray;		//Our columns
    BOOL				contentBottomAligned;	//YES for bottom-aligned content
    BOOL				forwardsKeyEvents;	//Pass keypresses to next responder

    //Cursor tracking
    NSMutableArray			*cursorTrackingCellArray;
    
    //Selecting
    int					selection_startIndex;
    int					selection_startRow;
    int					selection_startColumn;
    int					selection_endIndex;
    int					selection_endRow;
    int					selection_endColumn;
    }

- (void)setDelegate:(id <AIFlexibleTableViewDelegate>)inDelegate;
- (void)addColumn:(AIFlexibleTableColumn *)inColumn;
- (void)loadNewRow;
- (void)reloadData;
- (void)reloadRow:(int)inRow;
- (void)setContentBottomAligned:(BOOL)inValue;
- (void)setForwardsKeyEvents:(BOOL)inValue;
- (void)resizeCellHeight:(AIFlexibleTableCell *)inCell;

@end






/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2004, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

/*
 A subclass of outline view that adds:

 - Alternating rows
 - Delete key filtering
 - Expand / Collapse state control
 - A vertical column grid
 - Fixes a reload data crash

 */

#import "AIAlternatingRowOutlineView.h"

@interface AIAlternatingRowOutlineView (PRIVATE)
- (void)_drawRowInRect:(NSRect)rect colored:(BOOL)colored selected:(BOOL)selected;
- (void)_init;
- (void)outlineViewDeleteSelectedRows:(NSTableView *)tableView;
- (void)_drawGridInClipRect:(NSRect)rect;
@end

@implementation AIAlternatingRowOutlineView

- (id)initWithCoder:(NSCoder *)aDecoder
{
    [super initWithCoder:aDecoder];

    [self _init];

    return(self);
}

- (id)initWithFrame:(NSRect)frameRect
{
    [super initWithFrame:frameRect];

    [self _init];

    return(self);
}

- (void)dealloc
{
    [alternatingRowColor release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super dealloc];
}

- (void)_init
{
    drawsAlternatingRows = NO;
    alternatingRowColor = [[NSColor colorWithCalibratedRed:(237.0/255.0) green:(243.0/255.0) blue:(254.0/255.0) alpha:1.0] retain];
    
    //Group expand/collapse notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemDidExpand:) name:NSOutlineViewItemDidExpandNotification object:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemDidCollapse:) name:NSOutlineViewItemDidCollapseNotification object:self];

}

// Configuring ----------------------------------------------------------------------
- (void)setDrawsAlternatingRows:(BOOL)flag
{
    drawsAlternatingRows = flag;
    [self setNeedsDisplay:YES];
}

- (void)setAlternatingRowColor:(NSColor *)color
{
    if(color != alternatingRowColor){
        [alternatingRowColor release];
        alternatingRowColor = [color retain];
        [self setNeedsDisplay:YES];
    }
}


// Scrolling ----------------------------------------------------------------------
- (void)tile
{
    [super tile];

    [[self enclosingScrollView] setVerticalLineScroll: ([self rowHeight] + [self intercellSpacing].height) ];
}


// Delete key ---------------------------------------------------------------------
- (void)setDataSource:(id)aSource
{
    [super setDataSource:aSource];
}

//Filter keydowns looking for the delete key (to delete the current selection)
- (void)keyDown:(NSEvent *)theEvent
{
    NSString	*charString = [theEvent charactersIgnoringModifiers];
    unichar	pressedChar = 0;

    //Get the pressed character
    if([charString length] == 1) pressedChar = [charString characterAtIndex:0];

    //Check if 'delete' was pressed
    if(pressedChar == NSDeleteFunctionKey || pressedChar == 127){ //Delete
        if([[self dataSource] respondsToSelector:@selector(outlineViewDeleteSelectedRows:)]){
            [[self dataSource] outlineViewDeleteSelectedRows:self ]; //Delete the selection
        }
    }else{
        [super keyDown:theEvent]; //Pass the key event on
    }
}


// Collapsing/expanding ----------------------------------------------------------------------
@protocol AICollapseExpand
- (void)outlineView:(NSOutlineView *)outlineView setExpandState:(BOOL)state ofItem:(id)item;
- (BOOL)outlineView:(NSOutlineView *)outlineView expandStateOfItem:(id)item;
@end

- (void)itemDidExpand:(NSNotification *)notification
{
    if([[self delegate] respondsToSelector:@selector(outlineView:setExpandState:ofItem:)]){
        [(id <AICollapseExpand>)[self delegate] outlineView:self
                                             setExpandState:YES
                                                     ofItem:[[notification userInfo] objectForKey:@"NSObject"]];
    }
}

- (void)itemDidCollapse:(NSNotification *)notification
{
    if([[self delegate] respondsToSelector:@selector(outlineView:setExpandState:ofItem:)]){
        [(id <AICollapseExpand>)[self delegate] outlineView:self
                                             setExpandState:NO
                                                     ofItem:[[notification userInfo] objectForKey:@"NSObject"]];
    }
}

- (void)_reloadData
{
    if(needsReload){
        [self reloadData];
    }
}

- (void)reloadData
{
    id	selectedItem;
    int	selectedRow;

    /* This code is to correct what I consider a bug with NSOutlineView.
        - Basically, if reloadData is called from 'outlineView:setObjectValue:forTableColumn:byItem:' while the last row is edited in a way that will reduce the # of rows in the table view, things will crash within system code.
        - This crash is evident in many versions of Adium.  When renaming the last contact on the contact list to the name of a contact who already exists on the list, Adium will delete the original contact, reducing the # of rows in the outline view in the midst of the cell editing, causing the crash.
        - The fix is to delay reloading until editing of the last row is complete.  As an added benefit, we skip the delayed reloading if the outline view had been reloaded since the edit, and the reload is no longer necessary.
    */
    if([self numberOfRows] != 0 && ([self editedRow] == [self numberOfRows] - 1) && !needsReload){
        needsReload = YES;
        [self performSelector:@selector(_reloadData) withObject:nil afterDelay:0.0001];

    }else{
        needsReload = NO;

        //Remember the currently selected item
        selectedItem = [self itemAtRow:[self selectedRow]];

        //Reload
        [super reloadData];

        //After reloading data, we correctly expand/collaps all groups
        if([[self delegate] respondsToSelector:@selector(outlineView:expandStateOfItem:)]){
            NSObject <AICollapseExpand> 	*delegate = [self delegate];
            int 	numberOfRows = [delegate outlineView:self numberOfChildrenOfItem:nil];
            int 	row;

            //go through all items
            for(row = 0; row < numberOfRows; row++){
                id item = [delegate outlineView:self child:row ofItem:nil];

                //If the item is expandable, correctly expand/collapse it
                if([delegate outlineView:self isItemExpandable:item]){
                    if([delegate outlineView:self expandStateOfItem:item]){
                        [self expandItem:item];
                    }else{
                        [self collapseItem:item];
                    }
                }
            }
        }

        //Restore (if possible) the previously selected object
        selectedRow = [self rowForItem:selectedItem];
        if(selectedRow != NSNotFound){
            [self selectRow:selectedRow byExtendingSelection:NO];
        }
    }
    
}

- (void)reloadItem:(id)item reloadChildren:(BOOL)reloadChildren
{
	id	selectedItem;
	int	selectedRow;

	//Remember the currently selected item
	selectedItem = [self itemAtRow:[self selectedRow]];

	//Reload
	[super reloadItem:item reloadChildren:reloadChildren];

	//Restore (if possible) the previously selected object
	selectedRow = [self rowForItem:selectedItem];
	if(selectedRow != NSNotFound){
		[self selectRow:selectedRow byExtendingSelection:NO];
	}
}


// Drawing ----------------------------------------------------------------------
//Draw the alternating colors and grid below the "bottom" of the outlineview
- (void)drawRect:(NSRect)rect
{
    NSRect	rowRect;
    int		rowHeight;
    BOOL	coloredRow;
    int		numberOfColumns, numberOfRows;

    //Draw the rest of the outline view first
 [super drawRect:rect];

    //Setup
    numberOfRows = [self numberOfRows];
    numberOfColumns = [self numberOfColumns];
    rowHeight = [self rowHeight] + [self intercellSpacing].height;
    if(numberOfRows == 0){
        rowRect = NSMakeRect(0,0,rect.size.width,rowHeight);
        coloredRow = YES;        
    }else{
        rowRect = [self rectOfRow:numberOfRows-1];
        rowRect.origin.y += rowHeight;
        coloredRow = !(numberOfRows % 2);        
    }

    //Draw the grid
    while(rowRect.origin.y < rect.origin.y + rect.size.height){
        [self _drawRowInRect:rowRect colored:coloredRow selected:NO];

        //Move to the next row
        coloredRow = !coloredRow;
        rowRect.origin.y += rowHeight;            
    }

    if([self drawsGrid]){
        [self _drawGridInClipRect:rect];
    }
}

//Draw alternating colors
- (void)drawRow:(int)row clipRect:(NSRect)rect
{
    [self _drawRowInRect:[self rectOfRow:row] colored:(!(row % 2) && ![self isRowSelected:row]) selected:(row == [self selectedRow])];

    [super drawRow:row clipRect:rect];
}

//Draw a row
- (void)_drawRowInRect:(NSRect)rect colored:(BOOL)colored selected:(BOOL)selected
{
    if(drawsAlternatingRows){ //Draw alternating rows in the outline view
        NSRect	segmentRect = rect;

        if(colored && !selected){
            segmentRect.origin.x = 0;
            segmentRect.size.width = [self frame].size.width;

            //Whipe any existing color
            [[NSColor clearColor] set];
            NSRectFill(segmentRect); //fillRect: doesn't work here... must behave differently w/ alpha

            //Draw our grid color
            [alternatingRowColor set];
            [NSBezierPath fillRect:segmentRect];
        }
    }
}

- (void)drawGridInClipRect:(NSRect)rect
{
    //We do our grid drawing later
}

- (void)_drawGridInClipRect:(NSRect)rect
{
    NSEnumerator	*enumerator;
    NSTableColumn	*column;
    float		xPos = 0.5;
    int			intercellWidth = [self intercellSpacing].width;
    
    [[self gridColor] set];
    [NSBezierPath setDefaultLineWidth:1.0];

    enumerator = [[self tableColumns] objectEnumerator];
    while((column = [enumerator nextObject])){
        xPos += [column width] + intercellWidth;

        [NSBezierPath strokeLineFromPoint:NSMakePoint(xPos, rect.origin.y)
                                  toPoint:NSMakePoint(xPos, rect.origin.y + rect.size.height)];
    }
}



@end

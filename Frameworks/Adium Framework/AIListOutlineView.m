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

#import "AIListOutlineView.h"
#import "AIListCell.h"

#define	CONTACT_LIST_EMPTY_MESSAGE      AILocalizedString(@"No Available Contacts","Message to display when the contact list is empty")
#define EMPTY_HEIGHT					48
#define EMPTY_WIDTH						140

@implementation AIListOutlineView

- (id)initWithFrame:(NSRect)frame
{
	[super initWithFrame:frame];
	
	updateShadowsWhileDrawing = NO;

	[self sizeLastColumnToFit];
	
	return(self);
}

- (void)dealloc
{
	[super dealloc];
}

//Prevent the display of a focus ring around the contact list in 10.3 and greater
- (NSFocusRingType)focusRingType
{
    return(NSFocusRingTypeNone);
}

//When our delegate is set, ask it for our data cells
- (void)setDelegate:(id)delegate
{
	[super setDelegate:delegate];
}

//Keep our column full width
- (void)setFrameSize:(NSSize)newSize
{
	[super setFrameSize:newSize];
	[self sizeLastColumnToFit];
}


//Selection Hiding -----------------------------------------------------------------------------------------------------
//If our window isn't in the foreground, we're not displaying a selection.  So override this method to pass NO for
//selected in that situation
- (void)_drawRowInRect:(NSRect)rect colored:(BOOL)colored selected:(BOOL)selected
{
	if(![[self window] isKeyWindow]) selected = NO;
	[super _drawRowInRect:rect colored:colored selected:selected];
}
	
//When our view is inserted into a window, observe that window so we can hide selection when it's not main
- (void)configureSelectionHidingForNewSuperview:(NSView *)newSuperview
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidBecomeMainNotification object:[self window]];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidResignMainNotification object:[self window]];
    if([newSuperview window]){
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowBecameMain:) name:NSWindowDidBecomeMainNotification object:[newSuperview window]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowResignedMain:) name:NSWindowDidResignMainNotification object:[newSuperview window]];
    }
}

//Redraw our cells so they can select or de-select
- (void)windowBecameMain:(NSNotification *)notification{
	[self setNeedsDisplay:YES];
}
- (void)windowResignedMain:(NSNotification *)notification{
	[self setNeedsDisplay:YES];
}


//Sizing -----------------------------------------------------------------------------------------------------
// Returns our desired size
- (int)desiredHeight
{
	int desiredHeight = [self totalHeight]+2;
	return(desiredHeight > EMPTY_HEIGHT ? desiredHeight : EMPTY_HEIGHT);
}

- (int)desiredWidth
{
	unsigned	row;
	unsigned	widestCell = 0;
	unsigned	numberOfRows = [self numberOfRows];
	id			theDelegate = [self delegate];
	
	//Enumerate all rows, find the widest one
	for(row = 0; row < numberOfRows; row++){
		id				item = [self itemAtRow:row];
		AIListCell		*cell = ([self isExpandable:item] ? groupCell : contentCell);
		
		[theDelegate outlineView:self willDisplayCell:cell forTableColumn:nil item:item];
		int	width = [cell cellWidth];
		if(width > widestCell) widestCell = width;
	}

	return(widestCell > EMPTY_WIDTH ? widestCell : EMPTY_WIDTH);
}



//Contact menu ---------------------------------------------------------------
//Return the selected object (to auto-configure the contact menu)
- (AIListObject *)listObject
{
    int selectedRow = [self selectedRow];

    if(selectedRow >= 0 && selectedRow < [self numberOfRows]){
        return([self itemAtRow:selectedRow]);
    }else{
        return(nil);
    }
}

- (NSArray *)arrayOfListObjects
{
	return([self arrayOfSelectedItems]);
}

//Parent window transparency -----------------------------------------------------------------
//This is a hack and a complete performance disaster, but required because of bugs with transparency in 10.3 :(
- (void)setUpdateShadowsWhileDrawing:(BOOL)update
{
	updateShadowsWhileDrawing = update;
}

//If we DO NOT subcalss drawRect, the system will not update our view correctly while resizing (10.3.3)
- (void)drawRect:(NSRect)rect
{
	[super drawRect:rect];
	if(updateShadowsWhileDrawing) [[self window] compatibleInvalidateShadow];
}

@end


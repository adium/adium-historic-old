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

#define	CONTACT_LIST_EMPTY_MESSAGE      AILocalizedString(@"No Available Contacts","Message to display when the contact list is empty")
#define TOOL_TIP_CHECK_INTERVAL			45.0	//Check for mouse X times a second
#define TOOL_TIP_DELAY					25.0	//Number of check intervals of no movement before a tip is displayed

@implementation AIListOutlineView

- (id)initWithFrame:(NSRect)frame
{
	[super initWithFrame:frame];
	
	backgroundImage = nil;
	backgroundFade = 1.0;
	updateShadowsWhileDrawing = NO;
	drawsBackground = YES;

	[self sizeLastColumnToFit];
	
	return(self);
}

- (void)dealloc
{
	[backgroundImage release];
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



//Frame and superview tracking -----------------------------------------------------------------------------------------
#pragma mark Frame and superview tracking
//We're going to move to a new superview
//- (void)viewWillMoveToSuperview:(NSView *)newSuperview
//{
//	[super viewWillMoveToSuperview:newSuperview];
//
//	//Stop tracking our scrollview's frame
//	if([self enclosingScrollView]){
//		[[NSNotificationCenter defaultCenter] removeObserver:self
//														name:NSViewFrameDidChangeNotification
//													  object:[self enclosingScrollView]];
//	}
//	
//	//Configure various things for the new superview
//	[self configureSelectionHidingForNewSuperview:newSuperview];
//	[self configureTooltipsForNewSuperview:newSuperview];
//}
//
////We've moved to a new superview
//- (void)viewDidMoveToSuperview
//{	
//	[super viewDidMoveToSuperview];
//	
//	//Start tracking our new scrollview's frame
//	if([self enclosingScrollView]){
//        [[NSNotificationCenter defaultCenter] addObserver:self
//												 selector:@selector(frameDidChange:)
//													 name:NSViewFrameDidChangeNotification 
//												   object:[self enclosingScrollView]];
//		[self performSelector:@selector(frameDidChange:) withObject:nil afterDelay:0.0001];
//	}
//}
//
////Our enclosing scrollview has changed size
//- (void)frameDidChange:(NSNotification *)notification
//{
//	[self configureTooltipsForNewScrollViewFrame];
//}


//Selection Hiding -----------------------------------------------------------------------------------------------------
#warning do this at the cell level so as not to lose actual selection
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

//Restore the selection
- (void)windowBecameMain:(NSNotification *)notification
{
	[self setNeedsDisplay:YES];
	NSLog(@"Unhide selection");
}

//Hide the selection
- (void)windowResignedMain:(NSNotification *)notification
{
	[self setNeedsDisplay:YES];
	NSLog(@"Hide selection");
}

    
//Auto Sizing --------------------------------------------------------------------------
//Updates the horizontal size of several objects, posting a desired size did change notification if necessary
//- (void)updateHorizontalSizeForObjects:(NSArray *)inObjects
//{
//	NSEnumerator	*enumerator = [inObjects objectEnumerator];
//	AIListObject	*object;
//	BOOL			changed = NO;
//	
//	while(object = [enumerator nextObject]){
//		if([self _performPartialRecalculationForObject:object]) changed = YES;
//	}
//	
//    if(changed){
//        [[NSNotificationCenter defaultCenter] postNotificationName:AIViewDesiredSizeDidChangeNotification object:self]; //Resize
//    }
//}
//
////Updates the horizontal size of an object, posting a desired size did change notification if necessary
//- (void)updateHorizontalSizeForObject:(AIListObject *)inObject
//{
//	if([self _performPartialRecalculationForObject:inObject]){
//        [[NSNotificationCenter defaultCenter] postNotificationName:AIViewDesiredSizeDidChangeNotification object:self]; //Resize
//	}
//}
//
////Recalulate an object's size and determine if we need to resize our view
//- (BOOL)_performPartialRecalculationForObject:(AIListObject *)inObject
//{
//    NSTableColumn	*column = [[self tableColumns] objectAtIndex:0];
//    AISCLCell 		*cell = [column dataCell];
//    float			cellWidth;
//    NSArray			*cellSizeArray;
//    BOOL			changed = NO;
//    int				j;
//
//	if([self rowForItem:inObject] == -1){ //We don't cache hidden objects
//		for(j=0; j < 3; j++){ //check left, middle, and right
//			if(hadMax[j] == inObject){ //if this object was the largest in terms of j before but is now hidden, then we need to search for the now-largest
//				[self _performFullRecalculationFor:j];
//				changed = YES;
//			}
//		}
//	}else{ //object is in the active contact list
//		[[self delegate] outlineView:self willDisplayCell:cell forTableColumn:column item:inObject];        
//		for(j=0 ; j < 3; j++){  //check left, middle, and right
//			cellSizeArray = [cell cellSizeArrayForBounds:NSMakeRect(0,0,0,[self rowHeight]) inView:self];
//			cellWidth = [[cellSizeArray objectAtIndex:j] floatValue];
//			if(cellWidth > desiredWidth[j]) {
//				desiredWidth[j] = cellWidth;
//				hadMax[j] = inObject;
//				changed = YES;
//			} else if ((hadMax[j] == inObject) && (cellWidth != desiredWidth[j]) ) {   //if this object was the largest in terms of j before but is not now, then we need to search for the now-largest
//				[self _performFullRecalculationFor:j];
//				changed = YES;
//			}
//		}   
//	}
//	
//	return(changed);
//}
//
//- (void)_performFullRecalculation
//{
//    int j;
//    for (j=0 ; j < 3 ; j++) {
//        [self _performFullRecalculationFor:j];
//    }
//    [[NSNotificationCenter defaultCenter] postNotificationName:AIViewDesiredSizeDidChangeNotification object:self];
//}
//
//- (void)_performFullRecalculationFor:(int)j
//{
//    NSTableColumn	*column = [[self tableColumns] objectAtIndex:0];
//    AISCLCell		*cell = [column dataCell];
//    AIListObject	*object;
//    float			cellWidth;
//    NSArray			*cellSizeArray;
//    int				i;
//    
//	desiredWidth[j]=0;
//	hadMax[j]=nil;
//    for(i = 0; i < [self numberOfRows]; i++){
//        object = [self itemAtRow:i];
//
//        [[self delegate] outlineView:self willDisplayCell:cell forTableColumn:column item:object];
//        
//        cellSizeArray = [cell cellSizeArrayForBounds:NSMakeRect(0,0,0,[self rowHeight]) inView:self];
//		
//        cellWidth = [[cellSizeArray objectAtIndex:j] floatValue];
//        if(cellWidth > desiredWidth[j]){
//            desiredWidth[j] = cellWidth;
//            hadMax[j] = object;
//        }
//    } 
//}
//

// Returns our desired size
#define EMPTY_HEIGHT				24
#define EMPTY_WIDTH					140
- (NSSize)desiredSize
{
	if([self numberOfRows] == 0){
		return(NSMakeSize(EMPTY_WIDTH, EMPTY_HEIGHT));
	}else{
		NSLog(@"totalHeight = %i",(int)[self totalHeight]);
		return(NSMakeSize(EMPTY_WIDTH, [self totalHeight] + 2));
	}
}

//    //We need to convert this to a lazy cache
//    
//    if([self numberOfRows] == 0){
//        return( NSMakeSize(EMPTY_WIDTH, EMPTY_HEIGHT) );
//    }else{
//        float	desiredHeight;
//        int     j;
//        float   totalWidth = 0;
//        
//        desiredHeight = [self numberOfRows] * ([self rowHeight] + [self intercellSpacing].height);
//         for (j = 0; j < 3; j++) {
//             totalWidth += desiredWidth[j]; 
//         }
//         
//         totalWidth += [self intercellSpacing].width + 3; //+3 is to account for variable-width letters.  stupid things.
//         
//         if(totalWidth < DESIRED_MIN_WIDTH) totalWidth = DESIRED_MIN_WIDTH;
//         if(desiredHeight < DESIRED_MIN_HEIGHT) desiredHeight = DESIRED_MIN_HEIGHT;
//         
//         return( NSMakeSize(totalWidth, desiredHeight) );
//    }
//}


//- (void)outlineViewItemDidExpand:(NSNotification *)notification
//{
//    [[NSNotificationCenter defaultCenter] postNotificationName:AIViewDesiredSizeDidChangeNotification
//														object:contactListView];
//}
//
//- (void)outlineViewItemDidCollapse:(NSNotification *)notification
//{
//    [[NSNotificationCenter defaultCenter] postNotificationName:AIViewDesiredSizeDidChangeNotification
//														object:contactListView];
//}
	

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



#warning still need this?
//Our default drag image will be cropped incorrectly, so we need a custom one here
//- (NSImage *)dragImageForRows:(NSArray *)dragRows event:(NSEvent *)dragEvent dragImageOffset:(NSPointPointer)dragImageOffset
//{
//	NSRect			rowRect, cellRect;
//	int				count = [dragRows count];
//	
//	int				firstRow = [[dragRows objectAtIndex:0] intValue];
//	NSTableColumn	*column = [[self tableColumns] objectAtIndex:0];
//	NSCell			*cell;
//	NSImage			*image;
//	
//	//Since our cells draw outside their bounds, this drag image code will create a drag image as big as the table row
//	//and then draw the cell into it at the regular size.  This way the cell can overflow its bounds as normal and not
//	//spill outside the drag image.
//	rowRect = [self rectOfRow:firstRow];
//	image = [[NSImage alloc] initWithSize:NSMakeSize(rowRect.size.width,
//													 rowRect.size.height*count + [self intercellSpacing].height*(count-1))];
//
//	
//NSEnumerator	*enumerator = [dragRows objectEnumerator];
//NSNumber		*rowNumber;
//int				row;
//float			yOffset = 0;
//
//	//Draw (Since the OLV is normally flipped, we have to be flipped when drawing)
//	[image setFlipped:YES];
//	[image lockFocus];
//
//	while (rowNumber = [enumerator nextObject]){
//		row = [rowNumber intValue];
//		cell = [column dataCellForRow:row];
//		cellRect = [self frameOfCellAtColumn:0 row:row];
//		
//		//Render the cell
//		[[self dataSource] outlineView:self willDisplayCell:cell forTableColumn:column item:[self itemAtRow:row]];
////		NSLog(@"%i is %f %f %f = %f",row,cellRect.origin.y,rowRect.origin.y,yOffset,cellRect.origin.y - rowRect.origin.y + yOffset);
//		[cell drawWithFrame:NSMakeRect(cellRect.origin.x - rowRect.origin.x, /*cellRect.origin.y - rowRect.origin.y +*/ yOffset,cellRect.size.width,cellRect.size.height)
//					 inView:self];
//		yOffset += (rowRect.size.height + [self intercellSpacing].height);
//	}
//	
//	[image unlockFocus];
//	[image setFlipped:NO];
//	
//	//Offset the drag image (Remember: The system centers it by default, so this is an offset from center)
//	NSPoint clickLocation = [self convertPoint:[dragEvent locationInWindow] fromView:nil];
//	dragImageOffset->x = (rowRect.size.width / 2.0) - clickLocation.x;
//	
//	return([image autorelease]);
//}

	
	
	
	//We do custom highlight management when putting the label around the contact only
	- (void)highlightSelectionInClipRect:(NSRect)clipRect
	{
#warning 10.3 only
		if([[self window] isMainWindow]){
			NSIndexSet *indices = [self selectedRowIndexes];
			unsigned int bufSize = [indices count];
			unsigned int *buf = malloc(bufSize * sizeof(unsigned int));
			unsigned int i;
			NSRange range = NSMakeRange([indices firstIndex], ([indices lastIndex]-[indices firstIndex]) + 1);
			[indices getIndexes:buf maxCount:bufSize inIndexRange:&range];
			
			for(i = 0; i < bufSize; i++) {
				unsigned int startIndex = buf[i];
				unsigned int endIndex = startIndex;
				
				//Process the selected rows in clumps
#warning merging
				while(i < bufSize-1 && buf[i+1] == endIndex + 1){
					i++;
					endIndex++;
				}
				
				NSLog(@"select from %i to %i",startIndex,endIndex);
				
				NSRect selectRect;
				if(startIndex == endIndex){
					selectRect = [self rectOfRow:startIndex];
				}else{
					selectRect = NSUnionRect([self rectOfRow:startIndex],[self rectOfRow:endIndex]);
				}
				
				//Draw the gradient
				AIGradient *gradient = [AIGradient selectedControlGradientWithDirection:AIVertical];
				[gradient drawInRect:selectRect];
				
				//Draw a line at the light side, to make it look a lot cleaner
				selectRect.size.height = 1;
				[[NSColor alternateSelectedControlColor] set];
				NSRectFillUsingOperation(selectRect, NSCompositeSourceOver);
				
				
				//
			}
			
			free(buf);
		}
		
	}
	
	
	
		
		
//		
//		
//		
//		
//		
//		NSIndexSet	*indexSet = [self selectedRowIndexes];
//		
//		- (NSIndexSet *)selectedRowIndexes;
//
//		
//		
//		
//		NSLog(@"%i x %i",(int)clipRect.size.width,(int)clipRect.size.height);
//		
//		
//		
		
		
		
		
		//		NSLog(@"highlightSelectionInClipRect");
////		if (!labelAroundContactOnly) {
//			[super highlightSelectionInClipRect:clipRect];
//		}
		
	
	
	
	
	
	
	
	

//Background -----------------------------------------------------------------
//
- (void)setBackgroundImage:(NSImage *)inImage
{
	[backgroundImage release]; backgroundImage = nil;
	
	backgroundImage = [inImage retain];
	[backgroundImage setFlipped:YES];
	
	[[self superview] setCopiesOnScroll:(!backgroundImage)];
	[self setNeedsDisplay:YES];
}

- (void)setDrawsBackground:(BOOL)inDraw
{
	drawsBackground = inDraw;
}

- (void)setBackgroundFade:(float)fade
{
	backgroundFade = fade;
}

- (void)setBackgroundColor:(NSColor *)inColor
{
	[backgroundColor release];
	backgroundColor = [inColor retain];
}

- (NSColor *)backgroundColor
{
	return(backgroundColor);
}

- (void)viewWillMoveToSuperview:(NSView *)newSuperview
{
	[super viewWillMoveToSuperview:newSuperview];
	[(NSClipView *)newSuperview setCopiesOnScroll:(!backgroundImage)];
}

//
- (void)drawBackgroundInClipRect:(NSRect)clipRect
{
	NSRect visRect = [[self enclosingScrollView] documentVisibleRect];

#warning --
	[super drawBackgroundInClipRect:clipRect];
	
	if(drawsBackground){
		//BG Color
		[backgroundColor set];
		NSRectFill(clipRect);
		
		//Image
		if(backgroundImage){
			NSSize	imageSize = [backgroundImage size];
			
			[backgroundImage drawInRect:NSMakeRect(visRect.origin.x, visRect.origin.y, imageSize.width, imageSize.height)
							   fromRect:NSMakeRect(0, 0, imageSize.width, imageSize.height)
							  operation:NSCompositeSourceOver
							   fraction:backgroundFade];
		}	
	}else{
		[[NSColor clearColor] set];
		NSRectFill(clipRect);
	}
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


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

#import <Adium/Adium.h>
#import "AISCLOutlineView.h"
#import "AISCLCell.h"
#import "AIContactListCheckBox.h"
#import "AIAdium.h"
#import "AISCLViewPlugin.h"
#import "AISCLViewController.h"

#define	CONTACT_LIST_EMPTY_MESSAGE		@"No Available Contacts"		//Message to display when the contact list is empty
#define DESIRED_MIN_WIDTH	40
#define DESIRED_MIN_HEIGHT	20
#define EMPTY_HEIGHT		-2
#define EMPTY_WIDTH		140

@interface AISCLOutlineView (PRIVATE)
- (void)configureView;
- (void)configureTransparency;
- (void)configureTransparencyForWindow:(NSWindow *)inWindow;
@end

@implementation AISCLOutlineView

- (id)init
{
    NSTableColumn	*tableColumn;

    [super init];

    showLabels = YES;
    font = nil;
    groupFont = nil;
    color = nil;
    invertedColor = nil;
    groupColor = nil;
    invertedGroupColor = nil;
        
    //Set up the table view
    tableColumn = [[[NSTableColumn alloc] init] autorelease];
    [tableColumn setDataCell:[[[AISCLCell alloc] init] autorelease]];
    [tableColumn setEditable:NO];
    [tableColumn setResizable:NO];
    [self setDrawsGrid:NO];
    [self addTableColumn:tableColumn];
    [self setAutoresizesAllColumnsToFit:NO]; //System needs to leave this alone, I handle it manually
    [self setOutlineTableColumn:tableColumn];
    [self setHeaderView:nil];
    [self setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
    [self setIndentationPerLevel:10];
    
    return(self);
}

- (void)dealloc
{
    //Stop observing frame changes!
    if([self window]){
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidBecomeMainNotification object:[self window]];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidResignMainNotification object:[self window]];
    }
    
    //Cleanup
    [font release];
    [color release];
    [invertedColor release];
    [groupColor release];
    [invertedGroupColor release];
    [super dealloc];
}

//Called before we're inserted in a window
- (void)viewWillMoveToSuperview:(NSView *)newSuperview
{
    //Observe our window becoming and resigning main
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidBecomeMainNotification object:[self window]];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidResignMainNotification object:[self window]];
    if([newSuperview window]){
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowBecameMain:) name:NSWindowDidBecomeMainNotification object:[newSuperview window]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowResignedMain:) name:NSWindowDidResignMainNotification object:[newSuperview window]];
    }

    //Turn on transparency for our destination window (if necessary)
    [self configureTransparencyForWindow:[newSuperview window]];
}

- (void)viewDidMoveToSuperview
{
    [super viewDidMoveToSuperview];

    //Inform our delegate that we moved to another superview
    if([[self delegate] respondsToSelector:@selector(view:didMoveToSuperview:)]){
        [[self delegate] view:self didMoveToSuperview:[self superview]];
    }
}

//Override set frame size to force our rect to always be the correct height.  Without this the scrollview will stretch too tall vertically when resized beyond the bottom of our contact list.
- (void)setFrame:(NSRect)frameRect
{
    frameRect.size.height = [self numberOfRows] * ([self rowHeight] + [self intercellSpacing].height);
    [super setFrame:frameRect];

    NSTableColumn	*column = [[self tableColumns] objectAtIndex:0];
    [column setResizable:YES];
    [self sizeLastColumnToFit]; //Keep the table column at full width
    [column setResizable:NO];
}


// Selection Hiding --------------------------------------------------------------------
//Restore the selection
- (void)windowBecameMain:(NSNotification *)notification
{
    if(lastSelectedRow >= 0 && lastSelectedRow < [self numberOfRows] && [self selectedRow] == -1){
        [self selectRow:lastSelectedRow byExtendingSelection:NO];
    }
}

//Hide the selection
- (void)windowResignedMain:(NSNotification *)notification
{
    lastSelectedRow = [self selectedRow];
    [self deselectAll:nil];
}


// Context menu ------------------------------------------------------------------------
- (NSMenu *)menuForEvent:(NSEvent *)theEvent
{
    //Pass this on to our delegate
    if([[self delegate] respondsToSelector:@selector(outlineView:menuForEvent:)]){
        return([[self delegate] outlineView:self menuForEvent:theEvent]);
    }else{
        return(nil);
    }
}

    
// Transparency ------------------------------------------------------------------------
- (void)configureTransparencyForWindow:(NSWindow *)inWindow
{
    float	backgroundAlpha;

    //This is handled automatically by AISCLViewPlugin when the transparency preference is altered - but the first time preferences are applied our view is not yet installed.  The solution is to re-set the window transparency here, as our view is being inserted into the window.
    //Needed for proper transparency... but not the cleanest way.
    backgroundAlpha = [[[self backgroundColor] colorUsingColorSpaceName:NSDeviceRGBColorSpace] alphaComponent];
    [inWindow setAlphaValue:(backgroundAlpha == 100.0 ? 1.0 : 0.9999999)];
}


// Auto Sizing --------------------------------------------------------------------------
// Returns our desired size
- (NSSize)desiredSize
{
    if([self numberOfRows] == 0){
        return( NSMakeSize(EMPTY_WIDTH, EMPTY_HEIGHT) );

    }else{
        int	desiredHeight;//, desiredWidth;

        desiredHeight = [self numberOfRows] * ([self rowHeight] + [self intercellSpacing].height);

        int i;
        int desiredWidth = 50;

        for(i = 0; i < [self numberOfRows]; i++){
            NSTableColumn	*column = [[self tableColumns] objectAtIndex:0];
            AISCLCell 		*cell = [column dataCell];
            NSSize		cellSize;

            [[self delegate] outlineView:self willDisplayCell:cell forTableColumn:column item:[self itemAtRow:i]];

            cellSize = [cell cellSizeForBounds:NSMakeRect(0,0,0,[self rowHeight]) inView:self];
            cellSize.width += [self intercellSpacing].width;
            //cellSize.width += [self levelForRow:i] * [self indentationPerLevel];

            if(cellSize.width > desiredWidth){
                desiredWidth = cellSize.width;
            }
        }

        if(desiredWidth < DESIRED_MIN_WIDTH) desiredWidth = DESIRED_MIN_WIDTH;
        if(desiredHeight < DESIRED_MIN_HEIGHT) desiredHeight = DESIRED_MIN_HEIGHT;

        return( NSMakeSize(desiredWidth, desiredHeight) );
    }
}


// Keyboard Navigation ------------------------------------------------------------------
// Navigate the contact list with the keyboard
- (void)keyDown:(NSEvent *)theEvent
{
    if(!([theEvent modifierFlags] & NSCommandKeyMask)){
        if([theEvent keyCode] == 36){ //Enter or return
            [(AISCLViewController *)[self delegate] performDefaultActionOnSelectedContact:self];

        }else if([theEvent keyCode] == 123){ //left
            AIListObject 	*object = [self itemAtRow:[self selectedRow]];
            
            if(object != nil){
                if([object isKindOfClass:[AIListGroup class]]){
                    //Collapse
                    if([self isItemExpanded:object]){
                        [self collapseItem:object];
                    }
                } 	
            }

        }else if([theEvent keyCode] == 124){ //right
            AIListObject 	*object = [self itemAtRow:[self selectedRow]];
            
            if(object != nil){
                if([object isKindOfClass:[AIListGroup class]]){
                    //Expand
                    if(![self isItemExpanded:object]){
                        [self expandItem:object];
                    }
                } 	   
            }

        }else{
            [super keyDown:theEvent]; //pass it on
        }
    }else{
        [super keyDown:theEvent]; //pass it on
    }
}    


//Contact menu ---------------------------------------------------------------
//Return the selected countact (to auto-configure the contact menu)
- (AIListContact *)contact
{
    int selectedRow = [self selectedRow];

    if(selectedRow >= 0 && selectedRow < [self numberOfRows]){
        return([self itemAtRow:selectedRow]);
    }else{
        return(nil);
    }
}


//Custom font settings ------------------------------------------------------------------
//We have to handle setting our font manually.  Outline view responds to set font, but it does nothing.
- (void)setFont:(NSFont *)inFont{
    if(font != inFont){
        [font release];
        font = [inFont retain];
    }
}
- (NSFont *)font{
    return(font);
}

- (void)setGroupFont:(NSFont *)inFont{
    if(groupFont != inFont){
        [groupFont release];
        groupFont = [inFont retain];
    }
}
- (NSFont *)groupFont{
    return(groupFont);
}

//Custom color settings -----------------------------------------------------------------
//Contact color
- (void)setColor:(NSColor *)inColor
{    
    if(color != inColor){
        [color release];
        color = [inColor retain];
        [invertedColor release];
        invertedColor = [[inColor colorWithInvertedLuminance] retain];
    }
}
- (NSColor *)color{
    return(color);
}
- (NSColor *)invertedColor{
    return(invertedColor);
}

//Group color
- (void)setGroupColor:(NSColor *)inColor
{
    if(groupColor != inColor){
        [groupColor release];
        groupColor = [inColor retain];
        [invertedGroupColor release];
        invertedGroupColor = [[inColor colorWithInvertedLuminance] retain];
    }
}
- (NSColor *)groupColor{
    return(groupColor);
}
- (NSColor *)invertedGroupColor{
    return(invertedGroupColor);
}

- (void)setShowLabels:(BOOL)inValue{
    showLabels = inValue;
}
- (BOOL)showLabels{
    return(showLabels);
}


//No available contacts -----------------------------------------------------------------
//Draw a custom 'no available contacts' message when the list is empty
/*- (void)drawRect:(NSRect)rect
{
    int		rowHeight = [self rowHeight] + [self intercellSpacing].height;
    int		numberOfRows = [self numberOfRows];

    [super drawRect:rect];

    if(numberOfRows == 0){
        NSDictionary		*attributes;
        NSAttributedString	*emptyMessage;
        int			position;

        //Create the empty message
        //attributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont systemFontOfSize:11],NSFontAttributeName,nil];
        attributes = [NSDictionary dictionaryWithObjectsAndKeys:[self color],NSForegroundColorAttributeName,[self font],NSFontAttributeName,nil];
        emptyMessage = [[NSAttributedString alloc] initWithString:CONTACT_LIST_EMPTY_MESSAGE attributes:attributes];

        //Center it
        position = (rect.size.width - [emptyMessage size].width) / 2.0;
        [emptyMessage drawInRect:NSMakeRect(position, 2, position + rect.size.width, rowHeight)];

        [emptyMessage release];
    }
}*/



//Custom mouse tracking ----------------------------------------------------------------------
- (void)mouseMoved:(NSEvent *)theEvent
{
    [[self delegate] mouseMoved:theEvent];
}

@end

/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2002, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

#define	CONTACT_LIST_EMPTY_MESSAGE		@"No Available Contacts"		//Message to display when the contact list is empty

@interface AISCLOutlineView (PRIVATE)
- (void)configureView;
@end

@implementation AISCLOutlineView

- (id)init
{
    NSTableColumn	*tableColumn;
    NSFont *font = [NSFont systemFontOfSize:11];

    [super init];

    //Set up the table view
    tableColumn = [[[NSTableColumn alloc] init] autorelease];
    [tableColumn setDataCell:[[[AISCLCell alloc] init] autorelease]];
    [tableColumn setEditable:NO];
    [self addTableColumn:tableColumn];
    [self setAutoresizesAllColumnsToFit:YES];
    [self setOutlineTableColumn:tableColumn];
    [self setHeaderView:nil];
    [self setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];

    //Appearance
    [super setFont:font];
    [self setRowHeight:[font defaultLineHeightForFont]];
    [self setIndentationPerLevel:10];

    [self setBackgroundColor:[NSColor colorWithCalibratedRed:(250.0/255.0) green:(250.0/255.0) blue:(250.0/255.0) alpha:1.0]];
    [self setDrawsAlternatingRows:YES];
    [self setAlternatingRowColor:[NSColor colorWithCalibratedRed:(237.0/255.0) green:(237.0/255.0) blue:(240.0/255.0) alpha:1.0]];
    [self setDrawsAlternatingColumns:NO];

    return(self);
}

//Called before we're inserted in a window
- (void)viewWillMoveToSuperview:(NSView *)newSuperview
{
    //Remove the old observer
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewFrameDidChangeNotification object:[self enclosingScrollView]];
    
    //Install our scroll view frame changed notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(frameChanged:) name:NSViewFrameDidChangeNotification object:[newSuperview enclosingScrollView]];
}

// Hide the selection when the cursor isn't over the contact list
/*- (void)mouseEntered:(NSEvent *)theEvent
{
    [self selectRow:oldSelection byExtendingSelection:NO];
}
- (void)mouseExited:(NSEvent *)theEvent
{
    oldSelection = [self selectedRow];
    [self deselectAll:nil];
}*/

// Navigate the contact list with the keyboard
- (void)keyDown:(NSEvent *)theEvent
{
    if(!([theEvent modifierFlags] & NSCommandKeyMask)){
        if([theEvent keyCode] == 36){ //Enter or return
            [(AISCLViewPlugin *)[self delegate] performDefaultActionOnSelectedContact:nil];

        }else if([theEvent keyCode] == 123){ //left
            AIContactObject 	*object = [self itemAtRow:[self selectedRow]];
            
            if(object != nil){
                if([object isKindOfClass:[AIContactGroup class]]){
                    //Collapse
                    if([self isItemExpanded:object]){
                        [self collapseItem:object];
                    }
                } 	
            }

        }else if([theEvent keyCode] == 124){ //right
            AIContactObject 	*object = [self itemAtRow:[self selectedRow]];
            
            if(object != nil){
                if([object isKindOfClass:[AIContactGroup class]]){
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

//Override set frame size to force our rect to always be the correct height.  Without this the scrollview will stretch too tall vertically when resized beyond the bottom of our contact list.
- (void)setFrame:(NSRect)frameRect
{
    frameRect.size.height = [self numberOfRows] * ([self rowHeight] + [self intercellSpacing].height);
    [super setFrame:frameRect];
}
    
//Automatically hide/show the scrollbar
- (void)frameChanged:(NSNotification *)notification
{
    int 		visibleHeight;
    int 		totalHeight;
    NSScrollView	*scrollView = [self enclosingScrollView]; 

    //Hide or show scrollbar
    visibleHeight = [scrollView documentVisibleRect].size.height;
    totalHeight = [self numberOfRows] * ([self rowHeight] + [self intercellSpacing].height);
    if(totalHeight > visibleHeight){
        [scrollView setHasVerticalScroller:YES];
    }else{
        [scrollView setHasVerticalScroller:NO];
    }

    //Keep the table column at full width
    [self sizeLastColumnToFit];
    

    //Update tracking rect
/*    if(trackingRectTag != 0){
        [self removeTrackingRect:trackingRectTag];
    }
    
    trackingRectTag = [self addTrackingRect:[scrollView bounds] owner:self userData:nil assumeInside:NO];*/
}

- (void)setFont:(NSFont *)inFont
{
	[super setFont:inFont];
	NSLog(@"font is: %@ and should be %@", [[self font] fontName], inFont);
}

//Draw a custom 'no available contacts' message when the list is empty
- (void)drawRect:(NSRect)rect
{
    int		rowHeight = [self rowHeight] + [self intercellSpacing].height;
    int		numberOfRows = [self numberOfRows];

    [super drawRect:rect];

    if(numberOfRows == 0)
	{
        NSDictionary		*attributes;
        NSAttributedString	*emptyMessage;
        int			position;

        //Create the empty message
        attributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont systemFontOfSize:11],NSFontAttributeName,nil];
        emptyMessage = [[NSAttributedString alloc] initWithString:CONTACT_LIST_EMPTY_MESSAGE attributes:attributes];

        //Center it
        position = (rect.size.width - [emptyMessage size].width) / 2.0;
        [emptyMessage drawInRect:NSMakeRect(position, 2, position + rect.size.width, rowHeight)];
    
        [emptyMessage release];
    }
}

@end


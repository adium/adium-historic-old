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

#import <AIUtilities/AIUtilities.h>
#import <Adium/Adium.h>
#import "AIAdium.h"
#import "AISMTextView.h"
#import "AISMVMessageCell.h"
#import "AISMVSenderCell.h"

#define AUTOSCROLL_CATCH_SIZE 	20	//The distance (in pixels) that the scrollview must be within (from the bottom) for auto-scroll to kick in.

@interface AISMTextView (PRIVATE)
- (id)initForHandle:(AIContactHandle *)inHandle owner:(id)inOwner;
- (BOOL)isFlipped;
- (void)frameChanged:(NSNotification *)notification;
- (void)viewDidEndLiveResize;
- (void)viewDidMoveToSuperview;
- (void)viewWillMoveToSuperview:(NSView *)newSuperview;
- (void)buildMessageCellArray;
- (void)addCellsForContactObject:(NSObject<AIContentObject> *)object;
- (void)resizeCells;
- (void)resizeToFillContainerView;
@end

@implementation AISMTextView

//Create message text view
+ (id)messageTextViewForHandle:(AIContactHandle *)inHandle owner:(id)inOwner
{
    return([[[self alloc] initForHandle:inHandle owner:inOwner] autorelease]);
}

//Draw a rect of this view
- (void)drawRect:(NSRect)rect
{
    NSEnumerator		*cellEnumerator, *contentEnumerator;
    AISMVMessageCell		*textCell;
    AIContentMessage		*contentObject;
    NSRect			cellFrame = NSMakeRect(0, 0, [self frame].size.width, 0);
    NSRect			documentVisibleRect = [[self enclosingScrollView] documentVisibleRect];
    id				previousSource = nil;
    id				source;
    
    //If there isn't enough content to fill our entire view, we draw a section of blankness, and move down, so the content is bottom-aligned
    if(contentsHeight < documentVisibleRect.size.height){
        int	gapSize = documentVisibleRect.size.height - contentsHeight;

        //Move down so we're bottom aligned
        cellFrame.origin.y += gapSize;        
    }

    //Set up the bezier paths
    [NSBezierPath setDefaultLineWidth:1.0];
    [NSBezierPath setDefaultLineCapStyle:NSButtLineCapStyle];

    //Loop through, and draw, each cell
    cellEnumerator = [messageCellArray objectEnumerator];
    contentEnumerator = [contentArray objectEnumerator];
    while((textCell = [cellEnumerator nextObject])){
        contentObject = [contentEnumerator nextObject];

        source = [contentObject source];

        cellFrame.size.height = [textCell cellSize].height;
        if(NSIntersectsRect(documentVisibleRect,cellFrame)){
            NSRect	subFrame;
            
            //Draw the text cell
            subFrame = cellFrame;
            subFrame.size.width -= maxSenderWidth;
            subFrame.origin.x += maxSenderWidth;
            [textCell drawWithFrame:subFrame inView:self];
        
            //Draw the divider line and sender string
            // (we offset 0.5 pixels to achieve a simple 1 pixel aliased line)
            
            if(source != previousSource){ 
                int		senderCellIndex;

                //Draw the sender cell
                senderCellIndex = [senderArray indexOfObject:source];
                if(senderCellIndex != NSNotFound){
                    AISMVSenderCell	*senderCell = [senderCellArray objectAtIndex:senderCellIndex];

                    subFrame = cellFrame;
                    subFrame.size.width = maxSenderWidth;
                    subFrame.origin.x = 0;
                    [senderCell drawWithFrame:subFrame showName:YES inView:self];
                }

                //Left portion of the line
                [lineColorDivider set];
                [lineColorDarkDivider set];
                [NSBezierPath strokeLineFromPoint:NSMakePoint(cellFrame.origin.x, cellFrame.origin.y + 0.5) toPoint:NSMakePoint(cellFrame.origin.x + cellFrame.size.width, cellFrame.origin.y + 0.5)]; 
                
                //Right portion of the line
                [lineColorDivider set];
                [NSBezierPath strokeLineFromPoint:NSMakePoint(cellFrame.origin.x, cellFrame.origin.y + 0.5) toPoint:NSMakePoint(cellFrame.origin.x + cellFrame.size.width, cellFrame.origin.y + 0.5)]; 

            }else{
                int		senderCellIndex;

                //Draw an empty sender cell
                senderCellIndex = [senderArray indexOfObject:source];
                if(senderCellIndex != NSNotFound){
                    AISMVSenderCell	*senderCell = [senderCellArray objectAtIndex:senderCellIndex];

                    subFrame = cellFrame;
                    subFrame.size.width = maxSenderWidth;
                    subFrame.origin.x = 0;
                    [senderCell drawWithFrame:subFrame showName:NO inView:self];
                }
            }
        }

        //Next..
        cellFrame.origin.y += cellFrame.size.height;
        previousSource = source;
    }
}

//Called after a new message object is added
- (void)contentObjectAdded:(NSNotification *)notification
{
    id <AIContentObject>	newObject = [[notification userInfo] objectForKey:@"Object"];

    //Add the content
    [self addCellsForContactObject:newObject];

    //Resize and redisplay
    [self resizeToFillContainerView];
    [self setNeedsDisplay:YES];
}

//Private ---------------------------------------------------------------------------
//init
- (id)initForHandle:(AIContactHandle *)inHandle owner:(id)inOwner
{
    [super init];

    //init
    owner = [inOwner retain];
    handle = [inHandle retain];
    messageCellArray = [[NSMutableArray alloc] init];
    contentArray = [[NSMutableArray alloc] init];
    senderArray = [[NSMutableArray alloc] init];
    senderCellArray = [[NSMutableArray alloc] init];
    contentsHeight = 0;
    maxSenderWidth = 0;

    [self setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];

    //Register for notifications
    [[[owner contentController] contentNotificationCenter] addObserver:self selector:@selector(contentObjectAdded:) name:Content_ContentObjectAdded object:handle];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(frameChanged:) name:NSViewFrameDidChangeNotification object:self];

    //prefetch our colors
    backColorIn = [[[[owner preferenceController] preferenceForKey:@"message_incoming_backgroundColor" group:PREF_GROUP_GENERAL object:handle] representedColor] retain];
    backColorOut = [[[[owner preferenceController] preferenceForKey:@"message_outgoing_backgroundColor" group:PREF_GROUP_GENERAL object:handle] representedColor] retain];
    outgoingSourceColor = [[[[owner preferenceController] preferenceForKey:@"message_outgoing_sourceColor" group:PREF_GROUP_GENERAL object:handle] representedColor] retain];
    incomingSourceColor = [[[[owner preferenceController] preferenceForKey:@"message_incoming_sourceColor" group:PREF_GROUP_GENERAL object:handle] representedColor] retain];

lineColorDivider = [[backColorIn darkenBy:0.1] retain];
lineColorDarkDivider = [[backColorIn darkenBy:0.2] retain];

    [self buildMessageCellArray];

    return(self);
}

- (void)dealloc
{
    [[[owner contentController] contentNotificationCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
 
    [owner release];
    [handle release];
    [backColorIn release];
    [backColorOut release];
    [outgoingSourceColor release];
    [incomingSourceColor release];
    [lineColorDivider release];
    [lineColorDarkDivider release];
    [messageCellArray release];
    [contentArray release];
    [senderArray release];
    [senderCellArray release];

    [super dealloc];
}

//Return yes so our view's origin is in the top left
- (BOOL)isFlipped{
    return(YES);
}


//Called after we're inserted in a window
/*- (void)viewDidMoveToSuperview
{
    //Recalculate the cell dimensions and redisplay
    [self resizeToFillContainerView];
    [self resizeCells];
    [self setNeedsDisplay:YES];
}*/

//Called before we're inserted in a window
/*- (void)viewWillMoveToSuperview:(NSView *)newSuperview
{
    //force a cell resize
    
}*/

//Called when the frame changes.  Adjust to fill the new frame
- (void)frameChanged:(NSNotification *)notification
{    
    //Resize and redisplay
    [self resizeCells]; //live resize the contents
    [self resizeToFillContainerView];
    [self setNeedsDisplay:YES];
}

//Called after the view is resized.  Re-calculate the cell dimensions
/*- (void)viewDidEndLiveResize
{
    //Recalculate the cell dimensions and redisplay
    [self resizeToFillContainerView];
    [self resizeCells];
    [self setNeedsDisplay:YES];
}*/

//Flush and completely rebuild the message cell array
- (void)buildMessageCellArray
{
    NSEnumerator		*enumerator = [[handle contentObjectArray] reverseObjectEnumerator];
    id <AIContentObject> 	object;

    //Flush and reset
    [messageCellArray release]; messageCellArray = [[NSMutableArray alloc] init];
    [contentArray release]; contentArray = [[NSMutableArray alloc] init];
    maxSenderWidth = 0;
    contentsHeight = 0;

    //Build the cells
    while((object = [enumerator nextObject])){
        [self addCellsForContactObject:object];
    }

}

//Add a cell
- (void)addCellsForContactObject:(NSObject<AIContentObject> *)object
{
    AISMVMessageCell	*messageCell;
    float		width;// = [self frame].size.width - maxSenderWidth;
    
    if([[object type] compare:CONTENT_MESSAGE_TYPE] == 0){ //Message content
        NSMutableParagraphStyle	*paragraphStyle = [[[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
        AIContentMessage	*contentMessage = (AIContentMessage *)object;
        id			messageSource = [contentMessage source];
        float			height;

        //Create a sender cell (if one doesn't already exist)
        if([senderArray indexOfObject:messageSource] == NSNotFound){
            AISMVSenderCell	*senderCell;
            NSDictionary	*attributes;
            NSAttributedString	*attributedName;
            NSString		*senderName;
            NSColor		*backgroundColor;
            NSColor		*textColor;

            if([messageSource isKindOfClass:[AIAccount class]]){
                senderName = [NSString stringWithFormat:@"%@:",[(AIAccount *)messageSource accountDescription]];
                backgroundColor = backColorOut;
                textColor = outgoingSourceColor;

            }else{
                senderName = [NSString stringWithFormat:@"%@:",[(AIContactHandle *)messageSource displayName]];
                backgroundColor = backColorIn;
                textColor = incomingSourceColor;

            }
            
            //Create the cell
            [paragraphStyle setAlignment:NSRightTextAlignment];
            attributes = [NSDictionary dictionaryWithObjectsAndKeys:textColor,NSForegroundColorAttributeName,[NSFont systemFontOfSize:11],NSFontAttributeName,paragraphStyle,NSParagraphStyleAttributeName,nil];
            attributedName = [[[NSAttributedString alloc] initWithString:senderName attributes:attributes] autorelease];
            senderCell = [AISMVSenderCell senderCellWithString:attributedName];
            [senderCell setBackgroundColor:backgroundColor];

            //Cache it
            [senderArray addObject:messageSource];
            [senderCellArray addObject:senderCell];
            
            if([senderCell cellSize].width > maxSenderWidth){
                maxSenderWidth = [senderCell cellSize].width;
                [self resizeCells]; //resize our cells so they adjust to the new sender width
            }
        }
        
//if([
//left line = 194
//Dark name zone = 208
//light name zone = 234
//vertical divider = 207

        //track it in our content array
        [contentArray addObject:object];

        //Create a message cell
        messageCell = [AISMVMessageCell messageCellWithString:[contentMessage message]];
        width = [self frame].size.width - maxSenderWidth;
        height = [messageCell sizeCellForWidth:width].height;
        if([messageSource isKindOfClass:[AIAccount class]]){
            [messageCell setBackgroundColor:backColorOut];
        }else{
            [messageCell setBackgroundColor:backColorIn];
        }


        [messageCellArray addObject:messageCell];
        contentsHeight += height;


    }else{ //Unknown content
        [[owner contentController] invokeDefaultHandlerForObject:object];
    }
}

//Recalculate the cell dimensions
- (void)resizeCells
{
    NSScrollView		*enclosingScrollView;
    NSEnumerator		*enumerator;
    AISMVMessageCell		*cell;
    float			width;

    //Determine our width
    enclosingScrollView = [self enclosingScrollView];
    width = [enclosingScrollView documentVisibleRect].size.width - maxSenderWidth;

    //Resize our cells
    contentsHeight = 0;
    enumerator = [messageCellArray objectEnumerator];
    while((cell = [enumerator nextObject])){
        contentsHeight += [cell sizeCellForWidth:width].height;
    }
}

//Recalculate our dimensions, resizing our view to fill the entire space
- (void)resizeToFillContainerView
{
    NSScrollView		*enclosingScrollView;
    NSRect			documentVisibleRect;
    BOOL			autoScroll;
    NSSize			size;

    //Before resizing the view, we decide if the user is close to the bottom of our view.  If they are, we want to keep them at the bottom no matter what happens during the resize.
    enclosingScrollView = [self enclosingScrollView];
    documentVisibleRect = [enclosingScrollView documentVisibleRect];
    autoScroll = ((documentVisibleRect.origin.y + documentVisibleRect.size.height) > ([self frame].size.height - AUTOSCROLL_CATCH_SIZE));

    //Resize our view
    size.width = documentVisibleRect.size.width;
    size.height = contentsHeight;
    if(size.height < documentVisibleRect.size.height){
        size.height = documentVisibleRect.size.height;
    }
    [self setFrameSize:size];

    //If the user was near the bottom, move them back to the bottom (autoscroll)
    if(autoScroll){
        [[enclosingScrollView contentView] scrollToPoint:NSMakePoint(0, [self frame].size.height - documentVisibleRect.size.height)];
        [enclosingScrollView reflectScrolledClipView:[enclosingScrollView contentView]];
    }
}


@end









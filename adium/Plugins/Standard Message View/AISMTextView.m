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
#import "AISMVTimeCell.h"

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
    NSEnumerator		*cellEnumerator, *contentEnumerator, *timeCellEnumerator;
    NSRect			cellFrame, documentVisibleRect;

    NSString			*previousTimeString;
    id				previousSource;

    AISMVMessageCell		*textCell;
    AISMVTimeCell		*timeCell;


    
    //If there isn't enough content to fill our entire view, we move down so the content is bottom-aligned
    cellFrame = NSMakeRect(0, 0, [self frame].size.width, 0);
    documentVisibleRect = [[self enclosingScrollView] documentVisibleRect];
    if(contentsHeight < documentVisibleRect.size.height){
        cellFrame.origin.y += (documentVisibleRect.size.height - contentsHeight);
    }

    //Prepare for drawing
    [NSBezierPath setDefaultLineWidth:1.0];
    [NSBezierPath setDefaultLineCapStyle:NSButtLineCapStyle];

    cellEnumerator = [messageCellArray objectEnumerator];
    timeCellEnumerator = [timeCellArray objectEnumerator];
    contentEnumerator = [contentArray objectEnumerator];

    //Loop through, and draw, each cell
    previousSource = nil;
    previousTimeString = nil;
    while((textCell = [cellEnumerator nextObject])){
        AIContentMessage	*contentObject;
        NSString		*timeString;
        id			source;
        
        //Fetch all the information needed to display
        timeCell = [timeCellEnumerator nextObject];
        contentObject = [contentEnumerator nextObject];
        cellFrame.size.height = [textCell cellSize].height;
        source = [contentObject source];
        timeString = [timeCell timeString];
        
        if(NSIntersectsRect(documentVisibleRect,cellFrame)){ //Only draw visible cells
            NSSize		cellSize;
            AISMVSenderCell	*senderCell;
            
            //Draw the text cell
            cellSize = [textCell cellSize];
            [textCell drawWithFrame:NSMakeRect(cellFrame.origin.x + maxSenderWidth,
                                               cellFrame.origin.y,
                                               cellSize.width,
                                               cellFrame.size.height)
                             inView:self];

            //Draw the sender cell
            senderCell = [senderCellArray objectAtIndex:[senderArray indexOfObject:source]];
            [senderCell drawWithFrame:NSMakeRect(cellFrame.origin.x,
                                                 cellFrame.origin.y,
                                                 maxSenderWidth,
                                                 cellFrame.size.height)
                                showName:(source != previousSource)
                                inView:self];

            //Draw the time cell
            [timeCell drawWithFrame:NSMakeRect(cellFrame.origin.x + cellFrame.size.width - maxTimeWidth,
                                               cellFrame.origin.y,
                                               maxTimeWidth,
                                               cellFrame.size.height)
                           showTime:([timeString compare:previousTimeString] != 0)
                             inView:self];

            //Draw the divider line (offset 0.5 pixels for an aliased line)
            if(source != previousSource){
                [lineColorDarkDivider set];
                [NSBezierPath strokeLineFromPoint:NSMakePoint(cellFrame.origin.x, cellFrame.origin.y + 0.5)
                                          toPoint:NSMakePoint(cellFrame.origin.x + maxSenderWidth, cellFrame.origin.y + 0.5)];

                [lineColorDivider set];
                [NSBezierPath strokeLineFromPoint:NSMakePoint(cellFrame.origin.x + maxSenderWidth, cellFrame.origin.y + 0.5)
                                          toPoint:NSMakePoint(cellFrame.origin.x + maxSenderWidth + cellFrame.size.width, cellFrame.origin.y + 0.5)];
            }
        }

        //Next..
        cellFrame.origin.y += cellFrame.size.height;
	previousTimeString = timeString;
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
    timeCellArray = [[NSMutableArray alloc] init];
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
    [timeCellArray release];

    [super dealloc];
}

//Return yes so our view's origin is in the top left
- (BOOL)isFlipped{
    return(YES);
}

//Called when the frame changes.  Adjust to fill the new frame
- (void)frameChanged:(NSNotification *)notification
{    
    //Resize and redisplay
    [self resizeCells]; //live resize the contents
    [self resizeToFillContainerView];
    [self setNeedsDisplay:YES];
}

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
    AISMVSenderCell	*senderCell;
    AISMVMessageCell	*messageCell;
    AISMVTimeCell	*timeCell;
    
    if([[object type] compare:CONTENT_MESSAGE_TYPE] == 0){ //Message content
        AIContentMessage	*contentMessage = (AIContentMessage *)object;
        id			messageSource = [contentMessage source];
        BOOL			outgoing = ([messageSource isKindOfClass:[AIAccount class]]);

        //Add it to our content array
        [contentArray addObject:object];

        //Create a sender cell (if one doesn't already exist)
        if([senderArray indexOfObject:messageSource] == NSNotFound){
            if(outgoing){
                senderCell = [AISMVSenderCell senderCellWithString:[NSString stringWithFormat:@"%@:",[(AIAccount *)messageSource accountDescription]]
                                                         textColor:outgoingSourceColor
                                                   backgroundColor:backColorOut
                                                              font:[NSFont systemFontOfSize:11]];
            }else{
                senderCell = [AISMVSenderCell senderCellWithString:[NSString stringWithFormat:@"%@:",[(AIContactHandle *)messageSource displayName]]
                                                         textColor:incomingSourceColor
                                                   backgroundColor:backColorIn
                                                              font:[NSFont systemFontOfSize:11]];
            }
            
            //Cache it
            [senderArray addObject:messageSource];
            [senderCellArray addObject:senderCell];

            if([senderCell cellSize].width > maxSenderWidth){ //Resize the sender cells if this one is wider
                maxSenderWidth = [senderCell cellSize].width;
                [self resizeCells];
            }
        }

        
        //Create a time cell
        //User's localized date format: [[NSUserDefaults standardUserDefaults] objectForKey:NSTimeFormatString] w/ seconds
        timeCell = [AISMVTimeCell timeCellWithDate:[contentMessage date]
                                            format:@"%1I:%M"
                                         textColor:[NSColor grayColor]
                                   backgroundColor:(outgoing ? backColorOut : backColorIn)
                                              font:[NSFont fontWithName:@"Helvetica" size:10]];
        [timeCellArray addObject:timeCell];
        if([timeCell cellSize].width > maxTimeWidth){ //Resize the time cells if this one is wider
            maxTimeWidth = [timeCell cellSize].width;
            [self resizeCells];
        }

        
        //Create a message cell
        messageCell = [AISMVMessageCell messageCellWithString:[contentMessage message]
                                              backgroundColor:(outgoing ? backColorOut : backColorIn)];
        [messageCellArray addObject:messageCell];

        
        //Increase our height to fit this new cell
        contentsHeight += [messageCell sizeCellForWidth:([self frame].size.width - maxSenderWidth - maxTimeWidth) ].height;

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
    width = [enclosingScrollView documentVisibleRect].size.width - maxSenderWidth - maxTimeWidth;

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


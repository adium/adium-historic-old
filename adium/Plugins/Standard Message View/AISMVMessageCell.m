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

#import "AIAdium.h"
#import <AIUtilities/AIUtilities.h>
#import <Adium/Adium.h>
#import "AISMVMessageCell.h"
#import "AIContentMessage.h"

@interface AISMVMessageCell (PRIVATE)
- (AISMVMessageCell *)initMessageCellWithString:(NSAttributedString *)inString;
@end

//AIAttributedStringTextCell

#define MESSAGE_PADDING_Y 1
#define MESSAGE_PADDING_X 2

@implementation AISMVMessageCell

//Create a new cell
+ (AISMVMessageCell *)messageCellWithString:(NSAttributedString *)inString
{
    return([[[self alloc] initMessageCellWithString:inString] autorelease]);
}

//Resizes this cell for the desired width.  Returns the resulting size
- (NSSize)sizeCellForWidth:(float)inWidth
{
    //Reformat the text
    [textContainer setContainerSize:NSMakeSize(inWidth - (MESSAGE_PADDING_X * 2) , 1e7)];
    glyphRange = [layoutManager glyphRangeForTextContainer:textContainer];

    cellSize.width = inWidth;
    cellSize.height = [layoutManager usedRectForTextContainer:textContainer].size.height + (MESSAGE_PADDING_Y * 2);
    
    return(cellSize);
}

//Returns the last calculated cellSize (so, the last value returned by cellSizeForBounds)
- (NSSize)cellSize{
    return(cellSize);
}

//Set the background color of this cell
- (void)setBackgroundColor:(NSColor *)inColor
{
    backgroundColor = [inColor retain];
}

//Draws this cell in the requested view and rect
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    //Draw our background
    if(backgroundColor){
        [backgroundColor set];
    }else{
        [[NSColor whiteColor] set];
    }
    [NSBezierPath fillRect:cellFrame];
    
    //Draw the message string
    cellFrame.origin.x += MESSAGE_PADDING_X;
    cellFrame.origin.y += MESSAGE_PADDING_Y;
    [layoutManager drawGlyphsForGlyphRange:glyphRange atPoint:cellFrame.origin];

}

//Private --------------------------------------------------------------------------------
- (AISMVMessageCell *)initMessageCellWithString:(NSAttributedString *)inString
{
    [super init];

    //Init
    string = [inString retain];
    backgroundColor = nil;
    
    //Setup the layout manager and text container
    textStorage = [[NSTextStorage alloc] initWithAttributedString:inString];
    textContainer = [[NSTextContainer alloc] initWithContainerSize:NSMakeSize(1e7, 1e7)];
    layoutManager = [[NSLayoutManager alloc] init];
    
    [textContainer setLineFragmentPadding:0.0];
    [layoutManager addTextContainer:textContainer];
    [textStorage addLayoutManager:layoutManager];


    return(self);
}

- (void)dealloc
{
    [backgroundColor release];
    [textStorage release];
    [textContainer release];
    [layoutManager release];
    [string release];

    [super dealloc];
}

@end





/*

//Return the layout manager for our message text
- (NSLayoutManager *)messageLayoutManagerWithWidth:(int)inWidth
{
    if(!messageLayoutManager || messageLayoutWidth != inWidth){
        NSTextStorage 		*textStorage;
        NSTextContainer 	*textContainer;
    
//        NSLog(@"layout width %i",(int)inWidth);
    
        //Setup the layout manager and text container
        textStorage = [[NSTextStorage alloc] initWithAttributedString:[self messageString]];
        textContainer = [[NSTextContainer alloc] initWithContainerSize:NSMakeSize(inWidth, 1e7)];
        messageLayoutManager = [[NSLayoutManager alloc] init];
        
        //Configure
        [textContainer setLineFragmentPadding:0.0];
        [messageLayoutManager addTextContainer:textContainer];
        [textStorage addLayoutManager:messageLayoutManager];
        
        messageGlyphRange = [messageLayoutManager glyphRangeForTextContainer:textContainer];
        messageLayoutWidth = inWidth;
    }
    
    return(messageLayoutManager);
}

//Return the string of our sender
- (NSAttributedString *)senderString
{
    if(!senderString){
        AIContactHandle		*source;
        NSString			*senderNameString;
        NSColor			*senderColor;
        BOOL			incoming;
        NSMutableParagraphStyle	*style;
    
        //Get the sender information
        source = [object source];
        
        if([source isKindOfClass:[AIAccount class]]){
            senderNameString = [(AIAccount *)source accountDescription];
        }else{    
            senderNameString = [source displayName];
        }
        incoming = ![source isKindOfClass:[AIAccount class]];
    
        //Prepare some attributes
        style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        [style setAlignment:NSRightTextAlignment];
        
        if(incoming){
            senderColor = [[[owner preferenceController] preferenceForKey:@"message_incoming_darkPrefixColor" group:PREF_GROUP_GENERAL object:source] representedColor];
        }else{
            senderColor = [[[owner preferenceController] preferenceForKey:@"message_outgoing_darkPrefixColor" group:PREF_GROUP_GENERAL object:source] representedColor];
        }
    
        //Create
        senderString = [[NSAttributedString alloc] initWithString:senderNameString attributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSFont boldSystemFontOfSize:12], NSFontAttributeName, style, NSParagraphStyleAttributeName, senderColor, NSForegroundColorAttributeName, nil]];
    }
    
    return(senderString);
}
*/

/*    NSRect			segmentRect;
    AIContactHandle		*sender;
    BOOL			incoming;

    NSColor	*messageRowIn = [[preferenceController preferenceForKey:@"message_incoming_backgroundColor" group:PREF_GROUP_GENERAL object:sender] representedColor];
    NSColor	*messageRowOut = [[preferenceController preferenceForKey:@"message_outgoing_backgroundColor" group:PREF_GROUP_GENERAL object:sender] representedColor];


    sender = [object source];
    incoming = ![[object source] isKindOfClass:[AIAccount class]];


    //Draw the sender Gradient
    segmentRect = cellFrame;
    segmentRect.size.width = senderWidth;
    if(incoming){
        [AIGradient drawGradientInRect:segmentRect from:messageRowIn to:[messageRowIn darkenBy:0.10]];
    }else{
        [AIGradient drawGradientInRect:segmentRect from:messageRowOut to:[messageRowOut darkenBy:0.10]];
    }

    //Draw sender string
    if(drawSource){
        segmentRect.size.width -= SENDER_PADDING;
        [[self senderString] drawInRect:segmentRect];
        segmentRect.size.width += SENDER_PADDING;
    }

    //Draw the message background
    segmentRect.origin.x += segmentRect.size.width;
    segmentRect.size.width = cellFrame.size.width - segmentRect.origin.x;

    if(incoming){
        [messageRowIn set];
    }else{
        [messageRowOut set];
    }
    [NSBezierPath fillRect:segmentRect];
    
    //Draw the message string
    segmentRect.origin.x += MESSAGE_PADDING;

    [[self messageLayoutManagerWithWidth:(lastCellSize.width - senderWidth - MESSAGE_PADDING * 2)] drawGlyphsForGlyphRange:messageGlyphRange atPoint:segmentRect.origin];*/
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

#import "AIFlexibleTableTextCell.h"
#import "AIFlexibleTableView.h"
#import "AIFlexibleTableRow.h"
#import "AICursorAdditions.h"
#import "AITooltipUtilities.h"
#import "AILinkTrackingController.h"
#import "AITextAttachmentExtension.h"
#import "AIAttributedStringAdditions.h"

#define USE_OPTIMIZED_LIVE_RESIZE   NO  //If YES, text layout will not be recalculated during a resize

#define COPY_TEXT  AILocalizedString(@"Copy Text","Copy the text associated with an item")
#define COPY_IMAGE AILocalizedString(@"Copy Image","Copy the image associated with an item")

@interface AIFlexibleTableTextCell (PRIVATE)
- (NSRange)validRangeFromIndex:(int)sourceIndex to:(int)destIndex;
- (NSTextStorage *)createTextSystemWithString:(NSAttributedString *)inString size:(NSSize)inSize container:(NSTextContainer **)outContainer layoutManager:(NSLayoutManager **)outLayoutManager;
- (void)_buildLinkArray;
- (void)_showTooltipForEvent:(NSEvent *)theEvent;
- (void)_endTrackingMouse;
- (BOOL)_handleAttachmentClicks:(NSEvent *)theEvent atPoint:(NSPoint)inPoint offset:(NSPoint)offset;
- (NSArray *)_attachmentMenuItemsForEvent:(NSEvent *)theEvent atPoint:(NSPoint)inPoint offset:(NSPoint)offset;
- (NSRange)_validRangeFromIndex:(int)sourceIndex to:(int)destIndex;
@end

BOOL _mouseInRects(NSPoint aPoint, NSRectArray someRects, int arraySize, BOOL flipped);
NSRectArray _copyRectArray(NSRectArray someRects, int arraySize);

@implementation AIFlexibleTableTextCell

//Create a new cell with the string/color/text
+ (AIFlexibleTableTextCell *)cellWithString:(NSString *)inString color:(NSColor *)inTextColor font:(NSFont *)inFont alignment:(NSTextAlignment)inAlignment
{
    AIFlexibleTableTextCell	*cell;
    NSDictionary		*attributes;
    NSParagraphStyle		*paragraphStyle;
    NSAttributedString		*attributedString;
    
    //Create a paragraph style with the correct alignment
    paragraphStyle = [NSParagraphStyle styleWithAlignment:inAlignment];
    
    //Create the attributed string
    attributes = [NSDictionary dictionaryWithObjectsAndKeys:inTextColor, NSForegroundColorAttributeName,
															inFont, NSFontAttributeName, 
															paragraphStyle, NSParagraphStyleAttributeName, nil];
    attributedString = [[[NSAttributedString alloc] initWithString:inString attributes:attributes] autorelease];
    
    //Build the cell
    cell = [AIFlexibleTableTextCell cellWithAttributedString:attributedString];
    [cell setType:NSTextCellType];
    
    return(cell);
}

//Create a new cell from an attributed string
+ (AIFlexibleTableTextCell *)cellWithAttributedString:(NSAttributedString *)inString
{
    return([[[self alloc] initWithAttributedString:inString] autorelease]);
}

//
- (AIFlexibleTableTextCell *)initWithAttributedString:(NSAttributedString *)inString
{
    NSRange	scanRange;
    
    [super init];

    textStorage = nil;
    textContainer = nil;
    layoutManager = nil;
    linkTrackingController = nil;
    containsLinks = NO;
    uniqueEmoticonID = 0;

    string = [inString retain];

    //Create the text system
    textStorage = [[self createTextSystemWithString:string 
											   size:NSMakeSize(1e7, 1e7)
										  container:&textContainer
									  layoutManager:&layoutManager] retain];

    //Check if our string contains any links
    scanRange = NSMakeRange(0, 0);
    while(NSMaxRange(scanRange) < [textStorage length]){
        if([textStorage attribute:NSLinkAttributeName atIndex:NSMaxRange(scanRange) effectiveRange:&scanRange]){
            containsLinks = YES;
        }
    }
        
    return(self);
}

//Create a text system
- (NSTextStorage *)createTextSystemWithString:(NSAttributedString *)inString size:(NSSize)inSize container:(NSTextContainer **)outContainer layoutManager:(NSLayoutManager **)outLayoutManager
{
    NSTextStorage	*aTextStorage;
    NSLayoutManager	*aLayoutManager;
    NSTextContainer	*aContainer;

    //Create
    aTextStorage = [[NSTextStorage alloc] initWithAttributedString:inString];
    aContainer = [[NSTextContainer alloc] initWithContainerSize:inSize];
    aLayoutManager = [[NSLayoutManager alloc] init];
  
    //Setup
    [aContainer setLineFragmentPadding:1.0]; //A value of 0.0 appears to be invalid (it causes attribute display issues when the text container is resized to certain widths), so we'll use 1.0 since it's close though to 0 :)
    [aLayoutManager addTextContainer:aContainer];
	[aContainer release];
    [aTextStorage addLayoutManager:aLayoutManager];
	[aLayoutManager release];

    //Return
    if(outContainer) *outContainer = aContainer;
    if(outLayoutManager) *outLayoutManager = aLayoutManager;
    return([aTextStorage autorelease]);
}

//
- (void)dealloc
{    
    [textStorage release];
    [string release];
    [linkTrackingController release];

    [super dealloc];
}

//Resize the content of this cell to the desired width, returns new height
- (int)sizeContentForWidth:(float)inWidth
{
    if(!USE_OPTIMIZED_LIVE_RESIZE || ![[tableRow tableView] inLiveResize]){        
        //Reformat the text
        [textContainer setContainerSize:NSMakeSize(inWidth, 1e7)];
        glyphRange = [layoutManager glyphRangeForTextContainer:textContainer];
    
        //Return the new cell height
        contentHeight = [layoutManager usedRectForTextContainer:textContainer].size.height;
    }

    return(contentHeight);
}

//Draw our custom content
- (void)drawContentsWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    if(glyphRange.length != 0){
        if (isOpaque) {
			//drawBackgroundForGlyphRange:atPoint: doesn't actually invalidate the glyphs properly, so call glyphRangeForTextContainer: first
			[layoutManager glyphRangeForTextContainer:textContainer];
            [layoutManager drawBackgroundForGlyphRange:glyphRange atPoint:cellFrame.origin];
            [layoutManager drawGlyphsForGlyphRange:glyphRange atPoint:cellFrame.origin];
        } else {
            NSImage             *image;
            
            //Build an image of our rect before we draw
            image = [[NSImage alloc] initWithSize:cellFrame.size];
            [image setFlipped:[controlView isFlipped]];
            [image addRepresentation:[[[NSBitmapImageRep alloc] initWithFocusedViewRect:cellFrame] autorelease]];
            
            [controlView lockFocus];
            
			//Draw our glyphs
			
			//drawBackgroundForGlyphRange:atPoint: doesn't actually invalidate the glyphs properly, so call glyphRangeForTextContainer: first
			[layoutManager glyphRangeForTextContainer:textContainer];
            [layoutManager drawBackgroundForGlyphRange:glyphRange atPoint:cellFrame.origin];
            [layoutManager drawGlyphsForGlyphRange:glyphRange atPoint:cellFrame.origin];
            
            //Fade our new drawing back towards the original
            [image drawInRect:cellFrame
					 fromRect:NSMakeRect(0,0,cellFrame.size.width,cellFrame.size.height) 
					operation:NSCompositeSourceOver 
					 fraction:(1-opacity)];
            [controlView unlockFocus];
            [image release];
        }
    }
}


//Selection ---------------------------------------------------------------------------------
#pragma mark Selection
//Return the character index under the specified point
- (int)_characterIndexAtPoint:(NSPoint)point fractionOffset:(float)offset
{
    int 	glyphIndex;
    float	fractionOfDistanceThroughGlyph;

    //Factor in view padding
    point.x -= [self paddingInset].width;
    point.y -= [self paddingInset].height;

    //Get the character index
    glyphIndex = [layoutManager glyphIndexForPoint:point 
								   inTextContainer:textContainer 
					fractionOfDistanceThroughGlyph:&fractionOfDistanceThroughGlyph];
    if(fractionOfDistanceThroughGlyph >= offset){
        glyphIndex += 1;
    }

    return([layoutManager characterIndexForGlyphAtIndex:glyphIndex]);
}


// Link Tracking -------------------------------------------------------------------------------
#pragma mark Link tracking
//Returns YES if cursor rects were modified
- (BOOL)resetCursorRectsAtOffset:(NSPoint)offset visibleRect:(NSRect)visibleRect inView:(NSView *)controlView
{
    if(containsLinks){
        //Setup our link tracking
        if(!linkTrackingController){
            linkTrackingController = [[AILinkTrackingController linkTrackingControllerForView:controlView 
																			  withTextStorage:textStorage 
																				layoutManager:layoutManager
																				textContainer:textContainer] retain];
        }

        //Update for the new rect
        [linkTrackingController trackLinksInRect:visibleRect withOffset:offset];
    }

    return(containsLinks);
}

#pragma mark Mouse down events
//Handle a mouse down
- (BOOL)handleMouseDownEvent:(NSEvent *)theEvent atPoint:(NSPoint)inPoint offset:(NSPoint)inOffset
{
    BOOL	handled = NO;

    //Check for a link click
    if(!handled && containsLinks){
        handled = ([linkTrackingController handleMouseDown:theEvent withOffset:inOffset]);
    }

    //Check for an attachment click
    if(!handled){
        handled = [self _handleAttachmentClicks:theEvent atPoint:inPoint offset:inOffset];
    }

    return(handled);
}

//Handle attachment click toggling
- (BOOL)_handleAttachmentClicks:(NSEvent *)theEvent atPoint:(NSPoint)inPoint offset:(NSPoint)offset
{
    BOOL			handled = NO;
    unsigned int	charIndex;

    //Find clicked char index
    charIndex = [self _characterIndexAtPoint:inPoint fractionOffset:1.0];
    if(charIndex >= 0 && charIndex < [textStorage length]){
       if([[textStorage string] characterAtIndex:charIndex] == NSAttachmentCharacter){ //Check for emoticons to turn into text
		   AITextAttachmentExtension	*attachment = [textStorage attribute:NSAttachmentAttributeName
																	 atIndex:charIndex
															  effectiveRange:nil];
           NSString						*repStr = [attachment string];

		   //Check if the string exists and wants its alternate text to be used
           if(repStr != nil && [attachment hasAlternate]) {
               NSMutableAttributedString	*repAttStr = [[NSMutableAttributedString alloc] initWithString:repStr];

               NSMutableDictionary			*attributes = [[textStorage attributesAtIndex:charIndex 
																		   effectiveRange:nil] mutableCopy];
               unsigned int					tempIndex = charIndex;
               NSColor						*tempColor = nil;

               if(tempIndex > 0){
                   while(((tempColor = [textStorage attribute:NSForegroundColorAttributeName 
													 atIndex: --tempIndex effectiveRange:nil]) == nil) && (tempIndex != 0));
               }else if([textStorage length] > 1){
                   while(((tempColor = [textStorage attribute:NSForegroundColorAttributeName 
													 atIndex: ++tempIndex effectiveRange:nil]) == nil) &&
						 (tempIndex != ([textStorage length] - 1)));
               }

               if(tempColor) [attributes setObject:tempColor forKey:NSForegroundColorAttributeName];
               
			   [attributes setObject:attachment
							  forKey:@"IKHiddenAttachment"];
               [attributes setObject:[NSNumber numberWithInt:uniqueEmoticonID++] 
							  forKey:@"IKHiddenAttachmentUniq"]; //Add unique ID so ranges remain distinct
               
			   [attributes removeObjectForKey:NSAttachmentAttributeName];
               [repAttStr addAttributes:attributes range:NSMakeRange(0,[repAttStr length])];
               [attributes release];

               //Insert string
               [textStorage replaceCharactersInRange:NSMakeRange(charIndex,1) withAttributedString:repAttStr];
               [repAttStr release];
               handled = YES;
           }

       }else if([textStorage attribute:@"IKHiddenAttachment" atIndex:charIndex effectiveRange:nil]){ //Check for text to turn back into emoticons
           NSRange			replaceRange;
           NSMutableAttributedString	*repAttStr;
           AITextAttachmentExtension	*repAtt = [textStorage attribute:@"IKHiddenAttachment" 
																 atIndex:charIndex
														  effectiveRange:&replaceRange];

           repAttStr = [[NSMutableAttributedString attributedStringWithAttachment:repAtt] retain];
           [repAttStr addAttributes:[textStorage attributesAtIndex:charIndex effectiveRange:nil] 
							  range:NSMakeRange(0,1)];

           //Replace text with original image
           [textStorage replaceCharactersInRange:replaceRange withAttributedString:repAttStr];

           handled = YES;
       }
   }

   if(handled){
       glyphRange = [layoutManager glyphRangeForTextContainer:textContainer];
       [[tableRow tableView] resizeRow:tableRow];
   }

   return(NO);	//Returning TRUE gets in the way of selections, making copying difficult
}

//Change this cell's selection
- (void)selectContentFrom:(NSPoint)source to:(NSPoint)dest offset:(NSPoint)inOffset mode:(int)selectMode
{
    BOOL 	above = (source.x == -1 && source.y == -1);
    BOOL 	below = (dest.x == 1e7 && dest.y == 1e7);
    int		startIndex = (above ? 0 : [self _characterIndexAtPoint:source fractionOffset:0.5]);
    int		stopIndex = (below ? 1e7 : [self _characterIndexAtPoint:dest fractionOffset:0.5]);
	
    if(selectMode == 2){ //Extend to words
        startIndex = [textStorage doubleClickAtIndex:startIndex].location;
        stopIndex = (below ? 1e7 : NSMaxRange([textStorage doubleClickAtIndex:stopIndex]));

    }else if(selectMode == 3){ //Extend to cells
        startIndex = 0;
        stopIndex = 1e7;
        
    }

    //Ensure a valid range
    selectionRange = [self _validRangeFromIndex:startIndex to:stopIndex];

    //Remove any existing coloring
    [layoutManager removeTemporaryAttribute:NSBackgroundColorAttributeName
						  forCharacterRange:NSMakeRange(0,[textStorage length])];

    //Convert those coordinates to the nearest glyph index
    [layoutManager addTemporaryAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSColor selectedTextBackgroundColor], NSBackgroundColorAttributeName, nil] forCharacterRange:selectionRange];

    //
    [[tableRow tableView] setNeedsDisplay:YES];
}

//
- (void)deselectContent
{
    selectionRange = NSMakeRange(0,0);

    [layoutManager removeTemporaryAttribute:NSBackgroundColorAttributeName
						  forCharacterRange:NSMakeRange(0,[textStorage length])];

    [[tableRow tableView] setNeedsDisplay:YES];
}

//
- (BOOL)pointIsSelected:(NSPoint)inPoint offset:(NSPoint)inOffset
{
    return(NSLocationInRange([self _characterIndexAtPoint:inPoint fractionOffset:0.5], selectionRange));
}

//
- (NSAttributedString *)selectedString
{
    NSMutableAttributedString *selectedString = nil;
    
    if(selectionRange.length && ((selectionRange.location + selectionRange.length) <= [string length])){
        //Get the selected text (Safestring converts any attachments to text)
        selectedString = [[[[string attributedSubstringFromRange:selectionRange] safeString] mutableCopy] autorelease];

        //Strip any attributes we don't want to return
        [selectedString removeAttribute:NSBackgroundColorAttributeName
								  range:NSMakeRange(0,[selectedString length])]; //Background color
        [selectedString removeAttribute:NSParagraphStyleAttributeName 
								  range:NSMakeRange(0,[selectedString length])]; //evands: Paragraph style - some style settings like Centered cause a crash

        //Add a return character
        [selectedString appendString:@"\r" withAttributes:[selectedString attributesAtIndex:([selectedString length]-1) 
																			 effectiveRange:nil]];
    }
    
    return(selectedString);
}

//Converts the specified source/dest index to a valid NSRange
- (NSRange)_validRangeFromIndex:(int)sourceIndex to:(int)destIndex
{
    NSRange	range;

    //The range must go from left to right
    if(sourceIndex < destIndex){
        range = NSMakeRange(sourceIndex, destIndex - sourceIndex);
    }else{
        range = NSMakeRange(destIndex, sourceIndex - destIndex);
    }

    //The range cannot start before our string
    if(range.location < 0) range.location = 0;

    //The range cannot end beyond the end of our string
    if(range.location + range.length > [textStorage length]){
        range.length = [textStorage length] - range.location;
    }

    return(range);
}

//****Contextual menu items
#pragma mark Contextual menu items

//Supply menu items
- (NSArray *)menuItemsForEvent:(NSEvent *)theEvent atPoint:(NSPoint)inPoint offset:(NSPoint)inOffset
{
    NSArray *menuItemArray = nil;

    //Get emoticon menu items
    menuItemArray = [self _attachmentMenuItemsForEvent:theEvent atPoint:inPoint offset:inOffset];
    
    //Add link menu items
    if (containsLinks){
        NSArray *linkMenuItems = ([linkTrackingController menuItemsForEvent:theEvent withOffset:inOffset]);
        if (menuItemArray)
            menuItemArray = [menuItemArray arrayByAddingObjectsFromArray:linkMenuItems];
        else
            menuItemArray = linkMenuItems;
    }
    
    return(menuItemArray);
}

//Return the menu items for an attachment
- (NSArray *)_attachmentMenuItemsForEvent:(NSEvent *)theEvent atPoint:(NSPoint)inPoint offset:(NSPoint)offset
{
    NSMutableArray      *menuItemArray = nil;
    NSMenuItem          *menuItem;
    unsigned int		charIndex;
    
    //Find clicked char index
    charIndex = [self _characterIndexAtPoint:inPoint fractionOffset:1.0];
    if(charIndex >= 0 && charIndex < [textStorage length]){
        //Check for emoticons in image form
        if( ([[textStorage string] characterAtIndex:charIndex] == NSAttachmentCharacter) ) {
			AITextAttachmentExtension	*attachment;
			NSImage						*image;
			NSString					*repStr;
			
			//Make an array for transmitting the items
			menuItemArray = [[[NSMutableArray alloc] init] autorelease];
			
			attachment = [textStorage attribute:NSAttachmentAttributeName 
																	 atIndex:charIndex
															  effectiveRange:nil];   
			image = [(NSTextAttachmentCell *)[attachment attachmentCell] image];
			
			menuItem = [[[NSMenuItem alloc] initWithTitle:COPY_IMAGE
												   target:self
												   action:@selector(copyImage:)
											keyEquivalent:@""] autorelease];
			[menuItem setRepresentedObject:image];
			[menuItemArray addObject:menuItem];
			
			//get the string value
			repStr = [attachment string];
			
			//Check if the string exists and wants its alternate text to be used
			if(repStr != nil && [attachment hasAlternate]) {
				
				NSAttributedString *formattedText = [[NSAttributedString alloc] initWithString:repStr
																					attributes:[textStorage attributesAtIndex:charIndex
																											   effectiveRange:nil]];
				menuItem = [[[NSMenuItem alloc] initWithTitle:COPY_TEXT
													   target:self
													   action:@selector(copyText:)
												keyEquivalent:@""] autorelease];
				[menuItem setRepresentedObject:[formattedText autorelease]];                
				[menuItemArray addObject:menuItem];
			}
		} 
        //Check for emoticons in text form
        else if ([textStorage attribute:@"IKHiddenAttachment" atIndex:charIndex effectiveRange:nil]) {
            //Make an array for transmitting the items
            NSRange			replaceRange;
            menuItemArray = [[[NSMutableArray alloc] init] autorelease];
            
            AITextAttachmentExtension	*attachment = [textStorage attribute:@"IKHiddenAttachment" 
                                                                         atIndex:charIndex
                                                                  effectiveRange:&replaceRange];
            
            NSAttributedString *formattedText = [textStorage attributedSubstringFromRange:replaceRange];
            menuItem = [[[NSMenuItem alloc] initWithTitle:COPY_TEXT
                                                   target:self
                                                   action:@selector(copyText:)
                                            keyEquivalent:@""] autorelease];
            [menuItem setRepresentedObject:formattedText];                
            [menuItemArray addObject:menuItem];
            
            NSImage                     *image = [(NSTextAttachmentCell *)[attachment attachmentCell] image];
            menuItem = [[[NSMenuItem alloc] initWithTitle:COPY_IMAGE
                                                   target:self
                                                   action:@selector(copyImage:)
                                            keyEquivalent:@""] autorelease];
            [menuItem setRepresentedObject:image];
            [menuItemArray addObject:menuItem];
            
        }
    }
    return menuItemArray;
}

- (void)copyText:(id)sender
{
    NSAttributedString *copyString = [sender representedObject];
    [[NSPasteboard generalPasteboard] declareTypes:[NSArray arrayWithObject:NSRTFPboardType] owner:nil];
    [[NSPasteboard generalPasteboard] setData:[copyString RTFFromRange:NSMakeRange(0,[copyString length])
													documentAttributes:nil] 
									  forType:NSRTFPboardType];
}

- (void)copyImage:(id)sender
{
    NSImage *copyImage = [sender representedObject];
    [[NSPasteboard generalPasteboard] declareTypes:[NSArray arrayWithObject:NSTIFFPboardType] owner:nil];
    [[NSPasteboard generalPasteboard] setData:[copyImage TIFFRepresentation] forType:NSTIFFPboardType];
}
                                                               
@end


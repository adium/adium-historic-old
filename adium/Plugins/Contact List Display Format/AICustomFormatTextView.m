/* 
Copyright (C) 2001-2002  Adam Iser
 */

#import "AICustomFormatTextView.h"

@implementation AICustomFormatTextView

/* awakeFromNib
 *   cache our keyword color as we wake from the nib
 */
- (void)awakeFromNib
{
    greenColor = [[NSColor colorWithCalibratedRed:0.647 green:0.741 blue:0.839 alpha:1.0] retain];
}

- (void)dealloc
{
    [greenColor release];
    
    [super dealloc];
}

/* setSelectedRange
 *   if the selection includes part of a keyword, we extend it to include the entire keyword.  This prevents
 *   'half-selection' of our green keywords
 */
- (void)setSelectedRange:(NSRange)charRange affinity:(NSSelectionAffinity)affinity stillSelecting:(BOOL)stillSelectingFlag
{
    NSRange	effectiveRange;
    short 	loop;
    short	location = charRange.location;
    short	length = charRange.length;
    
    short	stringLength = [[self textStorage] length];
    
    short	leftOfKeyWord = 0;
    short	rightOfKeyWord = stringLength;

    unichar 	character;

    //if we start inside a keyword
    if(location > 0 && location < stringLength){
        [[[self textStorage] string] getCharacters:&character range:NSMakeRange(location,1)];        
        if([[[self textStorage] attributesAtIndex:location effectiveRange:&effectiveRange] objectForKey:NSBackgroundColorAttributeName] != nil && character != 60){

            //find left
            for(loop = location;loop >= 0;loop--){
                [[[self textStorage] string] getCharacters:&character range:NSMakeRange(loop,1)];        
                if(character == 60){
                    leftOfKeyWord = loop;
                    loop = -1;
                }
            }
            
            //find right
            for(loop = location;loop < stringLength;loop++){
                [[[self textStorage] string] getCharacters:&character range:NSMakeRange(loop,1)];        
                if(character == 62){
                    rightOfKeyWord = loop+1;
                    loop = stringLength+1;
                }
            }

            if(length == 0){
                length = rightOfKeyWord - leftOfKeyWord;
            }else{
                length += (location - leftOfKeyWord);
            }

            location = leftOfKeyWord;
        }
    }

    //if we end inside a keyword
    if(location+length > 0 && location+length < stringLength){
        [[[self textStorage] string] getCharacters:&character range:NSMakeRange(location+length,1)];        
        if([[[self textStorage] attributesAtIndex:location+length effectiveRange:&effectiveRange] objectForKey:NSBackgroundColorAttributeName] != nil && character != 60){

            //find right
            for(loop = location+length;loop < stringLength;loop++){
                [[[self textStorage] string] getCharacters:&character range:NSMakeRange(loop,1)];        
                if(character == 62){
                    rightOfKeyWord = loop+1;
                    loop = stringLength+1;
                }
            }

            length += rightOfKeyWord-(location+length);
        }
    }

    [super setSelectedRange:NSMakeRange(location,length) affinity:affinity stillSelecting:stillSelectingFlag];
}

/* deleteBackward
 *   we need to override the 'delete' action to prevent the user from deleting characters of our keywords.
 *   To do this we simply select the character to our left, then delete it... so if a keyword is to our left 
 *   the entire keyword will be deleted.. otherwise the behavior will look + act almost normal
 */
- (void)deleteBackward:(id)sender
{
    short location = [self selectedRange].location;
    short length = [self selectedRange].length;    
    
    //select one char to our left
    if(length == 0){
        if(location != 0){
            [self setSelectedRange:NSMakeRange(location-1,1)];
            [super deleteBackward:sender];
        }
    }else{
        //they've selected a range, so a keyword couldn't be deleted
        [super deleteBackward:sender];
    }
}

/* insertText
 *   here we override the inserting of text.  Replacing < and > with their html equivelents, and handling
 *   deleting of the current selection and insertion of the new text
*  EDS: I don't think this actually accomplishes anything. Remove?
 */ 
- (void)insertText:(id)insertString
{
    NSMutableAttributedString	*newString;

    newString = [[NSMutableAttributedString alloc] initWithString:insertString];

    //delete the selection
    if([self selectedRange].length != 0){
        [[self textStorage] deleteCharactersInRange:[self selectedRange]];
    }

    //insert the new string
    [[self textStorage] insertAttributedString:newString atIndex:[self selectedRange].location];

    //clean up
    [newString release];
    
    [super insertText:nil];
}

/* performDragOperation
 *   this function adds <>'s around the text being dragged right before it gets "dropped" into us
 */
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    NSPasteboard	*pboard = [sender draggingPasteboard];
    NSString		*theString = [pboard stringForType:NSStringPboardType];

    [pboard setString:[NSString stringWithFormat:@"<%@>",theString] forType:NSStringPboardType];

    return([super performDragOperation:sender]);
}

/* concludeDragOperation
 *   this function colors the newly dropped text green (so it's treated as a keyword)
 */
- (void)concludeDragOperation:(id<NSDraggingInfo>)sender
{
    [super concludeDragOperation:sender];

    [[self textStorage] addAttribute:NSBackgroundColorAttributeName value:greenColor range:NSMakeRange([self selectedRange].location+0,[self selectedRange].length - 0)];
}

@end

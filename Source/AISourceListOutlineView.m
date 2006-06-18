//
//  AISourceListOutlineView.m
//  Adium
//
//  Created by Evan Schoenberg on 6/18/06.
//

#import "AISourceListOutlineView.h"
#import <AIUtilities/AIGradient.h>

@implementation AISourceListOutlineView

- (void)_drawRowSelectionInRect:(NSRect)rect
{
	//Draw the gradient
	AIGradient *gradient = [AIGradient selectedControlGradientWithDirection:AIVertical];
	[gradient drawInRect:rect];
	
	//Draw a line at the light side, to make it look a lot cleaner
	rect.size.height = 1;
	[[NSColor alternateSelectedControlColor] set];
	NSRectFillUsingOperation(rect, NSCompositeSourceOver);	
}

- (void)highlightSelectionInClipRect:(NSRect)clipRect
{
	//Apple wants us to do some pretty crazy stuff for selections in 10.3
	NSIndexSet *indices = [self selectedRowIndexes];
	unsigned int bufSize = [indices count];
	unsigned int *buf = malloc(bufSize * sizeof(unsigned int));
	unsigned int i;
	
	NSRange range = NSMakeRange([indices firstIndex], ([indices lastIndex]-[indices firstIndex]) + 1);
	[indices getIndexes:buf maxCount:bufSize inIndexRange:&range];
	
	for (i = 0; i < bufSize; i++) {
		[self _drawRowSelectionInRect:[self rectOfRow:buf[i]]];
	}
	
	free(buf);
}

//Override to prevent drawing glitches; otherwise, the cell will try to draw a highlight, too
- (id)_highlightColorForCell:(NSCell *)cell
{
	return nil;
}

@end

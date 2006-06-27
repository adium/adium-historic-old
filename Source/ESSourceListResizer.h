//
//  ESSourceListResizer.h
//  Adium
//
//  Created by Evan Schoenberg on 6/26/06.
//

#import <Cocoa/Cocoa.h>
#import "ESSourceListBackgroundView.h"

@interface ESSourceListResizer : ESSourceListBackgroundView {
	id			delegate;

	BOOL		draggingDivider;
	NSPoint		originalMouseLocation;
	
	NSString			*stringValue;
	NSAttributedString	*attributedStringValue;
	float				stringHeight;
}

- (NSRect)resizeControlRect;
- (void)setStringValue:(NSString *)inString;
- (void)setDelegate:(id)inDelegate;

@end

@interface NSObject (ESSourceListResizerViewDelegate)
- (void)draggedDividerRightBy:(float)deltaX;
@end

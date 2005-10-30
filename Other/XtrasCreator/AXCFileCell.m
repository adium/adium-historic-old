//
//  AXCFileCell.m
//  XtrasCreator
//
//  Created by Mac-arena the Bored Zo on 2005-10-30.
//  Copyright 2005 Adium Team. All rights reserved.
//

#import "AXCFileCell.h"
#include <c.h>

@implementation AXCFileCell

- (void)setObjectValue:(id <NSCopying>)newObj {
	NSString *path = newObj;

	if (![path isAbsolutePath])
		path = [[[NSFileManager defaultManager] currentDirectoryPath] stringByAppendingPathComponent:path];

	[super setObjectValue:path];
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)view {
	NSString *path = [self stringValue];

	float gutter = 0.0, contentHeight = 16.0;
	static const float visualSeparation = 8.0;

	/*draw the icon*/ {
		NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:path];
		[icon setFlipped:YES];

		//get the largest size that will fit entirely within the frame.
		float cellDimension = MIN(cellFrame.size.width, cellFrame.size.height);
		if (cellDimension > 256.0)
			contentHeight = 256.0;
		else if (cellDimension > 128.0)
			contentHeight = 128.0;
		else if (cellDimension >  48.0)
			contentHeight =  48.0;
		else if (cellDimension >  32.0)
			contentHeight =  32.0;
		else
			contentHeight =  16.0;
		NSSize imageSize = { contentHeight, contentHeight };
		[icon setSize:imageSize];

		gutter = (cellDimension - contentHeight) / 2.0;
		NSRect imageSrcRect = {
			NSZeroPoint,
			imageSize
		};
		NSRect imageDestRect = {
			{ cellFrame.origin.x + gutter + visualSeparation, cellFrame.origin.y + gutter },
			imageSize
		};

		[icon drawInRect:imageDestRect
				fromRect:imageSrcRect
			   operation:NSCompositeSourceOver
				fraction:1.0];
	}

	/*draw the filename*/ {
		NSString *filename = [[NSFileManager defaultManager] displayNameAtPath:path];

		float leftMargin = gutter + (visualSeparation * 2.0) + contentHeight;
		NSRect destRect = {
			{ cellFrame.origin.x + leftMargin, cellFrame.origin.y + gutter },
			{ cellFrame.size.width - leftMargin, contentHeight }
		};

		NSColor *textColor;
		if([self isHighlighted]) {
			//credit to Ken Ferry for coming up with this test.
			if([[self highlightColorWithFrame:cellFrame inView:view] isEqual:[NSColor alternateSelectedControlColor]])
				textColor = [NSColor alternateSelectedControlTextColor];
			else
				textColor = [NSColor selectedControlTextColor];
		} else
			textColor = [NSColor controlTextColor];

		NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
			[NSFont systemFontOfSize:0.0], NSFontAttributeName,
			textColor, NSForegroundColorAttributeName,
			nil];

		[filename drawInRect:destRect withAttributes:attrs];
	}
}

@end

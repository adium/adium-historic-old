//
//  AIWindowDraggingView.h
//  Adium
//
//  Created by Evan Schoenberg on 3/6/06.
//

#import <Cocoa/Cocoa.h>

@interface AIWindowDraggingView : NSView {
    NSPoint originalMouseLocation;
	NSRect	windowFrame;
	BOOL	inLeftMouseEvent;	
}

@end

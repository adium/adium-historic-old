//
//  AIViewGridView.h
//  Adium
//
//  Created by Adam Iser on 12/10/04.
//  Copyright (c) 2004 The Adium Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AIViewGridView : NSView {
	int 	columns;
	NSSize	padding;
	NSSize	largest;
}

- (void)addView:(NSView *)inView;
- (void)removeAllViews;

@end

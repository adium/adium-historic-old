//
//  AIImageTextCellView.h
//  Adium
//
//  Created by Evan Schoenberg on 12/22/04.
//  Copyright 2004-2005 The Adium Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AIImageTextCellView : NSView {
	AIImageTextCell	*cell;
}

- (void)setStringValue:(NSString *)inString;
- (void)setImage:(NSImage *)inImage;
- (void)setSubString:(NSString *)inSubString;

@end

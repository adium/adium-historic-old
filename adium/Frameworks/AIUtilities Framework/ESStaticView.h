//
//  ESStaticView.h
//  Adium XCode
//
//  Created by Evan Schoenberg on Wed Oct 08 2003.
//

#import <Cocoa/Cocoa.h>

@interface ESStaticView : NSView {
    NSImage	*image;
    NSRect      sourceRect;
}

- (id)initWithFrame:(NSRect)frameRect image:(NSImage *)inImage;
- (void)drawRect:(NSRect)rect;
- (void)setImage:(NSImage *)inImage;
- (NSImage *)image;

@end

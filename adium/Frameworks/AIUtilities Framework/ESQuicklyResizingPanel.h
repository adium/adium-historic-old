//
//  ESQuicklyResizingPanel.h
//  Adium XCode
//
//  Created by Evan Schoenberg on Sat Oct 25 2003.
//

#import <Cocoa/Cocoa.h>

@interface ESQuicklyResizingPanel : NSPanel {
    NSTimeInterval resizeInterval;
}

-(NSTimeInterval)resizeInterval;
-(void)setResizeInterval:(NSTimeInterval)inInterval;

@end

//
//  ESQuicklyResizingPanel.h
//  Adium
//
//  Created by Evan Schoenberg on Sat Oct 25 2003.
//

@interface ESQuicklyResizingPanel : NSPanel {
    NSTimeInterval resizeInterval;
}

-(NSTimeInterval)resizeInterval;
-(void)setResizeInterval:(NSTimeInterval)inInterval;

@end

//
//  ESQuicklyResizingPanel.h
//  Adium
//
//  Created by Evan Schoenberg on Sat Oct 25 2003.
//  Copyright (c) 2003-2005 The Adium Team. All rights reserved.
//

@interface ESQuicklyResizingPanel : NSPanel {
    NSTimeInterval resizeInterval;
}

-(NSTimeInterval)resizeInterval;
-(void)setResizeInterval:(NSTimeInterval)inInterval;

@end

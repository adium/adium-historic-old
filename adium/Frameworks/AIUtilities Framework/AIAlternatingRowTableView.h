//
//  AIAlternatingRowTableView.h
//  Adium
//
//  Created by Adam Iser on Sat Feb 01 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AIAlternatingRowTableView : NSTableView {
    BOOL	drawsAlternatingRows;
    NSColor	*alternatingRowColor;

    BOOL	_dataSourceDeleteRow;
}

- (void)setDrawsAlternatingRows:(BOOL)flag;
- (void)setAlternatingRowColor:(NSColor *)color;

@end

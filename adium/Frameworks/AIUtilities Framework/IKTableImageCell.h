//
//  IKTableImageCell.h
//  Adium
//
//  Created by Ian Krieg on Mon Jul 28 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

@interface IKTableImageCell : NSImageCell {
    BOOL	isHighlighted;
}

- (void)setHighlighted:(BOOL)flag;
- (BOOL)isHighlighted;

@end

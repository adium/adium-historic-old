//
//  IKTableImageCell.h
//  Adium
//
//  Created by Ian Krieg on Mon Jul 28 2003.
//

@interface IKTableImageCell : NSImageCell {
    BOOL	isHighlighted;
}

- (void)setHighlighted:(BOOL)flag;
- (BOOL)isHighlighted;

@end

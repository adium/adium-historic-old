//
//  AIListContactMockieCell.h
//  Adium
//
//  Created by Adam Iser on Sun Aug 01 2004.
//

#import "AIListContactCell.h"

@interface AIListContactMockieCell : AIListContactCell {
	BOOL	drawGrid;
}

- (void)setDrawsGrid:(BOOL)inValue;

@end

//
//  ESRankingCell.h
//  Adium
//
//  Created by Evan Schoenberg on 11/1/04.
//

#import <Cocoa/Cocoa.h>


@interface ESRankingCell : NSCell {
	float	percentage;
}

-(void)setPercentage:(float)percentage;

@end

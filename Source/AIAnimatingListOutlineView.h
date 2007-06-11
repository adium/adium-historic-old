//
//  AIAnimatingListOutlineView.h
//  Adium
//
//  Created by Evan Schoenberg on 6/8/07.
//

#import <Cocoa/Cocoa.h>
#import <Adium/AIListOutlineView.h>

@interface AIAnimatingListOutlineView : AIListOutlineView {
	NSMutableDictionary *allAnimatingItemsDict;
	int animations;
	NSSize animationHedgeFactor;
}

- (NSSize)animationHedgeFactor;

@end

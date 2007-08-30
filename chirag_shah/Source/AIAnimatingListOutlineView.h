//
//  AIAnimatingListOutlineView.h
//  Adium
//
//  Created by Evan Schoenberg on 6/8/07.
//

#import <Cocoa/Cocoa.h>
#import <Adium/AIListOutlineView.h>

@interface AIAnimatingListOutlineView : AIListOutlineView {
	BOOL	enableAnimation;
	
	NSMutableDictionary *allAnimatingItemsDict;
	int animations;
	NSSize animationHedgeFactor;
	
	BOOL disableExpansionAnimation;
}

- (void)setEnableAnimation:(BOOL)shouldEnable;
- (BOOL)enableAnimation;

@end

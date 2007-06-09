//
//  AIAnimatingListOutlineView.h
//  Adium
//
//  Created by Evan Schoenberg on 6/8/07.
//

#import <Cocoa/Cocoa.h>
#import <Adium/AIListOutlineView.h>

@interface AIAnimatingListOutlineView : AIListOutlineView {
	NSTimer *animationTimer;
	NSMutableDictionary *allAnimatingItemsDict;
	int animations;
}

@end

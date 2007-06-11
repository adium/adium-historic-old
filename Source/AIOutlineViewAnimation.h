//
//  AIOutlineViewAnimation.h
//  Adium
//
//  Created by Evan Schoenberg on 6/9/07.
//

#import <Cocoa/Cocoa.h>

#define LIST_OBJECT_ANIMATION_DURATION .5
#define EXPANSION_DURATION .15

@interface AIOutlineViewAnimation : NSAnimation {
	NSDictionary *dict;
	id delegate;
}

+ (AIOutlineViewAnimation *)listObjectAnimationWithDictionary:(NSDictionary *)inDict delegate:(id)inDelegate;

@end

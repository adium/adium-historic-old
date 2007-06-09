//
//  AIOutlineViewAnimation.h
//  Adium
//
//  Created by Evan Schoenberg on 6/9/07.
//

#import <Cocoa/Cocoa.h>

@interface AIOutlineViewAnimation : NSAnimation {
	NSDictionary *dict;
	id delegate;
}

+ (AIOutlineViewAnimation *)listObjectAnimationWithDictionary:(NSDictionary *)inDict delegate:(id)inDelegate;

@end

//
//  ESWebFrameViewAdditions.m
//  Adium XCode
//
//  Created by Evan Schoenberg on Fri Mar 05 2004.
//

#import "ESWebFrameViewAdditions.h"


@implementation WebFrameView (ESWebFrameViewAdditions)

- (void)setAllowsHorizontalScrolling:(BOOL)inAllow
{
	[[_private frameScrollView] setAllowsHorizontalScrolling:inAllow];
}

@end


//ESWebFrameViewPrivateHack poses as WebFrameViewPrivate to let us access its protected variables
@implementation WebFrameViewPrivate (ESWebFrameViewPrivateHack)
/*
+ (void)load
{
	//Pose as WebFrameViewPrivate to add our own 
    [self poseAsClass:[WebFrameViewPrivate class]];
}
*/
//frameScrollView is normally protected; add an accesssor to it
- (WebDynamicScrollBarsView *)frameScrollView
{
	return frameScrollView;
}

@end
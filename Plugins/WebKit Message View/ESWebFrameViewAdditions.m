//
//  ESWebFrameViewAdditions.m
//  Adium
//
//  Created by Evan Schoenberg on Fri Mar 05 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

#import "ESWebFrameViewAdditions.h"

@implementation WebFrameView (ESWebFrameViewAdditions)

//WebDynamicScrollBarsView is a subclass of NSScrollView
- (WebDynamicScrollBarsView *)frameScrollView
{
	return [_private frameScrollView];
}

@end

//ESWebFrameViewPrivateHack lets us access WebFrameViewPrivate's protected variables
@implementation WebFrameViewPrivate (ESWebFrameViewPrivateHack)

//frameScrollView is normally protected; add an accesssor to it
- (WebDynamicScrollBarsView *)frameScrollView
{
	return frameScrollView;
}

@end

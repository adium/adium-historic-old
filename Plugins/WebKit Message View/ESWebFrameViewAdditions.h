//
//  ESWebFrameViewAdditions.h
//  Adium
//
//  Created by Evan Schoenberg on Fri Mar 05 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

#import "WebKitPrivateDefinitions.h"

@interface WebFrameView (ESWebFrameViewAdditions)
- (WebDynamicScrollBarsView *)frameScrollView;
@end

@interface WebFrameViewPrivate (ESWebFrameViewPrivateHack)
- (WebDynamicScrollBarsView *)frameScrollView;
@end


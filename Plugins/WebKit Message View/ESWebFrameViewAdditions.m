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

/* 
 * @category WebHTMLView (ESWebHTMLViewCrashFix)
 * @brief Fixes a crash when scrolling
 * 
 * The crash this category is intended to fix looks like this:
 *
 * OS Version:     Version 10.3.7 (Build 7S215)
 * Exception:      NSInvalidArgumentException
 * Reason: *** -[WebHTMLView _destinationFloatValueForScroller:]: selector not recognized
 * Stack trace:
 * 1  +[NSException raise:format:] (in Foundation)
 * 2  -[NSObject(NSForwardInvocation) forward::] (in Foundation)
 * 3  __objc_msgForward (in libobjc.A.dylib)
 * 4  -[NSScroller _testPartUsingDestinationFloatValue:] (in AppKit)
 * 5  -[NSScroller trackPagingArea:] (in AppKit)
 * 6  -[NSScroller mouseDown:] (in AppKit)
 * 7  __ZN12KWQKHTMLPart32passWidgetMouseDownEventToWidgetEP7QWidget (in WebCore)
 * 8  __ZN12KWQKHTMLPart32passWidgetMouseDownEventToWidgetEPN5khtml10MouseEventE (in WebCore)
 * 9必封封封必封封封必封封封必封封封必封封封2:52.728o *       __ZN12KWQKHTMLPart20khtmlMousePressEventEPN5khtml15MousePressEventE (in WebCore)
 * 10  0x99282874 (in WebCore)
 * 11  __ZN9KHTMLView23viewportMousePressEventEP11QMouseEvent (in WebCore)
 * 12  __ZN12KWQKHTMLPart9mouseDownEP7NSEvent (in WebCore)
 * 13  -[NSWindow sendEvent:] (in AppKit)
*/
@interface WebHTMLView (ESWebHTMLViewCrashFix)

- (float)_destinationFloatValueForScroller:(NSScroller *)inScroller
{
	//Wonder if we can figure out what to actually return here.
	return 0;
}

@end
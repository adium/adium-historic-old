//
//  ESWebFrameViewAdditions.h
//  Adium XCode
//
//  Created by Evan Schoenberg on Fri Mar 05 2004.

#import <WebKit/WebKit.h>

@interface WebCoreScrollView:NSScrollView
{
}

- (void)scrollWheel:fp8;

@end

@protocol WebCoreFrameView
- (void)setScrollBarsSuppressed:(char)fp8 repaintOnUnsuppress:(char)fp12;
- (int)verticalScrollingMode;
- (int)horizontalScrollingMode;
- (void)setScrollingMode:(int)fp8;
- (void)setVerticalScrollingMode:(int)fp8;
- (void)setHorizontalScrollingMode:(int)fp8;
@end

@interface WebDynamicScrollBarsView:WebCoreScrollView <WebCoreFrameView>
{
    int hScroll;
    int vScroll;
    char suppressLayout;
    char suppressScrollers;
    char inUpdateScrollers;
}

- (void)setSuppressLayout:(char)fp8;
- (void)setScrollBarsSuppressed:(char)fp8 repaintOnUnsuppress:(char)fp12;
- (void)updateScrollers;
- (void)reflectScrolledClipView:fp8;
- (void)setAllowsScrolling:(char)fp8;
- (char)allowsScrolling;
- (void)setAllowsHorizontalScrolling:(char)fp8;
- (void)setAllowsVerticalScrolling:(char)fp8;
- (char)allowsHorizontalScrolling;
- (char)allowsVerticalScrolling;
- (int)horizontalScrollingMode;
- (int)verticalScrollingMode;
- (void)setHorizontalScrollingMode:(int)fp8;
- (void)setVerticalScrollingMode:(int)fp8;
- (void)setScrollingMode:(int)fp8;

@end

@interface WebFrameViewPrivate:NSObject
{
    WebView *webView;
    WebDynamicScrollBarsView *frameScrollView;
    int marginWidth;
    int marginHeight;
    NSArray *draggingTypes;
    char hasBorder;
}

- init;
- (void)dealloc;

@end

@interface WebFrameView (ESWebFrameViewAdditions)
- (void)setAllowsHorizontalScrolling:(BOOL)inAllow;
@end

@interface WebFrameViewPrivate (ESWebFrameViewPrivateHack)
- (WebDynamicScrollBarsView *)frameScrollView;
@end

//
//  ESWebFrameViewAdditions.h
//  Adium
//
//  Created by Evan Schoenberg on Wed Mar 10 2004.

#import <WebKit/WebKit.h>

@interface NSScrollView (NSScrollViewWebKitPrivate)
- (void) setAllowsHorizontalScrolling:(BOOL) allow;
@end

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


@interface WebHTMLView:NSView <WebDocumentView, WebDocumentSearching, WebDocumentText>
{
    id  _private;
}

+ (void)initialize;
- initWithFrame:(struct _NSRect)fp8;
- (void)dealloc;
- (char)hasSelection;
- (void)takeFindStringFromSelection:fp8;
- (void)copy:fp8;
- (char)writeSelectionToPasteboard:fp8 types:fp12;
- (void)selectAll:fp8;
- (void)jumpToSelection:fp8;
- (char)validateUserInterfaceItem:fp8;
- validRequestorForSendType:fp8 returnType:fp12;
- (char)acceptsFirstResponder;
- (void)updateTextBackgroundColor;
- (void)addMouseMovedObserver;
- (void)removeMouseMovedObserver;
- (void)updateFocusRing;
- (void)addSuperviewObservers;
- (void)removeSuperviewObservers;
- (void)addWindowObservers;
- (void)removeWindowObservers;
- (void)viewWillMoveToSuperview:fp8;
- (void)viewDidMoveToSuperview;
- (void)viewWillMoveToWindow:fp8;
- (void)viewDidMoveToWindow;
- (void)viewWillMoveToHostWindow:fp8;
- (void)viewDidMoveToHostWindow;
- (void)addSubview:fp8;
- (void)reapplyStyles;
- (void)layoutToMinimumPageWidth:(float)fp8 maximumPageWidth:(float)fp12 adjustingViewSize:(char)fp16;
- (void)layout;
- menuForEvent:fp8;
- (char)searchFor:fp8 direction:(char)fp12 caseSensitive:(char)fp16 wrap:(char)fp20;
- string;
- attributedString;
- selectedString;
- selectedAttributedString;
- (void)selectAll;
- (void)deselectAll;
- (void)deselectText;
- (char)isOpaque;
- (void)setNeedsDisplay:(char)fp8;
- (void)setNeedsLayout:(char)fp8;
- (void)setNeedsToApplyStyles:(char)fp8;
- (void)drawRect:(struct _NSRect)fp8;
- (struct _NSRect)visibleRect;
- (char)isFlipped;
- (void)windowDidBecomeKey:fp8;
- (void)windowDidResignKey:fp8;
- (void)windowWillClose:fp8;
- (char)_isSelectionEvent:fp8;
- (char)acceptsFirstMouse:fp8;
- (char)shouldDelayWindowOrderingForEvent:fp8;
- (void)mouseDown:fp8;
- (void)dragImage:fp8 at:(struct _NSPoint)fp12 offset:(struct _NSSize)fp20 event:fp28 pasteboard:fp32 source:fp36 slideBack:(char)fp40;
- (void)mouseDragged:fp8;
- (unsigned int)draggingSourceOperationMaskForLocal:(char)fp8;
- (void)draggedImage:fp8 endedAt:(struct _NSPoint)fp12 operation:(unsigned int)fp20;
- namesOfPromisedFilesDroppedAtDestination:fp8;
- (void)mouseUp:fp8;
- (void)mouseMovedNotification:fp8;
- (char)supportsTextEncoding;
- nextKeyView;
- previousKeyView;
- nextValidKeyView;
- previousValidKeyView;
- (char)becomeFirstResponder;
- (char)resignFirstResponder;
- (void)setDataSource:fp8;
- (void)dataSourceUpdated:fp8;
- (void)_setPrinting:(char)fp8 minimumPageWidth:(float)fp12 maximumPageWidth:(float)fp16 adjustViewSize:(char)fp20;
- (void)adjustPageHeightNew:(float *)fp8 top:(float)fp12 bottom:(float)fp16 limit:(float)fp20;
- (float)_availablePaperWidthForPrintOperation:fp8;
- (float)_userScaleFactorForPrintOperation:fp8;
- (float)_scaleFactorForPrintOperation:fp8;
- (float)_provideTotalScaleFactorForPrintOperation:fp8;
- (char)knowsPageRange:(struct _NSRange *)fp8;
- (struct _NSRect)rectForPage:(int)fp8;
- (float)_calculatePrintHeight;
- (void)endDocument;
- (void)_updateTextSizeMultiplier;
- (void)keyDown:fp8;
- (void)keyUp:fp8;
- accessibilityAttributeValue:fp8;
- accessibilityHitTest:(struct _NSPoint)fp8;

@end

@protocol WebPluginContainer <NSObject>
- (void)showStatus:fp8;
- (void)showURL:fp8 inFrame:fp12;
@end

@interface WebPluginController:NSObject <WebPluginContainer>
{
    id				_HTMLView;
    NSMutableArray *_views;
    char _started;
}

- initWithHTMLView:fp8;
- (void)startAllPlugins;
- (void)stopAllPlugins;
- (void)addPlugin:fp8;
- (void)destroyAllPlugins;
- (void)showURL:fp8 inFrame:fp12;
- (void)showStatus:fp8;

@end


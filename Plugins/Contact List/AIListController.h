//
//  AIListController.h
//  Adium
//
//  Created by Evan Schoenberg on 9/9/04.

@class AIAbstractListController;

@interface AIListController : AIAbstractListController <AIListObjectObserver> {
	
    NSSize								minWindowSize;
    BOOL								autoResizeVertically;
    BOOL								autoResizeHorizontally;
	int									maxWindowWidth;
	int									forcedWindowWidth;

	BOOL 								dockToBottomOfScreen;
	
	BOOL								needsAutoResize;
}

- (void)contactListDesiredSizeChanged;

- (void)setMinWindowSize:(NSSize)inSize;
- (void)setMaxWindowWidth:(int)inWidth;
- (void)setAutoresizeHorizontally:(BOOL)flag;
- (void)setAutoresizeVertically:(BOOL)flag;
- (void)setForcedWindowWidth:(int)inWidth;

@end

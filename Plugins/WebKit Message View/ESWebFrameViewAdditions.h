//
//  ESWebFrameViewAdditions.h
//  Adium
//
//  Created by Evan Schoenberg on Fri Mar 05 2004.

#import "WebKitPrivateDefinitions.h"
/*


@interface WebFrameView (ESWebFrameViewAdditions)
- (WebDynamicScrollBarsView *)frameScrollView;
@end

@interface WebFrameViewPrivate (ESWebFrameViewPrivateHack)
- (WebDynamicScrollBarsView *)frameScrollView;
@end

*/

@interface ESWebFrameView : WebFrameView {
	id		draggingDelegate;
	BOOL	allowDragAndDrop;
}

- (void)setAllowDragAndDrop:(BOOL)flag;

@end

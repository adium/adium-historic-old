//
//  ESWebView.h
//  Adium
//
//  Created by Evan Schoenberg on Wed Mar 10 2004.
//

#import "WebKitPrivateDefinitions.h"

@interface ESWebView : WebView {
	id		draggingDelegate;
	BOOL	allowsDragAndDrop;
}

- (void)setFontFamily:(NSString *)familyName;
- (NSString *)fontFamily;
- (void)setDraggingDelegate:(id)inDelegate;

- (void)setAllowsDragAndDrop:(BOOL)flag;

@end

//
//  ESWebView.h
//  Adium
//
//  Created by Evan Schoenberg on Wed Mar 10 2004.
//

#import "WebKitPrivateDefinitions.h"

@interface ESWebView : WebView {
	id draggingDelegate;
}

- (void)setFontFamily:(NSString *)familyName;
- (NSString *)fontFamily;
- (void)setDraggingDelegate:(id)inDelegate;

@end

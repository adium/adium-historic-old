//
//  ESWebView.h
//  Adium
//
//  Created by Evan Schoenberg on Wed Mar 10 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

#import "WebKitPrivateDefinitions.h"

@interface ESWebView : WebView {
	id		draggingDelegate;
	BOOL	allowsDragAndDrop;
	BOOL	shouldForwardEvents;
}

- (void)setFontFamily:(NSString *)familyName;
- (NSString *)fontFamily;
- (void)setDraggingDelegate:(id)inDelegate;

- (void)setAllowsDragAndDrop:(BOOL)flag;
- (void)setShouldForwardEvents:(BOOL)flag;

@end

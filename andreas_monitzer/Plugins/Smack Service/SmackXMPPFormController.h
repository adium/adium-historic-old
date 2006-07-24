//
//  SmackXMPPFormController.h
//  Adium
//
//  Created by Andreas Monitzer on 2006-07-04.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebView.h>

@class SmackXForm;

@interface SmackXMPPFormController : NSObject {
    IBOutlet NSWindow *window;
    IBOutlet WebView *webview;
    
    id target;
    NSString *selector;
    
    SmackXForm *resultForm;
    
    BOOL wasSubmitted;
}

- (id)initWithForm:(SmackXForm*)form target:(id)t selector:(SEL)s webView:(WebView*)wv;

- (SmackXForm*)resultForm;

@end

//
//  JSCEventBezelController.h
//  Adium XCode
//
//  Created by Jorge Salvador Caffarena.
//  Copyright (c) 2003 All rights reserved.
//

#import "JSCEventBezelWindow.h"
#import "JSCEventBezelView.h"

@interface JSCEventBezelController : NSWindowController {
    IBOutlet JSCEventBezelWindow *bezelWindow;
    IBOutlet JSCEventBezelView *bezelView;
    AIAdium *owner;
}

+ (JSCEventBezelController *)eventBezelControllerForOwner:(id)inOwner;

- (void)showBezelWithContact:(NSString *)contactName
withImage:(NSImage *)buddyIcon
forEvent:(NSString *)event
withMessage:(NSString *)message
atPosition:(int)position;

@end

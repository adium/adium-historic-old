//
//  AIAutoScrollView.h
//  Adium
//
//  Created by Adam Iser on Sun Apr 20 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AIAutoScrollView : NSScrollView {
//    BOOL	autoScroll;
    NSRect	oldDocumentFrame;
}

- (void)scrollToBottom;

@end

//
//  AILinkTextView.h
//  Adium
//
//  Created by Adam Iser on Sun Apr 20 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AILinkTrackingController;

@interface AILinkTextView : NSTextView {
    AILinkTrackingController		*linkTrackingController;

}

@end

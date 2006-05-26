//
//  AIXtraPreviewImageController.h
//  Adium
//
//  Created by David Smith on 3/6/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AIXtraPreviewController.h"

@interface AIXtraPreviewImageController : NSObject <AIXtraPreviewController> {
	IBOutlet NSImageView *previewView;
}

@end

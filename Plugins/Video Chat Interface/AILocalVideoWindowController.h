//
//  AILocalVideoWindowController.h
//  Adium
//
//  Created by Adam Iser on 12/5/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AIVideoCapture;

@interface AILocalVideoWindowController : AIWindowController {
	IBOutlet	NSImageView		*videoImageView;
	AIVideoCapture				*localVideo;
}

@end

//
//  AILocalVideoWindowController.h
//  Adium
//
//  Created by Adam Iser on 12/5/04.
//

#import <Cocoa/Cocoa.h>

@class AIVideoCapture;

@interface AILocalVideoWindowController : AIWindowController {
	IBOutlet	NSImageView		*videoImageView;
	AIVideoCapture				*localVideo;
}

+ (void)showLocalVideoWindow;

@end

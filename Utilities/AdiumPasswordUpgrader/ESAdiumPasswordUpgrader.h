//
//  ESAdiumPasswordUpgrader.h
//  AdiumPasswordUpgrader
//
//  Created by Evan Schoenberg on 1/9/05.
//  Copyright 2005 The Adium Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ESAdiumPasswordUpgrader : NSObject {
	IBOutlet	NSProgressIndicator	*progressBar;
	IBOutlet	NSTextField			*text;
}

- (IBAction)upgrade:(id)sender;
- (IBAction)help:(id)sender;

@end

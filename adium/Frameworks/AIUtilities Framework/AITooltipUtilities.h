//
//  AITooltipUtilities.h
//  Adium
//
//  Created by Adam Iser on Thu Apr 10 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AITooltipUtilities : NSObject {

}
+ (void)showTooltipWithString:(NSString *)inString onWindow:(NSWindow *)inWindow atPoint:(NSPoint)inPoint;

@end

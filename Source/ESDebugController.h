//
//  ESDebugController.h
//  Adium
//
//  Created by Evan Schoenberg on 9/27/04.
//

#import <Cocoa/Cocoa.h>

@interface ESDebugController : NSObject {
	IBOutlet	AIAdium		*owner;
}

- (void)initController;
- (void)adiumDebug:(NSString *)message, ...;
- (NSArray *)debugLogArray;

@end

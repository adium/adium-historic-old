//
//  ESApplescriptabilityController.h
//  Adium
//
//  Created by Evan Schoenberg on Sat Jul 24 2004.
//

#import <Foundation/Foundation.h>

@interface ESApplescriptabilityController : NSObject {
    IBOutlet	AIAdium			*adium;

}

//Private
- (void)initController;
- (void)closeController;

@end

//
//  ESApplescriptabilityController.h
//  Adium
//
//  Created by Evan Schoenberg on Sat Jul 24 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ESApplescriptabilityController : NSObject {
    IBOutlet	AIAdium			*adium;

}

//Private
- (void)initController;
- (void)closeController;

@end

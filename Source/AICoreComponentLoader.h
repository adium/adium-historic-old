//
//  AIComponentLoader.h
//  Adium
//
//  Created by Adam Iser on 10/30/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AICoreComponentLoader : NSObject {
	NSMutableArray	*components;
}

- (void)initController;
- (void)closeController;

@end
//
//  AIExtendedStatusPlugin.h
//  Adium
//
//  Created by Adam Iser on 9/7/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol AIListObjectObserver;

@interface AIExtendedStatusPlugin : AIPlugin <AIListObjectObserver> {

}

- (NSString *)idleStringForSeconds:(int)seconds;

@end

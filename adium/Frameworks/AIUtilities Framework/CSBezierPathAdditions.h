//
//  CSBezierPathAdditions.h
//  Adium
//
//  Created by Chris Serino on Sun Oct 12 2003.
//  Copyright (c) 2003 The Adium Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSBezierPath (CSBezierPathAdditions) 

+ (NSBezierPath *)bezierPathWithRoundedRect:(NSRect)rect radius:(float)radius;

@end

/*
 *  ViewController.h
 *  XtrasCreator
 *
 *  Created by David Smith on 10/27/05.
 *  Copyright 2005 Adium Team. All rights reserved.
 *
 */
#import <Cocoa/Cocoa.h>

@protocol ViewController <NSObject>
- (NSView *) view;
- (void) writeCustomFilesToPath:(NSString *)path;
+ (id<ViewController>) controller;
@end
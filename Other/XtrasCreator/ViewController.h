/*
 *  ViewController.h
 *  XtrasCreator
 *
 *  Created by David Smith on 10/27/05.
 *  Copyright 2005 __MyCompanyName__. All rights reserved.
 *
 */

@class NSView, NSString;

@protocol ViewController
- (NSView *) view;
- (void) writeCustomFilesToPath:(NSString *)path;
+ (id<ViewController>) controller;
@end
/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import <Cocoa/Cocoa.h>
#import <Adium/Adium.h>
#import <WebKit/WebKit.h>

@class AIWebKitMessageViewController;

/*
 This class should be used to "vend" methods to javascript in the chat view. They will be accessed by adium.methodName(args) in js. See http://developer.apple.com/documentation/AppleApplications/Conceptual/SafariJSProgTopics/Tasks/ObjCFromJavaScript.html#//apple_ref/doc/uid/30001215 for more information.
 */

@interface AIWebKitJSBridge : AIObject {
	AIWebKitMessageViewController *controller;
}

+ (AIWebKitJSBridge *) bridgeWithController:(AIWebKitMessageViewController *)c;
- (id) initWithController:(AIWebKitMessageViewController *)c;

@end

//
//  AIApplication.m
//  Adium
//
//  Created by Evan Schoenberg on 7/6/06.
//

#import "AIApplication.h"
#import <Adium/AIObject.h>
#import <Adium/AIDockControllerProtocol.h>

@implementation AIApplication
/*!
 * @brief Intercept applicationIconImage so we can return a base application icon
 *
 * The base application icon doesn't have any badges, labels, or animation states.
 */
- (NSImage *)applicationIconImage
{
	NSImage *applicationIconImage = [[[AIObject sharedAdiumInstance] dockController] baseApplicationIconImage];

	return (applicationIconImage ? applicationIconImage : [super applicationIconImage]);
}

@end

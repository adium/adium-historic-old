//
//  CBObjectAdditions.m
//  Adium
//
//  Created by Colin Barrett on Mon Sep 22 2003.
//

#import "CBObjectAdditions.h"

/* 
 * this wonderful little thing is the creation of Mulle kybernetiK.
 * the awesome page I found this on is here: 
 * http://www.mulle-kybernetik.com/artikel/Optimization/
 * Happy landings! --chb 9/22/03
 */

@implementation NSObject (HashingAdditions)

- (unsigned int) hash
{
   return( ((unsigned int) self >> 4) | (unsigned int) self << (32 - 4));
}

@end

// Clever addition by Jonathan Jansson found on cocoadev.com (http://www.cocoadev.com/index.pl?ThreadCommunication)
@implementation NSObject (RunLoopMessenger)

- (void)mainPerformSelector:(SEL)aSelector
{
	[self performSelectorOnMainThread:aSelector withObject:nil waitUntilDone:NO];
}

- (void)mainPerformSelector:(SEL)aSelector withObject:(id)argument1
{
	[self performSelectorOnMainThread:aSelector withObject:argument1 waitUntilDone:NO];
}

- (void)mainPerformSelector:(SEL)aSelector withObject:(id)argument1 withObject:(id)argument2
{
	NSInvocation *invocation;
	invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:aSelector]];
	
	[invocation setSelector:aSelector];
	[invocation setArgument:&argument1 atIndex:2];
	[invocation setArgument:&argument2 atIndex:3];
	[invocation retainArguments];
	
	[self performSelectorOnMainThread:@selector(handleInvocation:) withObject:invocation waitUntilDone:NO];
}

- (void)mainPerformSelector:(SEL)aSelector withObject:(id)argument1 withObject:(id)argument2 withObject:(id)argument3
{
	NSInvocation *invocation;
	invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:aSelector]];
	
	[invocation setSelector:aSelector];
	[invocation setArgument:&argument1 atIndex:2];
	[invocation setArgument:&argument2 atIndex:3];
	[invocation setArgument:&argument3 atIndex:4];
	[invocation retainArguments];
	
	[self performSelectorOnMainThread:@selector(handleInvocation:) withObject:invocation waitUntilDone:NO];
}

- (void)handleInvocation:(NSInvocation *)anInvocation
{
	[anInvocation invokeWithTarget:self];
}

@end

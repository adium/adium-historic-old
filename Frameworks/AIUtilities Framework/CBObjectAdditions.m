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

//Included to allow uniform coding
- (void)mainPerformSelector:(SEL)aSelector
{
	[self mainPerformSelector:aSelector waitUntilDone:NO];
}
//Included to allow uniform coding - wrapped for performSelectorOnMainThread:withObject:waitUntilDone:
- (void)mainPerformSelector:(SEL)aSelector waitUntilDone:(BOOL)flag
{
	[self performSelectorOnMainThread:aSelector withObject:nil waitUntilDone:flag];
}

//Included to allow uniform coding
- (void)mainPerformSelector:(SEL)aSelector withObject:(id)argument1
{
	[self mainPerformSelector:aSelector withObject:argument1 waitUntilDone:NO];
}

//Included to allow uniform coding - wrapped for performSelectorOnMainThread:withObject:waitUntilDone:
- (void)mainPerformSelector:(SEL)aSelector withObject:(id)argument1 waitUntilDone:(BOOL)flag
{
	[self performSelectorOnMainThread:aSelector withObject:argument1 waitUntilDone:flag];
}

- (id)mainPerformSelector:(SEL)aSelector returnValue:(BOOL)flag
{
	id returnValue;
	
	if (flag){
		NSInvocation *invocation;
		
		invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:aSelector]];
		[invocation setSelector:aSelector];
		
		[self performSelectorOnMainThread:@selector(handleInvocation:)
							   withObject:invocation
							waitUntilDone:YES];
		
		[invocation getReturnValue:&returnValue];
		
	}else{
		returnValue = nil;
		[self performSelectorOnMainThread:aSelector waitUntilDone:NO];
	}	
}

//Perform a selector on the main thread, optionally taking an argument, and return its return value
- (id)mainPerformSelector:(SEL)aSelector withObject:(id)argument1 returnValue:(BOOL)flag
{
	id returnValue;
	
	if (flag){
		NSInvocation *invocation;
		
		invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:aSelector]];
		[invocation setSelector:aSelector];
		[invocation setArgument:&argument1 atIndex:2];
		
		[self performSelectorOnMainThread:@selector(handleInvocation:)
							   withObject:invocation
							waitUntilDone:YES];

		[invocation getReturnValue:&returnValue];
		
	}else{
		returnValue = nil;
		[self performSelectorOnMainThread:aSelector withObject:argument1 waitUntilDone:NO];
	}
	
	return(returnValue);
}


- (void)mainPerformSelector:(SEL)aSelector withObject:(id)argument1 withObject:(id)argument2
{
	[self mainPerformSelector:aSelector withObject:argument1 withObject:argument2 waitUntilDone:NO];
}
- (void)mainPerformSelector:(SEL)aSelector withObject:(id)argument1 withObject:(id)argument2 waitUntilDone:(BOOL)flag
{
	NSInvocation *invocation;
	invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:aSelector]];
	
	[invocation setSelector:aSelector];
	[invocation setArgument:&argument1 atIndex:2];
	[invocation setArgument:&argument2 atIndex:3];
	[invocation retainArguments];
	
	[self performSelectorOnMainThread:@selector(handleInvocation:) withObject:invocation waitUntilDone:flag];
}

- (void)mainPerformSelector:(SEL)aSelector withObject:(id)argument1 withObject:(id)argument2 withObject:(id)argument3 
{
	[self mainPerformSelector:aSelector withObject:argument1 withObject:argument2 withObject:argument3 waitUntilDone:NO];
}
- (void)mainPerformSelector:(SEL)aSelector withObject:(id)argument1 withObject:(id)argument2 withObject:(id)argument3 waitUntilDone:(BOOL)flag
{
	NSInvocation *invocation;
	invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:aSelector]];
	
	[invocation setSelector:aSelector];
	[invocation setArgument:&argument1 atIndex:2];
	[invocation setArgument:&argument2 atIndex:3];
	[invocation setArgument:&argument3 atIndex:4];
	[invocation retainArguments];
	
	[self performSelectorOnMainThread:@selector(handleInvocation:) withObject:invocation waitUntilDone:flag];
}

- (void)performSelector:(SEL)aSelector withObject:(id)argument1 withObject:(id)argument2 afterDelay:(NSTimeInterval)delay
{
	NSInvocation *invocation;
	invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:aSelector]];
	
	[invocation setSelector:aSelector];
	[invocation setArgument:&argument1 atIndex:2];
	[invocation setArgument:&argument2 atIndex:3];
	[invocation retainArguments];
	
	[self performSelector:@selector(handleInvocation:) withObject:invocation afterDelay:delay];	
}

- (void)handleInvocation:(NSInvocation *)anInvocation
{
	[anInvocation invokeWithTarget:self];
}

@end

//
//  CBObjectAdditions.h
//  Adium
//
//  Created by Colin Barrett on Mon Sep 22 2003.
//

@interface NSObject (HashingAdditions)
- (unsigned int)hash;
@end

@interface NSObject (RunLoopMessenger)
- (void)mainPerformSelector:(SEL)aSelector;
- (void)mainPerformSelector:(SEL)aSelector withObject:(id)argument1;
- (void)mainPerformSelector:(SEL)aSelector withObject:(id)argument1 withObject:(id)argument2;
- (void)mainPerformSelector:(SEL)aSelector withObject:(id)argument1 withObject:(id)argument2 withObject:(id)argument3;
- (void)handleInvocation:(NSInvocation *)anInvocation;
@end

//
//  NSObjectHOMAdditions.h
//  HigherOrderMessaging
//
//  Created by Ofri Wolfus on 10/09/05.
//  Copyright 2005 Ofri Wolfus. All rights reserved.
//

#import <HigherOrderMessaging/Message.h>


@interface NSObject (NewHOM)

/*!
 * @abstract Peforms the passed message and returns the result(s) (if it's an object) or the receiver.
 * @discussion This method accepts messages with iterated arguments returned from the -each method.
 * If iterated arguments are passed with the message, and the message returns an object, an array with all the results will be returned.
 * This method is an equivalent to <code>repeatOf:message for:1</code>.
 * You can use this method as an alternative to <code>-ifResponds</code> as long as the return type of the message is <code>id</code>.
 * If the return type is not <code>id</code>, <code>nil</code> will be returned but the message will still be sent. 
 */
- (id)do:(Message *)message;

/*!
 * @abstract Peforms the passed message x times, and returns the result(s) (if it's an object) or the receiver.
 * @discussion This method accepts messages with iterated arguments returned from the -each method.
 * If iterated arguments are passed with the message, and the message returns an object, an array with all the results will be returned.
 * The results of all messages sent during the execution of this method will be returned in a single array (only if the return type is <code>id</code>).
 * This method is specifically useful when allocating a bunch of instances at once, e.g. <code>NSArray *uninitializedStrings = [NSString repeatOf:MSG(alloc) for:5];</code>,
 * or combined with the -collect method to get an array of fully initialized instances: <code>NSArray *strings = [[NSString repeatOf:MSG(alloc) for:5] collect:MSG(initWithString:@"Hello")];</code>
 * This method is an equivalent to <code>for:NULL from:0 to:1 do:msg</code>.
 * @param xTimes The number of times the receiver will process the message.
 */
- (id)repeatOf:(Message *)msg for:(int)xTimes;

/*!
 * @abstract Peforms the passed message x times, and returns the result(s) (if it's an object) or the receiver.
 * @discussion This method is an extended version of the -repeatOf:for: method that allows you to use the counter of the iteration in your message.
 * Example: <code>int i;
	NSArray *values = [NSValue for:&i from:-10 to:10 do:MSG(valueWithBytes:&i objCType:@encode(int))];</code>
 * In the example above, the value of <code>i</code> will be set to -10, and increased (up to 9) before each execution of the passed message.
 * Pass in <code>NULL</code> as the counter to ignore it.
 */
- (id)for:(int *)counter from:(int)start to:(int)end do:(Message *)message;

/*!
 * @abstract Performs the passed message only if the receiver responds to it, and returns the result.
 * @discussion If the receiver doesn't respond to the passed message, <code>nil</code> will be returned.
 */
- (id)receive:(Message *)msg;

@end

/*!
 * @category NSObject (HOM)
 * @abstract Provides a basic HOM functionality for all objects.
 * @discussion This category is deprecated and will be removed in the final version.
 */
@interface NSObject (HOM)

/*!
 * @abstract Sends the argument message only if the receiver reponds to it.
 * @discussion Instead of writing <code>if ([receiver respondsToSelector:@selector(blah)]) [receiver blah];</code>, simply use <code>[[receiver ifResponds] blah]</code>.
 * This makes the code cleaner and easier to read.
 * The result of this method is the result of the argument message. If the receiver doesn't respond to the passed message, the return value is undefined.
 */
- (id)ifResponds;

/*!
 * @method do
 * @abstract Performs the argument message in a new thread.
 * @discussion Detaches a new thread, sets up an autorelease pool, and then performs the argument message.
 * @result Returns the receiver (self).
 */
- (id)async;

/*!
 * @method mainPerformAndWait:
 * @abstract Performs the argument message in the main thread.
 * @discussion Instead of calling performSelectorOnMainThread:withObject:waitUntilDone: this HOM allows you to do the same, but with as many argument you wish.
 */
- (id)mainPerformAndWait:(BOOL)waitUntilDone;

/*!
 * @method mainPerform
 * @abstract Does the same as -mainPerformAndWait: but without waiting.
 */
- (id)mainPerform;

/*!
 * @method invocationFrom
 * @abstract Returns the argument message as an NSInvocation instance.
 */
- (id)invocationFrom;

/*!
 * @method ifNotNil
 * @abstract Performs the prefix message only if all its arguments are not nil.
 */
- (id)ifNotNil;

@end

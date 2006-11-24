//
//  NSArrayHOMAdditions.h
//  HigherOrderMessaging
//
//  Created by Ofri Wolfus on 24/09/05.
//  Copyright 2005 Ofri Wolfus. All rights reserved.
//

#import <Foundation/NSArray.h>
#import <HigherOrderMessaging/Message.h>


@interface NSArray (HOMIteration)

/*!
 * @abstract Sends the passed message to each of the receiver's objects, and returns the results.
 * @discussion This respects and processes iterated arguments in the passed message.
 * If the return value of the message is not an object or a class, the result is undefined.
 * @result An array with all the results or <code>nil</code> if the receiver contains no objects.
 */
- (id)collect:(Message *)argumentMessage;

/*!
 * @abstract Returns all objects that returned <code>YES</code> to the last message passed.
 * @discussion Messages are sent one by one in the order in which they were passed.
 * Each message is sent to the result of the message before it, while the first message is sent to an object in the receiver.
 * The return value of the last message is assumed to be <code>BOOL</code>. If it's not, the result is undefined.
 * All other messages must return an object or a class, otherwise the result is undefined.
 * The passed messages list must be <code>nil<code> terminated.
 * @result An array with all objects that returned <code>YES</code> for the last message, or <code>nil</code> if none was found.
 */
- (id)selectWhere:(Message *)firstMessage, ...;

/*!
 * @abstract Returns all objects that returned <code>NO</code> to the last message passed.
 * @discussion Messages are sent one by one in the order in which they were passed.
 * Each message is sent to the result of the message before it, while the first message is sent to an object in the receiver.
 * The return value of the last message is assumed to be <code>BOOL</code>. If it's not, the result is undefined.
 * All other messages must return an object or a class, otherwise the result is undefined.
 * The passed messages list must be <code>nil<code> terminated.
 * @result An array with all objects that returned <code>NO</code> for the last message, or <code>nil</code> if none was found.
 */
- (id)rejectWhere:(Message *)firstMessage, ...;

/*!
 * @abstract Finds a single object that returns <code>YES</code> to the last message passed.
 * @discussion This method is identical to <code>-selectWhere:</code> except it returns a single object or <code>nil</code> if none was found.
 */
- (id)selectSingleWhere:(Message *)firstMessage, ...;

/*!
 * @abstract Finds a single object that returns <code>NO</code> to the last message passed.
 * @discussion This method is identical to <code>-rejectWhere:</code> except it returns a single object or <code>nil</code> if none was found.
 */
- (id)rejectSingleWhere:(Message *)firstMessage, ...;

/*!
 * @method each
 * @abstract Returns an iterated argument for use with other methods that support iterated arguments.
 * @discussion You can also use the returned object to send a message to all objects in the receiver like this:
 * <code>[[myArray each] setString:@"hello"];</code>
 */
- (id)each;

@end

/*!
 * @category NSArray (HOMIteration)
 * @abstract Adds some useful methods to NSArray.
 */
@interface NSArray (HOMAdditions)

/*!
 * @method makeObjectsPerformInvocation:
 * @abstract Sends the message in <code>invocation</code> to each object in the array, starting with the first object and continuing through the array to the last object.
 * @discussion The message shouldn’t have the side effect of modifying the receiving array.
 * This method raises an NSInvalidArgumentException if <code>invocation</code> is nil.
 * The message in <code>invocation</code> will not be sent to objects which can't respond to it.
 */
- (void)makeObjectsPerformInvocation:(NSInvocation *)invocation;

@end


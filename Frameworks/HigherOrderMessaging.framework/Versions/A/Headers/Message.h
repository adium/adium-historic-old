//
//  Message.h
//  HigherOrderMessaging
//
//  Created by Ofri Wolfus on 26/08/06.
//  Copyright 2006 Ofri Wolfus. All rights reserved.
//

#include <objc/objc.h>
#include <objc/objc-class.h>


/*!
 * @abstract A class representing an Objective-C message.
 * @discussion Message instances are created using the MSG() macro.
 * If the NSAutoreleasePool class is available, the MSG() macro returns an autoreleased message instance.
 * If not, you must release it yourself.
 */
@interface Message {
	Class		isa;
	marg_list	args;
	unsigned	refCount;
	unsigned	argsSize;
	char		*_types;
}

/*!
 * @abstract Returns the selector of the receiver.
 */
- (SEL)selector;

/*!
 * @abstract Returns the arguments list of the receiver.
 * @discussion Use this list in conjunction with one of the objc_msgSendv() functions in order to send the message.
 * This method returns the argument list of the receiver and not a copy, so never modify its content!
 */
- (marg_list)arguments;

/*!
 * @abstract Returns the size of the arguments list of the receiver.
 */
- (unsigned)argumentsSize;

/*!
 * @abstract Returns whether the receiver assumes to return a struct or not.
 * @discussion If you know you're goign to send the receiver to an object that'll return a struct and the result of this method is <code>NO</code>,
 * you should allocate a new arguments list with a pointer to a memory for the returned structure at the beginning of it.
 * Then copy the list of the receiver after the pointer of your new list. On the other hand, if you know your object is going to return an integer value,
 * and the result of this method is <code>YES</code>, you must allocate a new arguments list that starts with a pointer to your receiver.
 */
- (BOOL)returnsStruct;

/*!
 * @abstract Returns the number of arguments the receiver has.
 */
- (unsigned)numberOfArguments;

/*!
 * @abstract Increments the receiver’s reference count.
 */
- (id)retain;

/*!
 * @abstract Adds the receiver to the current autorelease pool.
 */
- (id)autorelease;

/*!
 * @abstract Decrements the receiver’s reference count.
 */
- (void)release;

/*!
 * @abstract Returns the receiver’s reference count.
 */
- (unsigned)retainCount;

/*!
 * @abstract A convenient method that for sending the receiver to a given target.
 * @discussion If the receiver returns something other then <code>id</code>, you must use one of the <code>objc_msgSendv()</code> functions to send it.
 */
- (id)sendTo:(id)receiver;

@end

@interface Message (Extensions)
- (const char *)types;
@end


// Private.
extern id _sharedMessageBuilder;

/*!
 * @abstract Returns a Message instance from a given message.
 * @discussion The use of this macro looks like this:
 * <code>Message *msg = MSG(hasPrefix:@"aa");</code>
 * A message object can only be created if the message is known at runtime, meaning at least one class can respond to it.
 * If the message can not be determined, <code>nil</code> will be returned.
 */
#define MSG(X...) ID([_sharedMessageBuilder X])

/*!
 * @abstract Returns a Message instance from a given message.
 * @discussion The use of this macro looks like this:
 * <code>Message *msg = MSGV(insertTabViewItem:atIndex:, someItem, 3);</code>
 * The first argument is the selector of the message (without the @selector() directive), followed by the arguments of the message.
 * A message object can only be created if the message is known at runtime, meaning at least one class can respond to it.
 * If the message can not be determined, <code>nil</code> will be returned.
 */
#define MSGV(sel, ...) objc_msgSend(_sharedMessageBuilder, @selector(sel), __VA_ARGS__)

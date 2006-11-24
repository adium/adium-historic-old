//
//  HOMMacros.h
//  HigherOrderMessaging
//
//  Created by Ofri Wolfus on 23/12/05.
//  Copyright 2005 Ofri Wolfus. All rights reserved.
//


#ifndef _HOM_MACROS
#define _HOM_MACROS

//
//  Platform specific defs for externs
//

//
// For MACH
//

#if defined(__MACH__)

#ifdef __cplusplus
#define HOM_EXTERN		extern "C"
#define HOM_PRIVATE_EXTERN	__private_extern__
#else
#define HOM_EXTERN		extern
#define HOM_PRIVATE_EXTERN	__private_extern__
#endif

//
// For Windows
//

#elif defined(WIN32)

#ifndef _CKBUILDING_HOM_DLL
#define _CKWINDOWS_DLL_GOOP	__declspec(dllimport)
#else
#define _CKWINDOWS_DLL_GOOP	__declspec(dllexport)
#endif

#ifdef __cplusplus
#define HOM_EXTERN		extern "C" _CKWINDOWS_DLL_GOOP
#define HOM_PRIVATE_EXTERN	extern
#else
#define HOM_EXTERN		_CKWINDOWS_DLL_GOOP extern
#define HOM_PRIVATE_EXTERN	extern
#endif

//
//  For Solaris
//

#elif defined(SOLARIS)

#ifdef __cplusplus
#define HOM_EXTERN		extern "C"
#define HOM_PRIVATE_EXTERN	extern "C"
#else
#define HOM_EXTERN		extern
#define HOM_PRIVATE_EXTERN	extern
#endif

#endif

//============================================================================
//================= HigherOrderMessaging With Any Return Type ================
//============================================================================

/*!
 * @defined ID()
 * @abstract Enables any message (or function) to return an object even if the compiler doesn't think it should.
 */
#if defined(__ppc__) || defined(__ppc64__)
#if defined (__ppc64__)
#warning Support for PPC-64 is untested
#endif
// PPC uses r3 for integer return values
#define ID(X...) ({ volatile id __o = nil; X; asm volatile ("stw r3, %0": "=m" (__o)); __o; })

#elif defined(__i386__)
// i386 returns integer values in %eax
#define ID(X...) ({ volatile id __o = nil; X; asm volatile ("mov %%eax, %0": "=m" (__o)); __o; })

#elif defined(__x86_64__)
#warning Support for x86-64 is untested
// According to the x86-64 ABI, integer return values are returned using the next available register of the
// sequence %rax, %rdx, so this may not be the right register.
// I'd really appreciate comments about this from someone with more knowledge in the subject.
#define ID(X...) ({ volatile id __o = nil; X; asm volatile ("mov %%rax, %0": "=m" (__o)); __o; })

#else
#error Unknown Architecture
#endif


//============================================================================
//================== Static Typing Of Higher Order Messages ==================
//============================================================================

/***************************************************************************************
 ***************************************************************************************
 *                                                                                     *
 * WARNING: The macros defined in this secion are obsolate and will be removed         *
 * in a future version! Use the ID() macro instead.                                    *
 *                                                                                     *
 ***************************************************************************************
 ***************************************************************************************/

/*
 * NOTE: Generally, you won't need to use the macros defined in this section, as the HOM() macro is much cleaner.
 */

/*!
 * @defined HOMEnableArgumentMessageCompatibility()
 * @abstract Lets the compiler know that a message that returns something that can't be cast to id, can be used as an argument message.
 * @discussion Higher Order Messaging relys on dynamic typing but except for messages sent to statically typed receivers, dynamic binding requires all implementations of identically named methods to have the same return type and the same argument types.
 * In most cases, this will simply generate a warning, but in some cases like <code>-floatValue</code> the code will fail to compile with an incompatible types error.
 * In order to avoid this, <code>HOMEnableArgumentMessageWithArgsCompatibility()</code> allows you to let the compiler know that a message can be safely used as an argument message even if it returns a type that can't be cast to id.
 * You must call <code>HOMEnableArgumentMessageWithArgsCompatibility()</code> inside your implementation file, before your @implementation block.
 * <code>HOMEnableArgumentMessageWithArgsCompatibility()</code> can safely be used in more then one implementation file.
 * @param method The entire method declaration without the return type. eg. getInputStream:(NSInputStream **)inputStream outputStream:(NSOutputStream **)outputStream.
 * @param identifier A dummy c identifier. The identifier should be uniqe for each call to <code>HOMEnableArgumentMessageWithArgsCompatibility()</code> in the same file. 
 */
#define HOMEnableArgumentMessageWithArgsCompatibility(method, identifier)\
@interface HOMTrampoline (identifier)\
- (id)method;\
@end

/*!
 * @defined HOMEnableArgumentMessageCompatibility()
 * @abstract A convenient macro for methods that takes no arguments.
 * <code>HOMEnableArgumentMessageCompatibility()</code> simply calls <code>HOMEnableArgumentMessageWithArgsCompatibility()</code> with the name of the method as the identifier.
 */
#define HOMEnableArgumentMessageCompatibility(method)	HOMEnableArgumentMessageWithArgsCompatibility(method, method)


/*!
 * @defined HOMStaticMessageSend()
 * @abstract Sends a Higher Order Message as a statically typed message.
 * <code>HOMEnableArgumentMessageWithArgsCompatibility()</code> must first be called with the argument message before you can call <code>HOMStaticMessageSend()</code>.
 * @discussion To complete <code>HOMEnableArgumentMessageWithArgsCompatibility()</code>, <code>HOMStaticMessageSend()</code> is needed.
 * <code>HOMStaticMessageSend()</code> is used to send a statically typed Higher Order Message.
 * See the docs for <code>HOMEnableArgumentMessageWithArgsCompatibility()</code> for more info.
 * @param receiver The receiver of the prefix message.
 * @param prefixMessage The prefix message that will be sent to the receiver.
 * @param argumentMessage The argument message that will be carried with the prefix message.
 * @result The result of the prefix message that was sent.
 */
#define HOMStaticMessageSend(receiver, prefixMessage, argumentMessage) [(HOMTrampoline *)[receiver prefixMessage] argumentMessage]


#endif // _HOM_MACROS

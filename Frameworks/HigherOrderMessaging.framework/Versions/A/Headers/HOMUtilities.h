//
//  HOMUtilities.h
//  HigherOrderMessaging
//
//  Created by Ofri Wolfus on 23/12/05.
//  Copyright 2005 Ofri Wolfus. All rights reserved.
//
//  This file is released under modified BSD license.
//

#import <Foundation/Foundation.h>
#include <objc/objc-class.h>
#include <AvailabilityMacros.h>
#import <HigherOrderMessaging/HOMMacros.h>


/*
 * A macro for class clusters that needs to implement a method that must be overridden by a concrete subclass.
 * This macro must be used within the context of a method. It raises an NSInternalInconsistencyException exception when the method is being called.
 */
#if !defined (DP_SUBCLASS_MUST_IMPLEMENT)
#define DP_SUBCLASS_MUST_IMPLEMENT \
do {\
	[[NSException exceptionWithName:NSInternalInconsistencyException\
							 reason:[NSString stringWithFormat:@"%@'s implementation of %@ was not overridden!",\
								 [self className], NSStringFromSelector(_cmd)]\
						   userInfo:nil] raise];\
} while (0)
// An alternative naming to DP_SUBCLASS_MUST_IMPLEMENT
#if !defined (DPSubclassMustOverride)
#define DPSubclassMustOverride DP_SUBCLASS_MUST_IMPLEMENT
#endif
#endif

@class NSAssertionHandler;

/* Asserts for Objective-C that accepts unlimited number of arguments */
#if !defined(NS_BLOCK_ASSERTIONS) && !defined(DPAssert)
/*
 * The usage of this macro is the same as with NSAssert, exept you don't need DPAssert1, DPAssert2, etc.
 * This macro accepts any number of arguments passed to the description.
 */
#define DPAssert(condition, desc...)\
do {\
	if (!(condition)) {\
		[[NSAssertionHandler currentHandler] handleFailureInMethod:_cmd\
															object:self\
															  file:[NSString stringWithCString:__FILE__] \
														lineNumber:__LINE__\
													   description:desc];\
	}\
} while(0)
#endif


// A nice name for the always_inline attribute, in the style of the attributes macros from AvailabilityMacros.h
#if !defined (ALWAYS_INLINE_ATTRIBUTE)
#define ALWAYS_INLINE_ATTRIBUTE __attribute__((always_inline))
#endif


// End of supported section
#pragma mark -

/*
 * The next section has some stuff that some may find useful, but others will consider as hacks.
 * Be VERY careful when you use stuff from here, and make sure you know what you're doing!
 * Also remember that these stuff may stop working at *ANY* later stage or even completely disappear.
 *
 * With that being said, most people will find the DPSubclassMustOverride and DPAssert() macros useful.
 * Other stuff are useful for people that need close interaction with the Objective-C runtime (which most people don't need).
 */

//These are defined in the GNU runtime but not in Apple's although the characters are the same.
#ifndef _C_CONST
#define _C_CONST		'r'
#endif

#ifndef _C_IN
#define _C_IN			'n'
#endif

#ifndef _C_INOUT
#define _C_INOUT		'N'
#endif

#ifndef _C_OUT
#define _C_OUT			'o'
#endif

#ifndef _C_BYCOPY
#define _C_BYCOPY		'O'
#endif

#ifndef _C_BYREF
#define _C_BYREF		'R'
#endif

#ifndef _C_ONEWAY
#define _C_ONEWAY		'V'
#endif

#ifndef _C_GCINVISIBLE
#define _C_GCINVISIBLE	'!'
#endif

/* Getting runtime info about objects and classes */
#if !defined (_HOM_RUNTIME_INFO_H)
#define _HOM_RUNTIME_INFO_H

/* These macros are private */
#define _CLS_IS_CLASS(cls)              ((((struct objc_class *) cls)->info & CLS_CLASS) != 0)
#define _CLS_IS_META(cls)               ((((struct objc_class *) cls)->info & CLS_META) != 0)
#define _CLS_GET_META(cls)              (CLS_IS_META(cls) ? ((struct objc_class *) cls) : ((struct objc_class *) cls)->isa)
#define _CLS_IS_INITIALIZED(cls)        ((((volatile long)CLS_GET_META(cls)->info) & CLS_INITIALIZED) != 0)
#define _CLS_IS_INITIALIZING(cls)       ((((volatile long)CLS_GET_META(cls)->info) & CLS_INITIALIZING) != 0)

// Returns a class with a given name (c string)
#define HOMGetClass(name)						objc_getClass(name)
// Returns the class of the passed object
#define HOMObjectGetClass(obj)					(obj->isa)
// Sets the class of obj to cls. Be VERY careful with this!
#define HOMObjectSetClass(obj, cls)				(obj->isa = cls)
// Returns whether the passed object is an instance
#define HOMObjectIsInstance(obj)				((obj != nil) && _CLS_IS_CLASS(obj->isa))
// Returns whether the passed object is a class
#define HOMObjectIsClass(obj)					((obj != nil) && _CLS_IS_META(obj->isa))
// Returns the meta class of the given class
#define HOMClassGetMetaClass(cls)				(cls->isa)
// Returns the super class of the given class
#define HOMClassGetSuperclass(cls)				(cls->super_class)
// Returns the version of the passed class
#define HOMClassGetVersion(cls)					class_getVersion(cls)
// Sets the version of a given class
#define HOMClassSetVersion(cls, vers)			class_setVersion(cls, vers)
// Returns whether the passed class is a class or not (it may be a meta class)
#define HOMClassIsClass(cls)					_CLS_IS_CLASS(cls)
// Returns whether the passed class is a meta class
#define HOMClassIsMeta(cls)						_CLS_IS_META(cls)

#endif

//This enum is defined in NSInvocation.h and represents objc types.
//Be careful when you play with it since it's kind of private.
typedef enum _NSObjCValueType HOMObjCType;

//Takes a type (const char*) returned from the @encode() directive,
//and returns the associated HOMObjCType with that type.
HOM_EXTERN HOMObjCType returnTypeForInvocation(const char * type)	DEPRECATED_ATTRIBUTE;

//Takes a type (const char*) returned from the @encode() directive,
//and returns the size of it.
static inline unsigned int hom_sizeOfType(const char * type)	ALWAYS_INLINE_ATTRIBUTE;
static inline unsigned int hom_sizeOfType(const char * type) {
	unsigned int i;
	NSGetSizeAndAlignment(type, &i, NULL);
	return i;
}

//Returns whether object responds to sel
//This does not invoke the -respondsToSelector: method, but digs directly into
//the object structure to find if it really responds to the selector or not.
//This function is useful if you must know whether a proxy really responds to a given selector
//or that is passes it to a different object.
static inline BOOL hom_respondsToSelector(id object, SEL sel)	ALWAYS_INLINE_ATTRIBUTE;
static inline BOOL hom_respondsToSelector(id object, SEL sel) {
	return (!HOMObjectIsClass(object) ? class_getInstanceMethod(object->isa, sel) :
			(class_getClassMethod((Class)object, sel) ?: class_getInstanceMethod(object, sel))) != NULL;
}

//Checks if obj is *really* kind of cls.
//This is useful if you *need* to know whether a proxy is really a proxy since
//it may override -isKindOfClass to its target object.
static inline BOOL hom_isKindOfClass(id obj, Class cls)	ALWAYS_INLINE_ATTRIBUTE;
static inline BOOL hom_isKindOfClass(id obj, Class cls) {
	Class class;
	
	for (class = HOMObjectGetClass(obj); class != Nil; class = HOMClassGetSuperclass(class))
		if (class == cls)
			return YES;
	return NO;
}


//Renames originalSelector instance method of inClass to newSelector.
HOM_EXTERN BOOL hom_renameInstnaceMethod(Class inClass, SEL originalSelector, SEL newSelector);

//Renames originalSelector class method of inClass to newSelector.
HOM_EXTERN BOOL hom_renameClassMethod(Class inClass, SEL originalSelector, SEL newSelector);

//Rplaces the IMP of originalSelector instance method of classOne with the imp of newSelector of classTwo.
//Returns the original IMP of originalSelector.
HOM_EXTERN IMP hom_replaceInstanceIMP(Class classOne, SEL originalSelector, Class classTwo, SEL newSelector);

//Rplaces the IMP of originalSelector class method of classOne with the imp of newSelector of classTwo.
//Returns the original IMP of originalSelector.
HOM_EXTERN IMP hom_replaceClassIMP(Class classOne, SEL originalSelector, Class classTwo, SEL newSelector);


// Returns the number of arguments the passed selector accepts
static inline unsigned hom_getNumberOfArguments(SEL sel)	ALWAYS_INLINE_ATTRIBUTE;
static inline unsigned hom_getNumberOfArguments(SEL sel) {
	unsigned c = 2U;
	char	*name = (char *)sel_getName(sel);
	
	while (*name) {
		if (*name == ':')
			++c;
		++name;
	};
	
	return c;
}

//Returns the return type of the passed method (a new NULL-terminated string).
//You are responsible for freeing it when you're done with it
HOM_EXTERN char * hom_getReturnType(Method m);

// Returnes the type of the argument at a given index.
// If index is 0 based, and if it exceeds the number of arguments, the result is undefined.
HOM_EXTERN const char * hom_getArgumentTypeAtIndex(Method m, unsigned index);

HOM_EXTERN const char * hom_getArgumentFromTypes(const char *types, unsigned index);

// Returnes the type of the argument at a given index.
// If index is 0 based, and if it exceeds the number of arguments, the result is undefined.
// You are responsible for freeing the returned string.
HOM_EXTERN char *hom_copyArgumentTypeAtIndex(Method m, unsigned index);

// Returnes the offset of the argument at a given index.
// If index is 0 based, and if it exceeds the number of arguments, the result is undefined.
// Use hom_sizeOfType() if you need to get the size of the argument.
HOM_EXTERN int hom_getArgumentOffsetAtIndex(Method m, unsigned index);

HOM_EXTERN int hom_getArgumentOffsetFromTypes(const char *types, unsigned index);

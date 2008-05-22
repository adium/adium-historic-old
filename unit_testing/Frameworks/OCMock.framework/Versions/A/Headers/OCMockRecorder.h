//---------------------------------------------------------------------------------------
//  $Id: OCMockRecorder.h 12 2006-06-11 02:41:31Z erik $
//  Copyright (c) 2004 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import <Foundation/Foundation.h>

@interface OCMockRecorder : NSProxy 
{
	id				signatureResolver;
	id				returnValue;
	BOOL			returnValueIsBoxed;
	BOOL			returnValueShouldBeThrown;
	NSInvocation	*recordedInvocation;
}

+ (id)anyArgument;

- (id)initWithSignatureResolver:(id)anObject;

- (id)andReturn:(id)anObject;
- (id)andReturnValue:(NSValue *)aValue;
- (id)andThrow:(NSException *)anException;

- (BOOL)matchesInvocation:(NSInvocation *)anInvocation;
- (void)setUpReturnValue:(NSInvocation *)anInvocation;

@end


#define OCMOCK_ANY [OCMockRecorder anyArgument]
#define OCMOCK_VALUE(variable) [NSValue value:&variable withObjCType:@encode(typeof(variable))]

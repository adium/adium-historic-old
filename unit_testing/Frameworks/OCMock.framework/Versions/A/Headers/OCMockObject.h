//---------------------------------------------------------------------------------------
//  $Id: OCMockObject.h 15 2007-06-04 11:49:51Z erik $
//  Copyright (c) 2004-2007 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import <Foundation/Foundation.h>

@interface OCMockObject : NSProxy
{
	BOOL			isNice;
	NSMutableArray	*recorders;
	NSMutableSet	*expectations;
	NSMutableArray	*exceptions;
}

+ (id)mockForClass:(Class)aClass;
+ (id)mockForProtocol:(Protocol *)aProtocol;

+ (id)niceMockForClass:(Class)aClass;
+ (id)niceMockForProtocol:(Protocol *)aProtocol;

- (id)init;

- (id)stub;
- (id)expect;

- (void)verify;

@end

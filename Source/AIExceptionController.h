//
//  AIException.h
//  Adium
//
//  Created by Evan Schoenberg on Sat Dec 13 2003.
//  Copyright (c) 2003-2005 The Adium Team. All rights reserved.
//


@interface AIExceptionController : NSException {

}

+ (void)enableExceptionCatching;
- (NSString *)decodedExceptionStackTrace;

@end

//
//  AIException.h
//  Adium
//
//  Created by Evan Schoenberg on Sat Dec 13 2003.
//


@interface AIExceptionController : NSException {

}

+ (void)enableExceptionCatching;
- (NSString *)decodedExceptionStackTrace;

@end

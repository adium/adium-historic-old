//
//  MSNStringAdditions.h
//  Adium
//
//  Created by Colin Barrett on Mon Jun 09 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSString (MSNAdditions)
- (NSString *)urlEncode;
- (NSString *)urlDecode;
- (BOOL)isUrlEncoded;
@end

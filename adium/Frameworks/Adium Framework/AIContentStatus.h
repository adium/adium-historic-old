//
//  AIContentStatus.h
//  Adium
//
//  Created by Adam Iser on Fri Apr 04 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AIAdium.h"

#define CONTENT_STATUS_TYPE		@"Status"		//Type ID for this content

@interface AIContentStatus : NSObject <AIContentObject> {
    id 				source;
    id	 			destination;
    NSDate 			*date;
    NSString 			*message;

}

+ (id)statusWithSource:(id)inSource destination:(id)inDest date:(NSDate *)inDate message:(NSString *)inMessage;
- (NSString *)type;
- (NSString *)message;
- (id)source;
- (id)destination;
- (NSDate *)date;

@end

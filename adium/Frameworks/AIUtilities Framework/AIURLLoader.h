//
//  AIURL.h
//  Adium
//
//  Created by Adam Iser on Sun Mar 23 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface AIURLLoader : NSObject {

}

+ (NSString *)loadHost:(NSString *)host port:(int)port path:(NSString *)path;

@end

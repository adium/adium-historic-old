//
//  SHMarkedHyperlink.h
//  Adium
//
//  Created by Stephen Holt on Tue May 11 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface SHMarkedHyperlink : NSObject {
    NSRange      linkRange;
    NSURL       *linkURL;
    NSString    *pString;
}

-(id)initWithString:(NSString *)inString parentString:(NSString *)pInString andRange:(NSRange)inRange;
-(NSString *)parentString;
-(NSRange)range;
-(NSURL *)URL;

-(void)setRange:(NSRange)inRange;
-(void)setURL:(NSURL *)inURL;
-(void)setURLFromString:(NSString *)inString;
-(void)setParentString:(NSString *)pInString;


@end

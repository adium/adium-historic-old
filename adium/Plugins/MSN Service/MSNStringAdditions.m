//
//  MSNStringAdditions.m
//  Adium
//
//  Created by Colin Barrett on Mon Jun 09 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "MSNStringAdditions.h"

//a-z, A-Z, 0-9, $-_.+!*'(),;/?:@=&

@implementation NSString (MSNAdditions)
- (NSString *)urlEncode
{
    NSScanner *s = [NSScanner scannerWithString:self];
    NSCharacterSet *notUrlCode = [[NSCharacterSet characterSetWithCharactersInString:
        @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789$-_.+!*'(),;/?:@=&"] 		invertedSet];
    NSMutableString *encodedString = [[NSMutableString alloc] initWithString:@""];
    NSString *read;
    
    while(![s isAtEnd])
    {
        [s scanUpToCharactersFromSet:notUrlCode intoString:&read];
        if(read)
            [encodedString appendString:read];
        if(![s isAtEnd])
        {
            [encodedString appendFormat:@"%%%x", [self characterAtIndex:[s scanLocation]]];
            [s setScanLocation:[s scanLocation]+1];
        }
    }
    
    return([encodedString autorelease]);
}

- (NSString *)urlDecode
{
    NSScanner *s = [NSScanner scannerWithString:self];
    NSMutableString *decodedString = [[NSMutableString alloc] initWithString:@""];
    NSString *read;
    
    while(![s isAtEnd])
    {
        [s scanUpToString:@"%" intoString:&read];
        if(read)
            [decodedString appendString:read];
        if(![s isAtEnd])
        {
            [decodedString appendString:[NSString stringWithFormat:@"%c", 
                [[NSString stringWithFormat:@"%li",
                    strtol([[self substringWithRange:NSMakeRange([s scanLocation]+1, 2)] cString], 
                        NULL, 16)] 
                intValue]]];
                
            [s setScanLocation:[s scanLocation]+3];

        }
    }
    return([decodedString autorelease]);
}

- (BOOL)isUrlEncoded
{
    NSCharacterSet *notUrlCode = [[NSCharacterSet characterSetWithCharactersInString:
        @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789$-_.+!*'(),;/?:@=&"] 		invertedSet];
    NSCharacterSet *notHexSet = [[NSCharacterSet characterSetWithCharactersInString: 	@"0123456789ABCEFabcdef"]
        invertedSet];
    NSScanner *s = [NSScanner scannerWithString:self]; 
    
    if([self rangeOfCharacterFromSet:notUrlCode].location != NSNotFound)
        return NO;
    
    while(![s isAtEnd])
    {
        [s scanUpToString:@"%" intoString:nil];
        
        if([[self substringWithRange:NSMakeRange([s scanLocation]+1, 2)] rangeOfCharacterFromSet:notHexSet].location != NSNotFound)
            return NO;
    }
    
    return YES;
}
@end
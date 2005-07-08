//
//  AIURLAdditions.h
//  Adium
//
//  Created by Evan Schoenberg on Tue Feb 17 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

@interface NSURL (AIURLAdditions)

- (unsigned int)length;

//Search is case sensitive, and you're responsible for removing any percent escapes (and +'s too)
- (NSString *)queryArgumentForKey:(NSString *)key;

@end

//
//  ESURLAdditions.h
//  Adium
//
//  Created by Evan Schoenberg on Tue Feb 17 2004.

@interface NSURL (ESURLAdditions)

- (unsigned int)length;

//Search is case sensitive, and you're responsible for removing any percent escapes (and +'s too)
- (NSString *)queryArgumentForKey:(NSString *)key;

@end

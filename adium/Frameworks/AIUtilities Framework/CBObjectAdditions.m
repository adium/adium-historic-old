//
//  CBObjectAdditions.m
//  Adium
//
//  Created by Colin Barrett on Mon Sep 22 2003.
//

#import "CBObjectAdditions.h"

/* 
 * this wonderful little thing is the creation of Mulle kybernetiK.
 * the awesome page I found this on is here: 
 * http://www.mulle-kybernetik.com/artikel/Optimization/
 * Happy landings! --chb 9/22/03
 */


@implementation NSObject (HashingAdditions)

- (unsigned int) hash
{
   return( ((unsigned int) self >> 4) | (unsigned int) self << (32 - 4));
}

@end

//
//  ESArrayAdditions.h
//  Adium
//
//  Created by Evan Schoenberg on Sat Jan 10 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

@interface NSArray (ESArrayAdditions)
+ (NSArray *)arrayNamed:(NSString *)name forClass:(Class)inClass;
@end

@interface NSMutableArray (ESArrayAdditions)
- (void)moveObject:(id)object toIndex:(int)newIndex;
@end

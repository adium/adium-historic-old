//
//  AITabViewAdditions.m
//  Adium
//
//  Created by Adam Iser on Wed Dec 11 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import "AITabViewAdditions.h"


@implementation NSTabView (AITabViewAdditions)

- (NSTabViewItem *)tabViewItemWithIdentifier:(id)identifier
{
    return([self tabViewItemAtIndex:[self indexOfTabViewItemWithIdentifier:identifier]]);
}


@end

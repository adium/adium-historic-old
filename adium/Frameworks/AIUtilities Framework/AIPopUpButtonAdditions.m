//
//  AIPopUpButtonAdditions.m
//  Adium
//
//  Created by Adam Iser on Fri Jan 24 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIPopUpButtonAdditions.h"


@implementation NSPopUpButton (AIPopUpButtonAdditions)

- (void)selectItemWithRepresentedObject:(id)object
{
    int	index = [self indexOfItemWithRepresentedObject:object];
    [self selectItemAtIndex:index];
}


@end

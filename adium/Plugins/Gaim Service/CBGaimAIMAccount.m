//
//  CBGaimAIMAccount.m
//  Adium XCode
//
//  Created by Colin Barrett on Sat Nov 01 2003.
//

#import "AIGaimAccountViewController.h"
#import "CBGaimAIMAccount.h"
#import "aim.h"

@implementation CBGaimAIMAccount

- (id <AIAccountViewController>)accountView
{
    return([AIGaimAccountViewController accountViewForAccount:self]);
}

@end

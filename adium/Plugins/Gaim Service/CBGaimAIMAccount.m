//
//  CBGaimAIMAccount.m
//  Adium XCode
//
//  Created by Colin Barrett on Sat Nov 01 2003.
//

#import "AIGaimAIMAccountViewController.h"
#import "CBGaimAIMAccount.h"
#import "aim.h"

@implementation CBGaimAIMAccount

- (id <AIAccountViewController>)accountView
{
    return([AIGaimAIMAccountViewController accountViewForAccount:self]);
}

@end

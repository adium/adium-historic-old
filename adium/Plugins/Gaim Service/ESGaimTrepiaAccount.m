//
//  ESGaimTrepiaAccount.m
//  Adium XCode
//
//  Created by Evan Schoenberg on Sun Feb 22 2004.
//

#import "ESGaimTrepiaAccount.h"
#import "ESGaimTrepiaAccountViewController.h"

@implementation ESGaimTrepiaAccount

- (const char*)protocolPlugin
{
    return "prpl-trepia";
}

- (id <AIAccountViewController>)accountView
{
    return([ESGaimTrepiaAccountViewController accountViewForAccount:self]);
}

@end
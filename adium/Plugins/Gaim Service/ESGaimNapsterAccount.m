//
//  ESGaimNapsterAccount.m
//  Adium XCode
//
//  Created by Evan Schoenberg on Sun Dec 28 2003.

#import "ESGaimNapsterAccountViewController.h"
#import "ESGaimNapsterAccount.h"

@implementation ESGaimNapsterAccount

- (const char*)protocolPlugin
{
    return "prpl-napster";
}

- (id <AIAccountViewController>)accountView
{
    return([ESGaimNapsterAccountViewController accountViewForAccount:self]);
}

@end
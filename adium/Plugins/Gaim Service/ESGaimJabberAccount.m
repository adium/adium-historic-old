//
//  ESGaimJabberAccount.m
//  Adium XCode
//
//  Created by Evan Schoenberg on Sun Dec 28 2003.

#import "ESGaimJabberAccountViewController.h"
#import "ESGaimJabberAccount.h"

@implementation ESGaimJabberAccount

- (const char*)protocolPlugin
{
    return "prpl-jabber";
}

- (id <AIAccountViewController>)accountView
{
    return([ESGaimJabberAccountViewController accountViewForAccount:self]);
}

@end
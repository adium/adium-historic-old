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

- (void)createNewGaimAccount
{
    [super createNewGaimAccount];
//    gaim_account_set_string(account,"connect_server","jabber.carter.to");
}

- (id <AIAccountViewController>)accountView
{
    return([ESGaimJabberAccountViewController accountViewForAccount:self]);
}

@end
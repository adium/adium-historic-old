//
//  ESGaimYahooAccount.m
//  Adium XCode
//
//  Created by Evan Schoenberg on Sun Dec 28 2003.
//

#import "ESGaimYahooAccountViewController.h"
#import "ESGaimYahooAccount.h"

@implementation ESGaimYahooAccount

- (const char*)protocolPlugin
{
    return "prpl-yahoo";
}

- (id <AIAccountViewController>)accountView
{
    return([ESGaimYahooAccountViewController accountViewForAccount:self]);
}

@end

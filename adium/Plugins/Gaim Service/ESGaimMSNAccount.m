//
//  ESGaimMSNAccount.m
//  Adium XCode
//
//  Created by Evan Schoenberg on Sun Dec 28 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "ESGaimMSNAccountViewController.h"
#import "ESGaimMSNAccount.h"

@implementation ESGaimMSNAccount

- (const char*)protocolPlugin
{
    return "prpl-msn";
}

- (id <AIAccountViewController>)accountView
{
    return([ESGaimMSNAccountViewController accountViewForAccount:self]);
}

@end

//
//  ESGaimMSNAccount.m
//  Adium XCode
//
//  Created by Evan Schoenberg on Sun Dec 28 2003.
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

//MSN doesn't use HTML at all... there's a font setting in the MSN Messenger text box, but maybe it's ignored?
- (NSString *)encodedAttributedString:(NSAttributedString *)inAttributedString forListObject:(AIListObject *)inListObject
{
    return ([inAttributedString string]);
}

@end

//
//  ESGaimNovellAccountViewController.m
//  Adium
//
//  Created by Evan Schoenberg on Mon Apr 19 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

#import "ESGaimNovellAccountViewController.h"

@implementation ESGaimNovellAccountViewController

- (NSString *)nibName{
    return(@"ESGaimNovellAccountView");
}

//Return nil to hide the options tab, we don't need it
- (NSView *)optionsView
{
    return(nil);
}

@end

//
//  ESGaimMSNAccountViewController.m
//  Adium XCode
//
//  Created by Evan Schoenberg on Sun Dec 28 2003.

#import "ESGaimMSNAccountViewController.h"


@implementation ESGaimMSNAccountViewController

//Configure our controls
- (void)configureViewAfterLoad
{
    //Configure the standard controls
    [super configureViewAfterLoad];
    
}

-(NSString *)validScreenNameCharacters
{
    return (@"abcdefghijklmnopqrstuvwxyz0123456789@. ");
}

@end

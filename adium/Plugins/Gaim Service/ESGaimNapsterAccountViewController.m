//
//  ESGaimNapsterAccountViewController.m
//  Adium XCode
//
//  Created by Evan Schoenberg on Sun Dec 28 2003.
//

#import "ESGaimNapsterAccountViewController.h"


@implementation ESGaimNapsterAccountViewController

//Configure our controls
- (void)configureViewAfterLoad
{
    //Configure the standard controls
    [super configureViewAfterLoad];
    
}

-(NSString *)validScreenNameCharacters
{
    return ([[super validScreenNameCharacters] stringByAppendingString:@"_"]);
}

@end

//
//  ESGaimJabberAccountViewController.m
//  Adium XCode
//
//  Created by Evan Schoenberg on Sun Dec 28 2003.
//

#import "ESGaimJabberAccountViewController.h"


@implementation ESGaimJabberAccountViewController
//Configure our controls
- (void)configureViewAfterLoad
{
    //Configure the standard controls
    [super configureViewAfterLoad];
    
}

-(NSString *)validScreenNameCharacters
{
    return ([[super validScreenNameCharacters] stringByAppendingString:@" _@"]);
}
-(int)maximumScreenNameLength
{
    return (50);
}

@end

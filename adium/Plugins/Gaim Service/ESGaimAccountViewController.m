//
//  ESGaimAccountView.m
//  Adium XCode
//
//  Created by Evan Schoenberg on Sun Dec 28 2003.
//

#import "ESGaimAccountViewController.h"


@implementation ESGaimAccountViewController
//Nib to load
- (NSString *)nibName{
    return(@"GaimAccountView");    
}

//Configure our controls
- (void)configureViewAfterLoad
{
    //Configure the standard controls
    [super configureViewAfterLoad];
    
    //Load and add our auxiliary tabs if present
    NSString *auxiliaryNib = [self auxiliaryGaimAccountViewTabsNib];
    if (auxiliaryNib) {
        [NSBundle loadNibNamed:auxiliaryNib owner:self];
        
        [self loadAuxiliaryTabsFromTabView:view_auxiliaryGaimAccountTabView];
    }
    
    //Restrict the account name field to valid characters and length
    [textField_accountName setFormatter:
        [AIStringFormatter stringFormatterAllowingCharacters:[NSCharacterSet characterSetWithCharactersInString:[self validScreenNameCharacters]]
                                                      length:[self maximumScreenNameLength]
                                               caseSensitive:NO
                                                errorMessage:[self errorMessage]]];
    
    //Put focus on the account name
    [[[view_accountView superview] window] setInitialFirstResponder:textField_accountName];	
}

//Basic characterset by default
-(NSString *)validScreenNameCharacters
{
    return (@"abcdefghijklmnopqrstuvwxyz0123456789. ");
}
//I like the number 24.  Also, I like cookies.  However, cookies are not of type (int), so 24 it is.
-(int)maximumScreenNameLength
{
    return (24);
}
-(NSString *)errorMessage
{
    return ([NSString stringWithFormat:@"Your user name must be %i characters or less, contain only letters and numbers, and start with a letter.",[self maximumScreenNameLength]]);
}

//No auxiliary tabs by default
-(NSString *)auxiliaryGaimAccountViewTabsNib
{
    return nil;
}
@end

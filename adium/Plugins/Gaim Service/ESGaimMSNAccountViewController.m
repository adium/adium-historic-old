//
//  ESGaimMSNAccountViewController.m
//  Adium
//
//  Created by Evan Schoenberg on Sun Dec 28 2003.

#import "ESGaimMSNAccountViewController.h"

@implementation ESGaimMSNAccountViewController

- (NSString *)nibName{
    return(@"ESGaimMSNAccountView");
}

//Configure our controls
- (void)configureForAccount:(AIAccount *)inAccount
{
    [super configureForAccount:inAccount];
    
    //Serverside alias - Friendly Name
    NSString		*friendlyName = [account preferenceForKey:@"FullName" group:GROUP_ACCOUNT_STATUS];
    if(friendlyName){
        [textField_friendlyName setStringValue:friendlyName];
    }
}

//Save changes made to a preference control
- (IBAction)changedPreference:(id)sender
{
    [super changedPreference:sender];
    
    //Our custom preferences
    if(sender == textField_friendlyName){
        [account setPreference:[sender stringValue] forKey:@"FullName" group:GROUP_ACCOUNT_STATUS];    
        
    }
}

@end
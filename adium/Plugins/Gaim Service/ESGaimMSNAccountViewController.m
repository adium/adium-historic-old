//
//  ESGaimMSNAccountViewController.m
//  Adium XCode
//
//  Created by Evan Schoenberg on Sun Dec 28 2003.

#import "ESGaimMSNAccountViewController.h"

@implementation ESGaimMSNAccountViewController

#define MSN_AUXILIARY_NIB   @"ESGaimMSNAccountView"

//Configure our controls
- (void)configureViewAfterLoad
{
    //Configure the standard controls
    [super configureViewAfterLoad];
    
    //Serverside alias - Friendly Name
    NSString            *friendlyName = [account preferenceForKey:@"FullName" group:GROUP_ACCOUNT_STATUS];
    if (friendlyName){
        [textField_friendlyName setStringValue:friendlyName];
    }
}

//Save changes made to a preference control
- (IBAction)changedPreference:(id)sender
{
    //Handle the standard preferences
    [super changedPreference:sender];
    
    //Our custom preferences
    if(sender == textField_friendlyName){
        [account setPreference:[sender stringValue] forKey:@"FullName" group:GROUP_ACCOUNT_STATUS];    
        
    }
}

-(NSString *)auxiliaryGaimAccountViewTabsNib
{
    return MSN_AUXILIARY_NIB;
}

@end
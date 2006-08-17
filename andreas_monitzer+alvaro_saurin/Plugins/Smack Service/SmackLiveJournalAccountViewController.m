//
//  SmackGoogleAccountViewController.m
//  Adium
//
//  Created by Andreas Monitzer on 2006-08-15.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import "SmackLiveJournalAccountViewController.h"


@implementation SmackLiveJournalAccountViewController

+ (AIAccountViewController*)accountViewController {
    static SmackLiveJournalAccountViewController *avc = nil;
    if(!avc)
        avc = [[self alloc] init];
    return avc;
}

- (NSString*)nibName {
    return @"SmackLiveJournalAccountView";
}

- (void)configureForAccount:(AIAccount *)inAccount
{
    if(account != inAccount) {
        [super configureForAccount:inAccount];
        
        NSString *username = [[account formattedUID] jidUsername];
        
        // the user name field shouldn't contain @gmail.com
        [textField_accountUID setStringValue:username?username:@""];
    }
}

@end

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

@end

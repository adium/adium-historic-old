//
//  SmackGoogleService.m
//  Adium
//
//  Created by Andreas Monitzer on 2006-08-15.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import "SmackLiveJournalService.h"
#import <AIUtilities/AIStringUtilities.h>
#import "SmackLiveJournalAccountViewController.h"

@class SmackLiveJournalAccount;

@implementation SmackLiveJournalService

- (Class)accountClass
{
    return [SmackLiveJournalAccount class];
}
- (AIAccountViewController *)accountViewController
{
    return [SmackLiveJournalAccountViewController accountViewController];
}

- (NSString *)serviceClass
{
	return @"LiveJournal";
}

- (NSString *)UIDPlaceholder
{
	return AILocalizedString(@"username@livejournal.com","Sample name and server for new livejournal accounts");
}

- (NSString *)serviceCodeUniqueID {
	return @"Smack-lj";
}

- (NSString *)shortDescription {
	return @"LiveJournal";
}

- (NSString *)longDescription {
	return @"LiveJournal Account";
}

- (NSString *)serviceID {
	return @"LiveJournal";
}

- (NSImage *)defaultServiceIconOfType:(AIServiceIconType)iconType
{
    return [NSImage imageNamed:@"LiveJournal"];
}

@end

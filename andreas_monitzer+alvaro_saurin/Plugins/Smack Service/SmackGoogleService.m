//
//  SmackGoogleService.m
//  Adium
//
//  Created by Andreas Monitzer on 2006-08-15.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import "SmackGoogleService.h"
#import <AIUtilities/AIStringUtilities.h>
#import "SmackGoogleAccountViewController.h"

@class SmackGoogleAccount;

@implementation SmackGoogleService

- (Class)accountClass
{
    return [SmackGoogleAccount class];
}
- (AIAccountViewController *)accountViewController
{
    return [SmackGoogleAccountViewController accountViewController];
}

- (NSString *)serviceClass
{
	return @"GTalk";
}

- (NSString *)UIDPlaceholder
{
	return AILocalizedString(@"username@gtalk.com","Sample name and server for new gmail accounts");
}

- (NSString *)serviceCodeUniqueID {
	return @"Smack-gtalk";
}

- (NSString *)shortDescription {
	return @"GTalk";
}

- (NSString *)longDescription {
	return @"GTalk Account";
}

- (NSString *)serviceID {
	return @"GTalk";
}

- (NSImage *)defaultServiceIconOfType:(AIServiceIconType)iconType
{
    return [NSImage imageNamed:@"GTalk"];
}

@end

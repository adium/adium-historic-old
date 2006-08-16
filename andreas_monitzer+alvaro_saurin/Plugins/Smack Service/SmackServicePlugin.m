//
//  SmackServicePlugin.m
//  Adium
//
//  Created by Andreas Monitzer on 2006-05-28.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import "SmackServicePlugin.h"


@implementation SmackServicePlugin

- (void)installPlugin
{
	xmppService = [[SmackXMPPService alloc] init];
    googleService = [[SmackGoogleService alloc] init];
    ljService = [[SmackLiveJournalService alloc] init];
}

- (void)dealloc {
    [xmppService release];
    xmppService = nil;
    [googleService release];
    googleService = nil;
    [SmackLiveJournalService release];
    ljService = nil;
    [super dealloc];
}

@end

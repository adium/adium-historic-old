//
//  SmackLiveJournalAccount.m
//  Adium
//
//  Created by Andreas Monitzer on 2006-08-15.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import "SmackLiveJournalAccount.h"


@implementation SmackLiveJournalAccount

- (void)initAccount {
	[super initAccount];
    
    // [self addPlugin:...];
}

- (NSString *)explicitFormattedUID {
    return [NSString stringWithFormat:@"%@@livejournal.com",[super explicitFormattedUID]];
}

@end

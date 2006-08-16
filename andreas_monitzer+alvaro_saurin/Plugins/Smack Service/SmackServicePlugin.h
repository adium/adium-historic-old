//
//  SmackServicePlugin.h
//  Adium
//
//  Created by Andreas Monitzer on 2006-05-28.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Adium/AIPlugin.h>

#import "SmackXMPPService.h"
#import "SmackGoogleService.h"
#import "SmackLiveJournalService.h"

@interface SmackServicePlugin : AIPlugin {
    SmackXMPPService *xmppService;
    SmackGoogleService *googleService;
    SmackLiveJournalService *ljService;
}

@end

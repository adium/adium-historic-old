//
//  SmackXMPPAccountRegistrationController.h
//  Adium
//
//  Created by Andreas Monitzer on 2006-07-21.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AIObject.h"

@class WebView, SmackCocoaAdapter, SmackXMPPConnection, SmackXMPPAccountViewController, SmackXMPPErrorMessagePlugin;

@interface SmackXMPPAccountRegistrationController : NSArrayController {
    IBOutlet NSTabView *tabview;
    IBOutlet NSTableView *serverlistTable;
    IBOutlet NSTextField *serverField;
    IBOutlet NSTextField *portField;
    IBOutlet NSButton *requestButton;
    IBOutlet NSProgressIndicator *progressIndicator;
    IBOutlet WebView *webview;
    IBOutlet SmackXMPPAccountViewController *accountviewcontroller;

    SmackCocoaAdapter *smackAdapter;
    SmackXMPPConnection *connection;
    SmackXMPPErrorMessagePlugin *errorPlugin;
    
    BOOL initialized;
}

- (IBAction)requestAccount:(id)sender;

- (void)activate;

@end

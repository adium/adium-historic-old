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

@interface SmackXMPPAccountRegistrationController : AIObject {
    NSXMLDocument *serverlist;
    NSXMLElement *serverlist_root;
    
    IBOutlet NSWindow *window;
    IBOutlet NSTabView *tabview;
    IBOutlet NSTableView *serverlistTable;
    IBOutlet NSTextField *serverField;
    IBOutlet NSTextField *portField;
    IBOutlet NSButton *requestButton;
    IBOutlet NSProgressIndicator *progressIndicator;
    IBOutlet WebView *webview;

    SmackCocoaAdapter *smackAdapter;
    SmackXMPPConnection *connection;
    SmackXMPPAccountViewController *accountviewcontroller;
    SmackXMPPErrorMessagePlugin *errorPlugin;
}

- (id)initWithAccountViewController:(SmackXMPPAccountViewController*)avc;

- (IBAction)requestAccount:(id)sender;

@end

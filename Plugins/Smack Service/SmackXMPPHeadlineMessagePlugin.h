//
//  SmackXMPPHeadlineMessagePlugin.h
//  Adium
//
//  Created by Andreas Monitzer on 2006-06-23.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Adium/AIObject.h>

@class SmackXMPPAccount;

@interface SmackXMPPHeadlineMessagePlugin : AIObject {
    IBOutlet NSWindow *window;
    IBOutlet NSTableView *tableview;
    IBOutlet NSDateFormatter *dateformatter;
    IBOutlet NSArrayController *headlinescontroller;
    IBOutlet NSTextField *lastReceived;
    
    NSMutableArray *headlines;
    
    NSDictionary *messagestyle;
    SmackXMPPAccount *account;
}

- (id)initWithAccount:(SmackXMPPAccount*)a;

- (IBAction)clear:(id)sender;

@end

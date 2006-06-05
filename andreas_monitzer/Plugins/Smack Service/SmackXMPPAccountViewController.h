//
//  SmackXMPPAccountViewController.h
//  Adium
//
//  Created by Andreas Monitzer on 2006-05-28.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AIAccountViewController.h"

@interface SmackXMPPAccountViewController : AIAccountViewController {
    IBOutlet NSTextField *textField_resource;
    IBOutlet NSTextField *label_resource;
    
    IBOutlet NSButton *checkBox_useTLS;
    IBOutlet NSButton *checkBox_useSSL;
    IBOutlet NSButton *checkBox_useSASL;
    IBOutlet NSButton *checkBox_allowSelfSigned;
    IBOutlet NSButton *checkBox_allowExpired;
    IBOutlet NSButton *checkBox_allowNonMatchingHost;
    IBOutlet NSButton *checkBox_useCompression;

    IBOutlet NSSlider *slider_availablePriority;
    IBOutlet NSSlider *slider_awayPriority;
    
    IBOutlet NSTextField *textfield_availablePriority;
    IBOutlet NSTextField *textfield_awayPriority;
    
    NSString *currentJID;
    BOOL useSSL;
}

- (void)setCurrentJID:(NSString*)jid;

- (void)setUseSSL:(BOOL)ssl;

@end

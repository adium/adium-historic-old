//
//  SmackXMPPPhonePlugin.h
//  Adium
//
//  Created by Andreas Monitzer on 2006-08-14.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import <Adium/AIObject.h>

@class SmackXMPPAccount, ABPeoplePickerView, SmackPhoneListener, SmackPhoneCall;
@protocol AIContactListTooltipEntry;

@interface SmackXMPPPhonePlugin : AIObject <AIContactListTooltipEntry> {
    SmackXMPPAccount *account;
    
    IBOutlet NSWindow *window;
    IBOutlet NSTextField *eventfield;
    IBOutlet NSTextField *numberfield;
    IBOutlet NSView *numberfieldview;
    IBOutlet ABPeoplePickerView *peoplePicker;
    
    NSString *discoID;
    NSString *phonejid;
    BOOL isSupported;
    SmackPhoneListener *listener;
    
    SmackPhoneCall *currentCall;
    NSString *currentCallID;
}

- (id)initWithAccount:(SmackXMPPAccount*)a;

- (IBAction)dial:(id)sender;
- (IBAction)forward:(id)sender;
- (IBAction)invite:(id)sender;

// eww
- (IBAction)dial0:(id)sender;
- (IBAction)dial1:(id)sender;
- (IBAction)dial2:(id)sender;
- (IBAction)dial3:(id)sender;
- (IBAction)dial4:(id)sender;
- (IBAction)dial5:(id)sender;
- (IBAction)dial6:(id)sender;
- (IBAction)dial7:(id)sender;
- (IBAction)dial8:(id)sender;
- (IBAction)dial9:(id)sender;
- (IBAction)dialPound:(id)sender;
- (IBAction)dialAsterisk:(id)sender;

@end

//
//  SmackGoogleNewMailPlugin.m
//  Adium
//
//  Created by Andreas Monitzer on 2006-08-16.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import "SmackGoogleNewMailPlugin.h"
#import <JavaVM/NSJavaVirtualMachine.h>
#import "SmackCocoaAdapter.h"
#import "SmackInterfaceDefinitions.h"
#import "SmackXMPPAccount.h"
#import "AIAdium.h"
#import "AIInterfaceController.h"

#import <AIUtilities/AIStringUtilities.h>

@interface SmackGoogleSettings : SmackIQ {
}

- (void)setAutoAcceptRequests:(BOOL)aar;
- (BOOL)getAutoAcceptRequests;
- (void)setMailNotifications:(BOOL)mn;
- (BOOL)getMailNotifications;
- (NSString *)getChildElementXML;
@end

@interface SmackGoogleMailNotification : SmackIQ {
}

+ (void)registerIQ;
- (NSString *)getChildElementXML;
@end

@interface SmackCocoaAdapter (GoogleNewMailPlugin)
+ (void)registerGoogleNewMailExtension;
+ (SmackGoogleSettings *)googleSettings;
@end

@implementation SmackCocoaAdapter (GoogleNewMailPlugin)

+ (SmackGoogleSettings *)googleSettings
{
    return [[(id)[[self classLoader] loadClass:@"net.adium.smackBridge.google.GoogleSettings"] newWithSignature:@"()"] autorelease];
}

+ (void)registerGoogleNewMailExtension
{
    [(id)[[self classLoader] loadClass:@"net.adium.smackBridge.google.MailNotification"] registerIQ];
}

@end

@implementation SmackGoogleNewMailPlugin

- (id)initWithAccount:(SmackXMPPAccount*)inAccount
{
    if ((self = [super init]))
    {
        account = inAccount;
        [SmackCocoaAdapter registerGoogleNewMailExtension];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receivedIQPacket:)
                                                     name:SmackXMPPIQPacketReceivedNotification
                                                   object:account];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(updateSettings:)
                                                     name:SmackXMPPUpdateStatusNotification
                                                   object:account];
    }
    return self;
}

- (void)connected:(SmackXMPPConnection*)connection
{
    [self performSelector:@selector(afterLoginConnected) withObject:nil afterDelay:0.0];
}

- (void)updateSettings:(NSNotification*)notification
{
    NSString *key = [[notification userInfo] objectForKey:SmackXMPPStatusKey];
    if ([key isEqualToString:KEY_ACCOUNT_CHECK_MAIL]) {
        SmackGoogleSettings *settings = [SmackCocoaAdapter googleSettings];
        [settings setMailNotifications:[[account preferenceForKey:KEY_ACCOUNT_CHECK_MAIL
                                                            group:GROUP_ACCOUNT_STATUS] boolValue]];
        [settings setTo:[[account UID] jidUserHost]]; // for some reason, the target is ourselves
        [settings setType:[SmackCocoaAdapter IQType:@"SET"]];
        [[account connection] sendPacket:settings];
    }
}

- (void)afterLoginConnected
{
    SmackXMPPConnection *connection = [account connection];
    if (!connection)
        return; // seems to have failed
    
    [self updateSettings:[NSNotification notificationWithName:SmackXMPPUpdateStatusNotification
                                                       object:account
                                                     userInfo:[NSDictionary dictionaryWithObject:KEY_ACCOUNT_CHECK_MAIL forKey:SmackXMPPStatusKey]]];
}

- (void)receivedIQPacket:(NSNotification*)notification
{
    SmackIQ *packet = [[notification userInfo] objectForKey:SmackXMPPPacket];
    
    NSLog(@"packet = %@",[packet toXML]);
    
    if ([[[packet getType] toString] isEqualToString:@"set"] && [SmackCocoaAdapter object:packet isInstanceOfJavaClass:@"net.adium.smackBridge.google.MailNotification"]) {
        // tell the server that we have received it
        SmackIQ *result = [SmackCocoaAdapter IQ];
        [result setType:[SmackCocoaAdapter IQType:@"RESULT"]];
        [result setPacketID:[packet getPacketID]];
        [[account connection] sendPacket:result];
        
        [[adium interfaceController] displayQuestion:[NSString stringWithFormat:AILocalizedString(@"New Mail Received on %@","new mail notification alert title"),[[account UID] jidUserHost]]
                                     withDescription:AILocalizedString(@"Do you want to visit your mailbox on http://mail.google.com?","new mail notification alert question")
                                     withWindowTitle:AILocalizedString(@"Notification","new mail alert window title")
                                       defaultButton:AILocalizedString(@"Visit Website","new mail alert window default button")
                                     alternateButton:AILocalizedString(@"Close","new mail alert window alternate button")
                                         otherButton:nil
                                              target:self
                                            selector:@selector(showGoogleMailWebpage:userInfo:)
                                            userInfo:nil];
    }
}

- (void)showGoogleMailWebpage:(int)returncode userInfo:(NSDictionary*)userInfo
{
    if (returncode == NSAlertDefaultReturn)
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://mail.google.com"]];
}

@end

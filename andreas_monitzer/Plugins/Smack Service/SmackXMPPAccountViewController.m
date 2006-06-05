//
//  SmackXMPPAccountViewController.m
//  Adium
//
//  Created by Andreas Monitzer on 2006-05-28.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import "SmackXMPPAccountViewController.h"
#import "AIAccount.h"

@implementation SmackXMPPAccountViewController

+ (AIAccountViewController*)accountViewController {
    static SmackXMPPAccountViewController *avc = nil;
    if(!avc)
        avc = [[SmackXMPPAccountViewController alloc] init];
    return avc;
}

- (NSString*)nibName {
    return @"SmackXMPPAccountView";
}

- (void)configureForAccount:(AIAccount *)inAccount {
    if(account != inAccount) {
        [super configureForAccount:inAccount];
        
        NSString *resource = [account preferenceForKey:@"Resource" group:GROUP_ACCOUNT_STATUS];
        [textField_resource setStringValue:resource?resource:@""];

		[checkBox_useTLS setState:![[inAccount preferenceForKey:@"disableTLS"
                                                          group:GROUP_ACCOUNT_STATUS] boolValue]];
		[checkBox_useSSL setState:[[inAccount preferenceForKey:@"useSSL"
															group:GROUP_ACCOUNT_STATUS] boolValue]];
		[checkBox_useSASL setState:![[inAccount preferenceForKey:@"disableSASL"
															group:GROUP_ACCOUNT_STATUS] boolValue]];
		[checkBox_allowSelfSigned setState:[[inAccount preferenceForKey:@"allowSelfSigned"
															group:GROUP_ACCOUNT_STATUS] boolValue]];
		[checkBox_allowExpired setState:[[inAccount preferenceForKey:@"allowExpired"
															group:GROUP_ACCOUNT_STATUS] boolValue]];
        [checkBox_allowNonMatchingHost setState:[[inAccount preferenceForKey:@"allowNonMatchingHost"
                                                                       group:GROUP_ACCOUNT_STATUS] boolValue]];
		[checkBox_useCompression setState:![[inAccount preferenceForKey:@"disableCompression"
															group:GROUP_ACCOUNT_STATUS] boolValue]];

        [slider_availablePriority setIntValue:[[inAccount preferenceForKey:@"availablePriority"
                                                                     group:GROUP_ACCOUNT_STATUS] intValue]];
        [textfield_availablePriority setIntValue:[[inAccount preferenceForKey:@"availablePriority"
                                                                        group:GROUP_ACCOUNT_STATUS] intValue]];
        [slider_awayPriority setIntValue:[[inAccount preferenceForKey:@"awayPriority"
                                                                group:GROUP_ACCOUNT_STATUS] intValue]];
        [textfield_awayPriority setIntValue:[[inAccount preferenceForKey:@"awayPriority"
                                                                   group:GROUP_ACCOUNT_STATUS] intValue]];
        
        
        
        [self setCurrentJID:[inAccount explicitFormattedUID]];
    }
}

- (void)saveConfiguration {
    [super saveConfiguration];
    NSString *resource = [textField_resource stringValue];
    [account setPreference:(resource && [resource length])?resource:nil
                    forKey:@"Resource"
                     group:GROUP_ACCOUNT_STATUS];
    
    [account setPreference:[NSNumber numberWithBool:![checkBox_useTLS state]]
					forKey:@"disableTLS"
					 group:GROUP_ACCOUNT_STATUS];
    [account setPreference:[NSNumber numberWithBool:[checkBox_useSSL state]]
					forKey:@"useTLS"
					 group:GROUP_ACCOUNT_STATUS];
    [account setPreference:[NSNumber numberWithBool:![checkBox_useSASL state]]
					forKey:@"disableSASL"
					 group:GROUP_ACCOUNT_STATUS];
    [account setPreference:[NSNumber numberWithBool:[checkBox_allowSelfSigned state]]
					forKey:@"allowSelfSigned"
					 group:GROUP_ACCOUNT_STATUS];
    [account setPreference:[NSNumber numberWithBool:[checkBox_allowExpired state]]
					forKey:@"allowExpired"
					 group:GROUP_ACCOUNT_STATUS];
    [account setPreference:[NSNumber numberWithBool:[checkBox_allowNonMatchingHost state]]
					forKey:@"allowNonMatchingHost"
					 group:GROUP_ACCOUNT_STATUS];
    [account setPreference:[NSNumber numberWithBool:![checkBox_useCompression state]]
					forKey:@"disableCompression"
					 group:GROUP_ACCOUNT_STATUS];
    
    [account setPreference:[NSNumber numberWithInt:[slider_availablePriority intValue]]
					forKey:@"availablePriority"
					 group:GROUP_ACCOUNT_STATUS];
    [account setPreference:[NSNumber numberWithInt:[slider_awayPriority intValue]]
					forKey:@"awayPriority"
					 group:GROUP_ACCOUNT_STATUS];
}

- (void)setCurrentJID:(NSString*)jid {
    id old = currentJID;
    currentJID = [jid retain];
    [old release];

    NSRange hostrange = [jid rangeOfString:@"@" options:NSLiteralSearch | NSBackwardsSearch];
    if(hostrange.location != NSNotFound)
        [[textField_connectHost cell] setPlaceholderString:[jid substringFromIndex:hostrange.location + 1]];
    else
        [[textField_connectHost cell] setPlaceholderString:@""];
}

- (void)setUseSSL:(BOOL)ssl {
    useSSL = ssl;
    [[textField_connectPort cell] setPlaceholderString:ssl?@"5223":@"5222"];
}

@end

//
//  SmackCocoaAdapter.h
//  Adium
//
//  Created by Andreas Monitzer on 2006-05-28.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "AIObject.h"

@protocol AdiumSmackBridgeDelegate;
@class SmackXMPPConnection, SmackXMPPAccount, SmackPresenceType, SmackPresenceMode, SmackMessageType, SmackConnectionConfiguration, SmackPresence, SmackMessage, SmackXXHTMLExtension, SmackIQ, SmackIQType, SmackXMPPError, SmackRoster, SmackXForm, JavaMethod;

@interface SmackCocoaAdapter : AIObject <AdiumSmackBridgeDelegate> {
    SmackXMPPConnection *connection;
    SmackXMPPAccount *account;
}

+ (void)initializeJavaVM;

+ (id)staticObjectField:(NSString*)fieldname inJavaClass:(NSString*)className;
+ (BOOL)object:(id)obj isInstanceOfJavaClass:(NSString*)className;

- (id)initForAccount:(SmackXMPPAccount *)inAccount;
- (SmackXMPPConnection*)connection;

+ (SmackConnectionConfiguration*)connectionConfigurationWithHost:(NSString*)host port:(int)port service:(NSString*)service;
+ (SmackPresence*)presenceWithType:(SmackPresenceType*)type;
+ (SmackPresence*)presenceWithTypeString:(NSString*)type;
+ (SmackPresence*)presenceWithType:(SmackPresenceType*)type status:(NSString*)status priority:(int)priority mode:(SmackPresenceMode*)mode;
+ (SmackPresence*)presenceWithTypeString:(NSString*)type status:(NSString*)status priority:(int)priority modeString:(NSString*)mode;
+ (SmackMessage*)messageTo:(NSString*)to type:(SmackMessageType*)type;
+ (SmackMessage*)messageTo:(NSString*)to typeString:(NSString*)type;

+ (SmackXXHTMLExtension*)XHTMLExtension;
+ (SmackIQ*)IQ;
+ (SmackIQType*)IQType:(NSString*)type;
+ (SmackXMPPError*)XMPPErrorWithCode:(int)code;
+ (SmackXMPPError*)XMPPErrorWithCode:(int)code message:(NSString*)message;
+ (void)createRosterEntryInRoster:(SmackRoster*)roster withJID:(NSString*)jid name:(NSString*)name group:(NSString*)group;
+ (SmackXForm*)formWithType:(NSString*)type;
+ (id)invokeObject:(id)obj methodWithParamTypeAndParam:(NSString*)method, ...;

@end

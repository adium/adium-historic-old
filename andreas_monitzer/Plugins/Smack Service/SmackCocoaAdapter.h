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
@class SmackXMPPConnection, SmackXMPPAccount, SmackPresenceType, SmackPresenceMode, SmackMessageType, SmackConnectionConfiguration, SmackPresence, SmackMessage, SmackPacket, SmackXXHTMLExtension, SmackIQ, SmackIQType, SmackXMPPError, SmackRoster, SmackRegistration, SmackXForm, SmackXFormField, JavaMethod, JavaVector, JavaDate, JavaMap, JavaFile, SmackXServiceDiscoveryManager, JavaClassLoader, SmackInvisibleCommand;

@interface SmackCocoaAdapter : AIObject <AdiumSmackBridgeDelegate> {
    SmackXMPPConnection *connection;
    SmackXMPPAccount *account;
}

+ (void)initializeJavaVM;

+ (JavaClassLoader*)classLoader; // for categories only!

+ (id)enumWithType:(NSString*)type name:(NSString*)name;
+ (id)staticObjectField:(NSString*)fieldname inJavaClass:(NSString*)className;
+ (BOOL)object:(id)obj isInstanceOfJavaClass:(NSString*)className;

- (id)initForAccount:(SmackXMPPAccount *)inAccount;
- (SmackXMPPConnection*)connection;

+ (SmackConnectionConfiguration*)connectionConfigurationWithHost:(NSString*)host port:(int)port service:(NSString*)service;
+ (SmackPresence*)presenceWithType:(SmackPresenceType*)type;
+ (SmackPresence*)presenceWithTypeString:(NSString*)type;
+ (SmackPresence*)presenceWithType:(SmackPresenceType*)type status:(NSString*)status priority:(int)priority mode:(SmackPresenceMode*)mode;
+ (SmackPresence*)presenceWithTypeString:(NSString*)type status:(NSString*)status priority:(int)priority modeString:(NSString*)mode;
+ (SmackMessage*)message;
+ (SmackMessage*)messageTo:(NSString*)to type:(SmackMessageType*)type;
+ (SmackMessage*)messageTo:(NSString*)to typeString:(NSString*)type;
+ (SmackMessageType*)messageTypeFromString:(NSString*)type;
+ (SmackRegistration*)registration;

+ (SmackXServiceDiscoveryManager*)serviceDiscoveryManagerForConnection:(SmackXMPPConnection*)connection;
+ (SmackXXHTMLExtension*)XHTMLExtension;
+ (SmackIQ*)IQ;
+ (SmackIQType*)IQType:(NSString*)type;
+ (SmackInvisibleCommand*)invisibleCommandForInvisibility:(BOOL)invisible;
+ (SmackXMPPError*)XMPPErrorWithCode:(int)code;
+ (SmackXMPPError*)XMPPErrorWithCode:(int)code message:(NSString*)message;
+ (void)createRosterEntryInRoster:(SmackRoster*)roster withJID:(NSString*)jid name:(NSString*)name group:(NSString*)group;
+ (SmackXForm*)formWithType:(NSString*)type;
+ (SmackXForm*)formFromPacket:(SmackPacket*)packet;
+ (SmackXFormField*)fixedFormField;
+ (SmackXFormField*)formFieldWithVariable:(NSString*)variable;
+ (id)invokeObject:(id)obj methodWithParamTypeAndParam:(NSString*)method, ...;
+ (JavaVector*)vector;
+ (JavaMap*)map;
+ (JavaFile*)fileFromPath:(NSString*)path;

+ (NSDate*)dateFromJavaDate:(JavaDate*)date;

// the Java Bridge has the issue that it transforms Java exceptions into Objective C-exceptions (NSJavaException),
// but the original object gets lost in the process. That way we can't retrieve the XMPPError packet that contains the real info for us.
// However, there's some minimal info stored in the reason-field of the NSException (the toString()-info from the object apparently),
// so we can derive some information from this one.
+ (NSDictionary *)smackExceptionInfo:(NSException*)e;

@end

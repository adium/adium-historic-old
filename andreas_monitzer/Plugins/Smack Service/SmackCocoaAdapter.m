//
//  SmackCocoaAdapter.m
//  Adium
//
//  Created by Andreas Monitzer on 2006-05-28.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import "SmackCocoaAdapter.h"
#import "SmackInterfaceDefinitions.h"
#import "SmackXMPPAccount.h"
#import "ESDebugAILog.h"

#import "AIAdium.h"
#import "AIInterfaceController.h"

#import <JavaVM/NSJavaVirtualMachine.h>
#import <AIUtilities/AIStringUtilities.h>

#define SMACKBRIDGE_JAR @"SmackBridge"
#define SMACK_JAR @"smack"
#define SMACKX_JAR @"smackx"

extern CFRunLoopRef CFRunLoopGetMain(void);
/* java.lang.Object */
@interface NSObject (JavaObjectAdditions)
+ (id)getProperty:(NSString *)property;
- (NSString *)toString;
@end

@implementation SmackCocoaAdapter

+ (void)initializeJavaVM
{
	[NSThread detachNewThreadSelector:@selector(prepareJavaVM)
							 toTarget:self
						   withObject:nil];
}

#pragma mark Java VM Preparation
+ (void)prepareJavaVM
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
	@synchronized(self) {
		//Only one vm is needed for all accounts
		static	NSJavaVirtualMachine	*vm = nil;
		static BOOL		attachedVmToMainRunLoop = NO;
		BOOL			onMainRunLoop = (CFRunLoopGetCurrent() == CFRunLoopGetMain());
        
		if (!vm) {
			NSString	*smackJarPath, *smackxJarPath, *smackBridgeJarPath;
			NSString	*classPath;
            
			smackBridgeJarPath = [[NSBundle bundleForClass:[self class]] pathForResource:SMACKBRIDGE_JAR
                                                                                  ofType:@"jar"
                                                                             inDirectory:@"Java"];
			smackJarPath = [[NSBundle bundleForClass:[self class]] pathForResource:SMACK_JAR
																			ofType:@"jar"
																	   inDirectory:@"Java"];
			smackxJarPath = [[NSBundle bundleForClass:[self class]] pathForResource:SMACKX_JAR
																			 ofType:@"jar"
																		inDirectory:@"Java"];
			
			classPath = [NSString stringWithFormat:@"%@:%@:%@:%@",
				[NSJavaVirtualMachine defaultClassPath],
				smackJarPath, smackxJarPath, smackBridgeJarPath];
			
			vm = [[NSJavaVirtualMachine alloc] initWithClassPath:classPath];
			
			AILog(@"-[%@ prepareJavaVM]: Java %@ ; Smack %@. Using classPath: %@",
				  self,
				  [NSClassFromString(@"java.lang.System") getProperty:@"java.version"],
				  [NSClassFromString(@"org.jivesoftware.smack.SmackConfiguration") getVersion],
				  classPath);
			
			if (onMainRunLoop) {
				attachedVmToMainRunLoop = YES;
			}
            
		} else {
			if  (!attachedVmToMainRunLoop && onMainRunLoop) {
				[vm attachCurrentThread];
				attachedVmToMainRunLoop = YES;
			} else
                [vm attachCurrentThread];
		}
        
		if (onMainRunLoop &&
			!NSClassFromString(@"org.jivesoftware.smack.SmackConfiguration")) {
			NSMutableString	*msg = [NSMutableString string];
			
			[msg appendFormat:@"Java version %@ could not load SmackConfiguration\n",[NSClassFromString(@"java.lang.System") getProperty:@"java.version"]];
            
			NSRunCriticalAlertPanel(@"Fatal Java error",
									msg,
									nil,nil,nil);
		}
		
#ifdef DEBUG_BUILD
		[[NSNotificationCenter defaultCenter] performSelector:@selector(postNotificationName:object:)
												   withObject:@"AttachedJavaVM"
												   withObject:nil];
#endif
	}
    
	[pool release];
}

#pragma mark utility functions

+ (id)staticObjectField:(NSString*)fieldname inJavaClass:(NSString*)className {
    return [NSClassFromString(@"net.adium.smackBridge.SmackBridge") getStaticFieldFromClass:fieldname :className];
}

+ (BOOL)object:(id)obj isInstanceOfJavaClass:(NSString*)className {
    return [NSClassFromString(@"net.adium.smackBridge.SmackBridge") isInstanceOfClass:obj :className];
}

+ (NSDate*)dateFromJavaDate:(JavaDate*)date
{
    // [javaDate toString] format: "dow mon dd hh:mm:ss zzz yyyy"	
	return (date ? 
			[NSCalendarDate dateWithString:[date toString]
							calendarFormat:@"%a %b %d %H:%M:%S %Z %Y"] :
			nil);
}

#pragma mark Main Adapter

- (id)initForAccount:(SmackXMPPAccount *)inAccount {
    if((self=[super init])) {
        account = inAccount;
        [NSThread detachNewThreadSelector:@selector(runConnection:) toTarget:self withObject:inAccount];
    }
    return self;
}

- (void)runConnection:(SmackXMPPAccount*)inAccount {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    SmackConnectionConfiguration *conf = [inAccount connectionConfiguration];
    if(conf) {
        BOOL useSSL = [[inAccount preferenceForKey:@"useSSL" group:GROUP_ACCOUNT_STATUS] boolValue];
        AdiumSmackBridge *bridge = [[NSClassFromString(@"net.adium.smackBridge.SmackBridge") alloc] init];
        [bridge initSubscriptionMode];
        [bridge setDelegate:self];
        
        @try {
            [bridge createConnection:useSSL :conf];
        }@catch(NSException *e) {
            [self performSelectorOnMainThread:@selector(connectionError:) withObject:e waitUntilDone:YES];
            
            [bridge release];
            [pool release];
            return;
        }
        
        [bridge release];
    }
    [pool release];
}

- (void)connectionError:(NSException*)e {
    [[adium interfaceController] handleErrorMessage:[NSString stringWithFormat:AILocalizedString(@"Connection error on account %@.","Connection error on account %@."),[account explicitFormattedUID]] withDescription:[e reason]];
}

- (SmackXMPPConnection*)connection {
    return connection;
}

- (void)dealloc {
    [connection close];
    [connection release];
    [super dealloc];
}

- (void)setConnection:(SmackXMPPConnection*)conn {
    connection = [conn retain];
    AILog(@"XMPP Connection established");
    [account performSelectorOnMainThread:@selector(connected:) withObject:conn waitUntilDone:NO];
}

- (void)setDisconnection:(JavaBoolean*)blah {
    AILog(@"XMPP Connection closed.");
    [account performSelectorOnMainThread:@selector(disconnected:) withObject:connection waitUntilDone:NO];
}

- (void)setConnectionError:(NSString*)error {
    AILog(@"XMPP Connection Error: %@",error);
    [account performSelectorOnMainThread:@selector(connectionError:) withObject:error waitUntilDone:NO];
}

- (void)setNewMessagePacket:(SmackPacket*)packet {
    [account performSelectorOnMainThread:@selector(receiveMessagePacket:) withObject:packet waitUntilDone:NO];
}
- (void)setNewPresencePacket:(SmackPacket*)packet {
    [account performSelectorOnMainThread:@selector(receivePresencePacket:) withObject:packet waitUntilDone:NO];
}
- (void)setNewIQPacket:(SmackPacket*)packet {
    [account performSelectorOnMainThread:@selector(receiveIQPacket:) withObject:packet waitUntilDone:NO];
}

#pragma mark Bridged Object Creation

+ (SmackConnectionConfiguration*)connectionConfigurationWithHost:(NSString*)host port:(int)port service:(NSString*)service {
    return [[NSClassFromString(@"org.jivesoftware.smack.ConnectionConfiguration") newWithSignature:@"(Ljava/lang/String;ILjava/lang/String;)",host,port,service] autorelease];
}

+ (SmackPresence*)presenceWithType:(SmackPresenceType*)type {
    return [[NSClassFromString(@"org.jivesoftware.smack.packet.Presence") newWithSignature:@"(Lorg/jivesoftware/smack/packet/Presence$Type;)",type] autorelease];
}

+ (SmackPresence*)presenceWithTypeString:(NSString*)type {
    return [self presenceWithType:[SmackCocoaAdapter staticObjectField:type inJavaClass:@"org.jivesoftware.smack.packet.Presence$Type"]];
}

+ (SmackPresence*)presenceWithType:(SmackPresenceType*)type status:(NSString*)status priority:(int)priority mode:(SmackPresenceMode*)mode {
    return [[NSClassFromString(@"org.jivesoftware.smack.packet.Presence") newWithSignature:@"(Lorg/jivesoftware/smack/packet/Presence$Type;Ljava/lang/String;ILorg/jivesoftware/smack/packet/Presence$Mode;)",type,status,priority,mode] autorelease];
}

+ (SmackPresence*)presenceWithTypeString:(NSString*)type status:(NSString*)status priority:(int)priority modeString:(NSString*)mode {
    return [self presenceWithType:[SmackCocoaAdapter staticObjectField:type inJavaClass:@"org.jivesoftware.smack.packet.Presence$Type"] status:status priority:priority mode:[SmackCocoaAdapter staticObjectField:mode inJavaClass:@"org.jivesoftware.smack.packet.Presence$Mode"]];
}

+ (SmackMessage*)messageTo:(NSString*)to type:(SmackMessageType*)type {
    return [[NSClassFromString(@"org.jivesoftware.smack.packet.Message") newWithSignature:@"(Ljava/lang/String;Lorg/jivesoftware/smack/packet/Message$Type;)",to,type] autorelease];
}

+ (SmackMessage*)messageTo:(NSString*)to typeString:(NSString*)type {
    return [self messageTo:to type:[SmackCocoaAdapter staticObjectField:type inJavaClass:@"org.jivesoftware.smack.packet.Message$Type"]];
}

+ (SmackRegistration*)registration {
    return [[[NSClassFromString(@"org.jivesoftware.smack.packet.Registration") alloc] init] autorelease];
}

+ (SmackXXHTMLExtension*)XHTMLExtension {
    return [[[NSClassFromString(@"org.jivesoftware.smackx.packet.XHTMLExtension") alloc] init] autorelease];
}

+ (SmackIQ*)IQ {
    return [[[NSClassFromString(@"org.jivesoftware.smack.packet.IQ") alloc] init] autorelease];
}

+ (SmackIQType*)IQType:(NSString*)type {
    return [self staticObjectField:type inJavaClass:@"org.jivesoftware.smack.packet.IQ$Type"];
}

+ (SmackXMPPError*)XMPPErrorWithCode:(int)code {
    return [[NSClassFromString(@"org.jivesoftware.smack.packet.XMPPError") newWithSignature:@"(I)",code] autorelease];
}

+ (SmackXMPPError*)XMPPErrorWithCode:(int)code message:(NSString*)message {
    return [[NSClassFromString(@"org.jivesoftware.smack.packet.XMPPError") newWithSignature:@"(ILjava/lang/String;)",code,message] autorelease];
}

+ (void)createRosterEntryInRoster:(SmackRoster*)roster withJID:(NSString*)jid name:(NSString*)name group:(NSString*)group {
    [NSClassFromString(@"net.adium.smackBridge.SmackBridge") createRosterEntry:roster :jid :name :group];
}

+ (SmackXForm*)formWithType:(NSString*)type {
    return [[NSClassFromString(@"org.jivesoftware.smackx.Form") newWithSignature:@"(Ljava/lang/String;)",type] autorelease];
}

+ (SmackXForm*)formFromPacket:(SmackPacket*)packet {
    return [NSClassFromString(@"org.jivesoftware.smackx.Form") getFormFrom:packet];
}

+ (SmackXForm*)fixedFormField {
    return [[[NSClassFromString(@"org.jivesoftware.smackx.FormField") alloc] init] autorelease];
}

+ (SmackXFormField*)formFieldWithVariable:(NSString*)variable {
    return [[NSClassFromString(@"org.jivesoftware.smackx.FormField") newWithSignature:@"(Ljava/lang/String;)",variable] autorelease];
}

+ (id)invokeObject:(id)obj methodWithParamTypeAndParam:(NSString*)method, ... {
    va_list ap;
    va_start(ap, method);
    
    JavaVector *argumentTypes = [[NSClassFromString(@"java.util.Vector") alloc] init];
    JavaVector *arguments = [[NSClassFromString(@"java.util.Vector") alloc] init];
    NSString *typestr;
    
    while((typestr = va_arg(ap,id))) {
        if([typestr isEqualToString:@"int"]) {
            int value = va_arg(ap, int);
            id javaint = [NSClassFromString(@"java.lang.Integer") newWithSignature:@"(I)",value];
            
            [argumentTypes add:typestr];
            [arguments add:javaint];
            
            [javaint release];
        } else if([typestr isEqualToString:@"boolean"]) {
            BOOL value = va_arg(ap, int)?YES:NO;
            id javabool = [NSClassFromString(@"java.lang.Boolean") newWithSignature:@"(Z)",value];
            
            [argumentTypes add:typestr];
            [arguments add:javabool];
            
            [javabool release];
        } else if([typestr isEqualToString:@"double"]) {
            double value = va_arg(ap, double);
            id javadouble = [NSClassFromString(@"java.lang.Double") newWithSignature:@"(D)",value];
            
            [argumentTypes add:typestr];
            [arguments add:javadouble];
            
            [javadouble release];
        } else if([typestr isEqualToString:@"float"]) {
            float value = (float)va_arg(ap, double);
            id javafloat = [NSClassFromString(@"java.lang.Float") newWithSignature:@"(F)",value];
            
            [argumentTypes add:typestr];
            [arguments add:javafloat];
            
            [javafloat release];
        } else if([typestr isEqualToString:@"long"]) {
            long value = va_arg(ap, long);
            id javalong = [NSClassFromString(@"java.lang.Long") newWithSignature:@"(J)",value];
            
            [argumentTypes add:typestr];
            [arguments add:javalong];
            
            [javalong release];
        } else if([typestr isEqualToString:@"char"]) {
            char value = (char)va_arg(ap, int);
            id javachar = [NSClassFromString(@"java.lang.Char") newWithSignature:@"(C)",value];
            
            [argumentTypes add:typestr];
            [arguments add:javachar];
            
            [javachar release];
        } else if([typestr isEqualToString:@"short"]) {
            short value = (short)va_arg(ap, int);
            id javashort = [NSClassFromString(@"java.lang.Short") newWithSignature:@"(S)",value];
            
            [argumentTypes add:typestr];
            [arguments add:javashort];
            
            [javashort release];
        } else { // assume Java class
            NSString *type = typestr;
            id value = va_arg(ap, id);
            [argumentTypes add:type];
            [arguments add:value];
        }
    }
    
    NSMutableString *classname = [[obj className] mutableCopy];
    // -className returns the internal representation of the Java class (like java/lang/String), but we need the one used in the
    // Java language itself (java.lang.String)
    [classname replaceOccurrencesOfString:@"/" withString:@"." options:NSLiteralSearch range:NSMakeRange(0,[classname length])];
    [classname replaceOccurrencesOfString:@"$" withString:@"." options:NSLiteralSearch range:NSMakeRange(0,[classname length])];
    
    JavaMethod *meth = [NSClassFromString(@"net.adium.smackBridge.SmackBridge") getMethod:classname :method :argumentTypes];
    [classname release];
    
    id result = [NSClassFromString(@"net.adium.smackBridge.SmackBridge") invokeMethod:meth :obj :arguments];
    
    [argumentTypes release];
    [arguments release];
    
    va_end(ap);
    return result;
}

+ (JavaVector*)vector {
    return [[[NSClassFromString(@"java.util.Vector") alloc] init] autorelease];
}

+ (JavaMap*)map {
    return [[NSClassFromString(@"java.util.HashMap") newWithSignature:@"()"] autorelease];
}

+ (NSDictionary *)smackExceptionInfo:(NSException*)e {
    NSLog(@"exception!\nname = %@\nreason = %@\nuserInfo = %@",[e name],[e reason],[e userInfo]);
    return [NSDictionary dictionary];
}

@end

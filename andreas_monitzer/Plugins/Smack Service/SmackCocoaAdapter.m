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

#import <JavaVM/NSJavaVirtualMachine.h>

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
        
        NSLog(@"VM Thread = %p, main thread = %p",CFRunLoopGetCurrent(),CFRunLoopGetMain());
        
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
        
        connection = [NSClassFromString(useSSL?@"org.jivesoftware.smack.SSLXMPPConnection":@"org.jivesoftware.smack.XMPPConnection") newWithSignature:@"(Lorg/jivesoftware/smack/ConnectionConfiguration;)",conf];
        
        [bridge registerConnection:connection];
        [bridge release];
    }
    [pool release];
}

- (SmackXMPPConnection*)connection {
    return connection;
}

- (void)dealloc {
    [connection close];
    [connection release];
    [super dealloc];
}

- (void)setConnection:(JavaBoolean*)state {
    if([state booleanValue]) {
        AILog(@"XMPP Connection established");
        [account performSelectorOnMainThread:@selector(connected:) withObject:connection waitUntilDone:NO];
    } else {
        AILog(@"XMPP Connection closed.");
        [account performSelectorOnMainThread:@selector(disconnected:) withObject:connection waitUntilDone:NO];
    }
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

+ (id)invokeObject:(id)obj methodWithParamTypeAndParam:(NSString*)method, ... {
    va_list ap;
    va_start(ap, method);
    
    JavaVector *argumentTypes = [[NSClassFromString(@"java.util.Vector") alloc] init];
    JavaVector *arguments = [[NSClassFromString(@"java.util.Vector") alloc] init];
    NSString *typestr;
    
    while((typestr = va_arg(ap,id))) {
        if([typestr isEqualToString:@"int"]) {
            Class type = NSClassFromString(@"java.lang.Integer");
            int value = va_arg(ap, int);
            id javaint = [type newWithSignature:@"(I)",value];
            
            [argumentTypes add:type];
            [arguments add:javaint];
            
            [javaint release];
        } else if([typestr isEqualToString:@"boolean"]) {
            Class type = NSClassFromString(@"java.lang.Boolean");
            BOOL value = va_arg(ap, int)?YES:NO;
            id javabool = [type newWithSignature:@"(Z)",value];
            
            [argumentTypes add:type];
            [arguments add:javabool];
            
            [javabool release];
        } else if([typestr isEqualToString:@"double"]) {
            Class type = NSClassFromString(@"java.lang.Double");
            double value = va_arg(ap, double);
            id javadouble = [type newWithSignature:@"(D)",value];
            
            [argumentTypes add:type];
            [arguments add:javadouble];
            
            [javadouble release];
        } else if([typestr isEqualToString:@"float"]) {
            Class type = NSClassFromString(@"java.lang.Float");
            float value = (float)va_arg(ap, double);
            id javafloat = [type newWithSignature:@"(F)",value];
            
            [argumentTypes add:type];
            [arguments add:javafloat];
            
            [javafloat release];
        } else if([typestr isEqualToString:@"long"]) {
            Class type = NSClassFromString(@"java.lang.Long");
            long value = va_arg(ap, long);
            id javalong = [type newWithSignature:@"(J)",value];
            
            [argumentTypes add:type];
            [arguments add:javalong];
            
            [javalong release];
        } else if([typestr isEqualToString:@"char"]) {
            Class type = NSClassFromString(@"java.lang.Char");
            char value = (char)va_arg(ap, int);
            id javachar = [type newWithSignature:@"(C)",value];
            
            [argumentTypes add:type];
            [arguments add:javachar];
            
            [javachar release];
        } else if([typestr isEqualToString:@"short"]) {
            Class type = NSClassFromString(@"java.lang.Short");
            short value = (short)va_arg(ap, int);
            id javashort = [type newWithSignature:@"(S)",value];
            
            [argumentTypes add:type];
            [arguments add:javashort];
            
            [javashort release];
        } else { // assume Java class
            Class type = NSClassFromString(typestr);
            id value = va_arg(ap, id);
            [argumentTypes add:type];
            [arguments add:value];
        }
    }
    
    JavaMethod *meth = [NSClassFromString(@"net.adium.smackBridge.SmackBridge") getMethod:[obj className] :method :argumentTypes];
    id result = [meth invoke:obj :[arguments toArray]];
    
    [argumentTypes release];
    [arguments release];
    
    va_end(ap);
    return result;
}


@end

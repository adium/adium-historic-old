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
#import "AIAccountController.h"
#import "AIJavaController.h"

#import <JavaVM/NSJavaVirtualMachine.h>
#import <AIUtilities/AIStringUtilities.h>

#define SMACKBRIDGE_JAR @"SmackJavaBridge"
#define SMACK_JAR		@"smack"
#define SMACKX_JAR		@"smackx"

extern CFRunLoopRef CFRunLoopGetMain(void);
/* java.lang.Object */
@interface NSObject (JavaObjectAdditions)
+ (id)getProperty:(NSString *)property;
- (NSString *)toString;
@end

static JavaClassLoader *classLoader = nil;

@implementation SmackCocoaAdapter

+ (JavaClassLoader *)classLoader
{
    return classLoader;
}

+ (void)initializeJavaVM
{
//	[NSThread detachNewThreadSelector:@selector(prepareJavaVM)
//							 toTarget:self
//						   withObject:nil];

    NSString	*smackJarPath, *smackxJarPath, *smackBridgeJarPath;
    
    smackBridgeJarPath = [[NSBundle bundleForClass:[self class]] pathForResource:SMACKBRIDGE_JAR
                                                                          ofType:@"jar"
                                                                     inDirectory:@"Java"];
    smackJarPath = [[NSBundle bundleForClass:[self class]] pathForResource:SMACK_JAR
                                                                    ofType:@"jar"
                                                               inDirectory:@"Java"];
    smackxJarPath = [[NSBundle bundleForClass:[self class]] pathForResource:SMACKX_JAR
                                                                     ofType:@"jar"
                                                                inDirectory:@"Java"];

    classLoader = [[[[AIObject sharedAdiumInstance] javaController] classLoaderWithJARs:[NSArray arrayWithObjects:
        smackBridgeJarPath, smackJarPath, smackxJarPath,
        nil]] retain];
}

/*
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
				  [[classLoader loadClass:@"java.lang.System"] getProperty:@"java.version"],
				  [[classLoader loadClass:@"org.jivesoftware.smack.SmackConfiguration"] getVersion],
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
			![classLoader loadClass:@"org.jivesoftware.smack.SmackConfiguration"]) {
			NSMutableString	*msg = [NSMutableString string];
			
			[msg appendFormat:@"Java version %@ could not load SmackConfiguration\n",[[classLoader loadClass:@"java.lang.System"] getProperty:@"java.version"]];
            
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
*/
#pragma mark utility functions

+ (id)enumWithType:(NSString*)type name:(NSString*)name {
    return [(Class <JavaEnum>)[classLoader loadClass:@"java.lang.Enum"] valueOf:[classLoader loadClass:type] :name];
}

+ (id)staticObjectField:(NSString*)fieldname inJavaClass:(NSString*)className {
    return [(Class <AdiumSmackBridge>)[classLoader loadClass:@"net.adium.smackBridge.SmackBridge"] getStaticFieldFromClass:fieldname :className];
}

+ (id)staticObjectField:(NSString*)fieldname inJavaClassObject:(Class <JavaObject>)classobj {
    return [(Class <AdiumSmackBridge>)[classLoader loadClass:@"net.adium.smackBridge.SmackBridge"] getStaticFieldFromClassObject:fieldname :classobj];
}

+ (BOOL)object:(id)obj isInstanceOfJavaClass:(NSString*)className {
    return [(Class <AdiumSmackBridge>)[classLoader loadClass:@"net.adium.smackBridge.SmackBridge"] isInstanceOfClass:obj :className];
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
        
        [account getProxyConfigurationNotifyingTarget:self selector:@selector(spawnConnectionWithProxy:account:) context:inAccount];
    }
    return self;
}

- (void)spawnConnectionWithProxy:(NSDictionary*)proxyinfo account:(SmackXMPPAccount*)inAccount
{
    // establish Java proxy settings
    JavaProperties *systemProperties = [(Class <JavaSystem>)[classLoader loadClass:@"java.lang.System"] getProperties];
    AdiumProxyType type = (AdiumProxyType)[[proxyinfo objectForKey:@"AdiumProxyType"] intValue];
    
    if ((type == Adium_Proxy_SOCKS4) || (type == Adium_Proxy_SOCKS5) || (type == Adium_Proxy_Default_SOCKS4) || (type == Adium_Proxy_Default_SOCKS5)) {
        [systemProperties put:@"socksProxyHost" :[proxyinfo objectForKey:@"Host"]];
        [systemProperties put:@"socksProxyPort" :[[proxyinfo objectForKey:@"Port"] description]];
        if([[proxyinfo objectForKey:@"Username"] length] > 0)
        {
            [systemProperties put:@"java.net.socks.username" :[proxyinfo objectForKey:@"Username"]];
            [systemProperties put:@"java.net.socks.password" :[proxyinfo objectForKey:@"Password"]];
        } else {
            [systemProperties remove:@"java.net.socks.username"];
            [systemProperties remove:@"java.net.socks.password"];
        }

    } else {
        [systemProperties remove:@"socksProxyHost"];
        [systemProperties remove:@"socksProxyPort"];
        [systemProperties remove:@"java.net.socks.username"];
        [systemProperties remove:@"java.net.socks.password"];
        
        if (type != Adium_Proxy_None)
            [[adium interfaceController] handleErrorMessage:AILocalizedString(@"Proxy Settings", nil)
											withDescription:AILocalizedString(@"HTTP proxies are currently not supported. The connection attempt will continue without the proxy.", nil)];
    }
    
    // start connection
    [NSThread detachNewThreadSelector:@selector(runConnection:) toTarget:self withObject:inAccount];
}

- (void)runConnection:(SmackXMPPAccount*)inAccount {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    SmackConnectionConfiguration *conf = [inAccount connectionConfiguration];
    if(conf) {
        BOOL useSSL = NO; //[[inAccount preferenceForKey:@"useSSL" group:GROUP_ACCOUNT_STATUS] boolValue];
        
        // create connection
        AdiumSmackBridge *bridge = [[[classLoader loadClass:@"net.adium.smackBridge.SmackBridge"] alloc] init];
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
    [[adium interfaceController] handleErrorMessage:[NSString stringWithFormat:AILocalizedString(@"Connection error on account %@.", nil),[account explicitFormattedUID]] withDescription:[e reason]];
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
    return [[[classLoader loadClass:@"org.jivesoftware.smack.ConnectionConfiguration"] newWithSignature:@"(Ljava/lang/String;ILjava/lang/String;)",host,port,service] autorelease];
}

+ (SmackPresence*)presenceWithType:(SmackPresenceType*)type {
    return [[[classLoader loadClass:@"org.jivesoftware.smack.packet.Presence"] newWithSignature:@"(Lorg/jivesoftware/smack/packet/Presence$Type;)",type] autorelease];
}

+ (SmackPresence*)presenceWithTypeString:(NSString*)type {
    return [self presenceWithType:[SmackCocoaAdapter enumWithType:@"org.jivesoftware.smack.packet.Presence$Type" name:type]];
}

+ (SmackPresence*)presenceWithType:(SmackPresenceType*)type status:(NSString*)status priority:(int)priority mode:(SmackPresenceMode*)mode {
    return [[[classLoader loadClass:@"org.jivesoftware.smack.packet.Presence"] newWithSignature:@"(Lorg/jivesoftware/smack/packet/Presence$Type;Ljava/lang/String;ILorg/jivesoftware/smack/packet/Presence$Mode;)",type,status,priority,mode] autorelease];
}

+ (SmackPresence*)presenceWithTypeString:(NSString*)type status:(NSString*)status priority:(int)priority modeString:(NSString*)mode {
    return [self presenceWithType:[SmackCocoaAdapter enumWithType:@"org.jivesoftware.smack.packet.Presence$Type" name:type] status:status priority:priority mode:[SmackCocoaAdapter enumWithType:@"org.jivesoftware.smack.packet.Presence$Mode" name:mode]];
}

+ (SmackMessage*)message {
    return [[[classLoader loadClass:@"org.jivesoftware.smack.packet.Message"] newWithSignature:@"()"] autorelease];
}

+ (SmackMessage*)messageTo:(NSString*)to type:(SmackMessageType*)type {
    return [[[classLoader loadClass:@"org.jivesoftware.smack.packet.Message"] newWithSignature:@"(Ljava/lang/String;Lorg/jivesoftware/smack/packet/Message$Type;)",to,type] autorelease];
}

+ (SmackMessage*)messageTo:(NSString*)to typeString:(NSString*)type {
    return [self messageTo:to type:[self messageTypeFromString:type]];
}

+ (SmackMessageType*)messageTypeFromString:(NSString*)type {
    return [SmackCocoaAdapter staticObjectField:type inJavaClass:@"org.jivesoftware.smack.packet.Message$Type"];
}

+ (SmackRegistration*)registration {
    return [[[[classLoader loadClass:@"org.jivesoftware.smack.packet.Registration"] alloc] init] autorelease];
}

+ (SmackXServiceDiscoveryManager*)serviceDiscoveryManagerForConnection:(SmackXMPPConnection*)connection {
    return [(Class <SmackXServiceDiscoveryManager>)[classLoader loadClass:@"org.jivesoftware.smackx.ServiceDiscoveryManager"] getInstanceFor:connection];
}

+ (SmackXXHTMLExtension*)XHTMLExtension {
    return [[[[classLoader loadClass:@"org.jivesoftware.smackx.packet.XHTMLExtension"] alloc] init] autorelease];
}

+ (SmackIQ*)IQ {
    return [[[[classLoader loadClass:@"org.jivesoftware.smack.packet.IQ"] alloc] init] autorelease];
}

+ (SmackIQType*)IQType:(NSString*)type {
    return [self staticObjectField:type inJavaClass:@"org.jivesoftware.smack.packet.IQ$Type"];
}

+ (SmackInvisibleCommand*)invisibleCommandForInvisibility:(BOOL)invisible {
    return [[(id)[classLoader loadClass:@"net.adium.smackBridge.InvisibleCommand"] newWithSignature:@"(Z)",invisible] autorelease];
}

+ (SmackXMPPError*)XMPPErrorWithCode:(int)code {
    return [[[classLoader loadClass:@"org.jivesoftware.smack.packet.XMPPError"] newWithSignature:@"(I)",code] autorelease];
}

+ (SmackXMPPError*)XMPPErrorWithCode:(int)code message:(NSString*)message {
    return [[[classLoader loadClass:@"org.jivesoftware.smack.packet.XMPPError"] newWithSignature:@"(ILjava/lang/String;)",code,message] autorelease];
}

+ (void)createRosterEntryInRoster:(SmackRoster*)roster withJID:(NSString*)jid name:(NSString*)name group:(NSString*)group {
    [(Class <AdiumSmackBridge>)[classLoader loadClass:@"net.adium.smackBridge.SmackBridge"] createRosterEntry:roster :jid :name :group];
}

+ (SmackXForm*)formWithType:(NSString*)type {
    return [[[classLoader loadClass:@"org.jivesoftware.smackx.Form"] newWithSignature:@"(Ljava/lang/String;)",type] autorelease];
}

+ (SmackXForm*)formFromPacket:(SmackPacket*)packet {
    return [(Class <SmackXForm>)[classLoader loadClass:@"org.jivesoftware.smackx.Form"] getFormFrom:packet];
}

+ (SmackXFormField*)fixedFormField {
    return [[[[classLoader loadClass:@"org.jivesoftware.smackx.FormField"] alloc] init] autorelease];
}

+ (SmackXFormField*)formFieldWithVariable:(NSString*)variable {
    return [[[classLoader loadClass:@"org.jivesoftware.smackx.FormField"] newWithSignature:@"(Ljava/lang/String;)",variable] autorelease];
}

+ (id)invokeObject:(id)obj methodWithParamTypeAndParam:(NSString*)method, ... {
    va_list ap;
    va_start(ap, method);
    
    JavaVector *argumentTypes = [[[classLoader loadClass:@"java.util.Vector"] alloc] init];
    JavaVector *arguments = [[[classLoader loadClass:@"java.util.Vector"] alloc] init];
    NSString *typestr;
    
    while((typestr = va_arg(ap,id))) {
        if([typestr isEqualToString:@"int"]) {
            int value = va_arg(ap, int);
            id javaint = [[classLoader loadClass:@"java.lang.Integer"] newWithSignature:@"(I)",value];
            
            [argumentTypes add:typestr];
            [arguments add:javaint];
            
            [javaint release];
        } else if([typestr isEqualToString:@"boolean"]) {
            BOOL value = va_arg(ap, int)?YES:NO;
            id javabool = [[classLoader loadClass:@"java.lang.Boolean"] newWithSignature:@"(Z)",value];
            
            [argumentTypes add:typestr];
            [arguments add:javabool];
            
            [javabool release];
        } else if([typestr isEqualToString:@"double"]) {
            double value = va_arg(ap, double);
            id javadouble = [[classLoader loadClass:@"java.lang.Double"] newWithSignature:@"(D)",value];
            
            [argumentTypes add:typestr];
            [arguments add:javadouble];
            
            [javadouble release];
        } else if([typestr isEqualToString:@"float"]) {
            float value = (float)va_arg(ap, double);
            id javafloat = [[classLoader loadClass:@"java.lang.Float"] newWithSignature:@"(F)",value];
            
            [argumentTypes add:typestr];
            [arguments add:javafloat];
            
            [javafloat release];
        } else if([typestr isEqualToString:@"long"]) {
            long value = va_arg(ap, long);
            id javalong = [[classLoader loadClass:@"java.lang.Long"] newWithSignature:@"(J)",value];
            
            [argumentTypes add:typestr];
            [arguments add:javalong];
            
            [javalong release];
        } else if([typestr isEqualToString:@"char"]) {
            char value = (char)va_arg(ap, int);
            id javachar = [[classLoader loadClass:@"java.lang.Char"] newWithSignature:@"(C)",value];
            
            [argumentTypes add:typestr];
            [arguments add:javachar];
            
            [javachar release];
        } else if([typestr isEqualToString:@"short"]) {
            short value = (short)va_arg(ap, int);
            id javashort = [[classLoader loadClass:@"java.lang.Short"] newWithSignature:@"(S)",value];
            
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
    
    JavaMethod *meth = [(Class <AdiumSmackBridge>)[classLoader loadClass:@"net.adium.smackBridge.SmackBridge"] getMethod:classname :method :argumentTypes];
    [classname release];
    
    id result = [(Class <AdiumSmackBridge>)[classLoader loadClass:@"net.adium.smackBridge.SmackBridge"] invokeMethod:meth :obj :arguments];
    
    [argumentTypes release];
    [arguments release];
    
    va_end(ap);
    return result;
}

+ (JavaVector*)vector {
    return [[[[classLoader loadClass:@"java.util.Vector"] alloc] init] autorelease];
}

+ (JavaMap*)map {
    return [[[classLoader loadClass:@"java.util.HashMap"] newWithSignature:@"()"] autorelease];
}

+ (JavaFile*)fileFromPath:(NSString*)path {
    return [[[classLoader loadClass:@"java.io.File"] newWithSignature:@"(Ljava/lang/String;)", path] autorelease];
}

+ (NSDictionary *)smackExceptionInfo:(NSException*)e {
    NSLog(@"exception!\nname = %@\nreason = %@\nuserInfo = %@",[e name],[e reason],[e userInfo]);
    return [NSDictionary dictionary];
}

@end

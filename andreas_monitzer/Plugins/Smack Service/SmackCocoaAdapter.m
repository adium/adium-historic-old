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
    AILog(@"XMPP: new message packet!");
    [account performSelectorOnMainThread:@selector(receiveMessagePacket:) withObject:packet waitUntilDone:NO];
}
- (void)setNewPresencePacket:(SmackPacket*)packet {
    AILog(@"XMPP: new presence packet!");
    [account performSelectorOnMainThread:@selector(receivePresencePacket:) withObject:packet waitUntilDone:NO];
}
- (void)setNewIQPacket:(SmackPacket*)packet {
    AILog(@"XMPP: new IQ packet!");
    [account performSelectorOnMainThread:@selector(receiveIQPacket:) withObject:packet waitUntilDone:NO];
}

/*- (void)setRosterEntriesAdded:(JavaCollection*)addresses {
    
}

- (void)setRosterEntriesUpdated:(JavaCollection*)addresses {
    
}

- (void)setRosterEntriesDeleted:(JavaCollection*)addresses {
    
}

- (void)setRosterPresenceChanged:(NSString*)xmppAddress {
    AILog(@"XMPP: roster presence changed: \"%@\"",xmppAddress);
}*/

@end

//
//  SmackXMPPPhonePlugin.m
//  Adium
//
//  Created by Andreas Monitzer on 2006-08-14.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import "SmackXMPPPhonePlugin.h"
#import "SmackXMPPAccount.h"
#import <AddressBook/ABPeoplePickerView.h>
#import <AddressBook/ABRecord.h>
#import "AIJavaController.h"
#import "AIAccountController.h"

#import "SmackCocoaAdapter.h"
#import "SmackInterfaceDefinitions.h"
#import <AIUtilities/AIStringUtilities.h>

#define ASTERISKIM_JAR @"asterisk-im-client"
#define CONCURRENT_JAR @"backport-util-concurrent"

static JavaClassLoader *classLoader = nil;
static JavaClass *asterisklistener = nil;

@interface SmackPhoneEventStatus : NSObject {
}

- (BOOL)equals:(id)o;
- (NSString*)name;

@end

@protocol SmackPhoneEvent

- (NSString*)getCallID;
- (NSString*)getDevice;
- (SmackPhoneEventStatus*)getEventStatus;

@end

@interface SmackPhoneCall : NSObject {
}

- (NSString*)getId;
- (BOOL)isActive;

@end

@interface SmackPhoneEventDispatcher : NSObject {
}

- (void)dispatchEvent:(id<SmackPhoneEvent>)event;

@end

@interface SmackPhoneRingEvent : NSObject <SmackPhoneEvent, SmackPacketExtension> {
}

- (SmackPhoneCall*)getCall;
- (NSString*)getCallerID;
- (NSString*)getCallerIDName;
- (void)initCall:(SmackPhoneEventDispatcher*)dispatcher;

@end

@interface SmackPhoneDialedEvent : NSObject <SmackPhoneEvent, SmackPacketExtension> {
}

- (SmackPhoneCall*)getCall;
- (void)initCall:(SmackPhoneEventDispatcher*)dispatcher;

@end

@interface SmackPhoneOnPhoneEvent : NSObject <SmackPhoneEvent, SmackPacketExtension> {
}

- (SmackPhoneCall*)getCall;
- (NSString*)getCallerID;
- (NSString*)getCallerIDName;
- (void)initCall:(SmackPhoneEventDispatcher*)dispatcher;

@end

@interface SmackPhoneHangUpEvent : NSObject <SmackPhoneEvent, SmackPacketExtension> {
}
@end

@interface SmackPhoneClient : NSObject {
}

- (void)dialByExtension:(NSString*)extension;
- (void)forward:(SmackPhoneCall*)call :(NSString*)extension;
- (void)forwardByJID:(SmackPhoneCall*)call :(NSString*)jid;
- (BOOL)isPhoneEnabled:(NSString*)jid;

@end

@interface SmackCocoaAdapter (AsteriskPlugin)

+ (void)loadAsteriskPlugin;
+ (SmackXDiscoverItems*)discoverItems;
+ (SmackXDiscoverInfo*)discoverInfo;
+ (SmackPhoneClient*)phoneListenerForConnection:(SmackXMPPConnection*)connection delegate:(id)delegate;

@end

@implementation SmackCocoaAdapter (AsteriskPlugin)

+ (void)loadAsteriskPlugin
{
    if(!classLoader)
    {
        NSString *asteriskIMJarPath = [[NSBundle bundleForClass:[self class]] pathForResource:ASTERISKIM_JAR
                                                                                       ofType:@"jar"
                                                                                  inDirectory:@"Java"];
        NSString *concurrentJarPath = [[NSBundle bundleForClass:[self class]] pathForResource:CONCURRENT_JAR
                                                                                       ofType:@"jar"
                                                                                  inDirectory:@"Java"];
        
        classLoader = [[[AIObject sharedAdiumInstance] javaController] classLoaderWithJARs:[NSArray arrayWithObjects:asteriskIMJarPath, concurrentJarPath, nil] parentClassLoader:[self classLoader]];
    }
}

+ (SmackXDiscoverItems*)discoverItems
{
    return [[[[[self classLoader] loadClass:@"org.jivesoftware.smackx.packet.DiscoverItems"] alloc] init] autorelease];
}

+ (SmackXDiscoverInfo*)discoverInfo
{
    return [[[[[self classLoader] loadClass:@"org.jivesoftware.smackx.packet.DiscoverInfo"] alloc] init] autorelease];
}

+ (SmackPhoneClient*)phoneListenerForConnection:(SmackXMPPConnection*)connection delegate:(id)delegate
{
    return [[(id)[classLoader loadClass:@"net.adium.smackBridge.SmackXMPPAsteriskListener"] newWithSignature:@"(Lorg/jivesoftware/smack/XMPPConnection;Ljava/lang/ClassLoader;Lcom/apple/cocoa/foundation/NSObject;)",connection,classLoader,delegate] autorelease];
}

@end

@implementation SmackXMPPPhonePlugin

- (id)initWithAccount:(SmackXMPPAccount*)a
{
    if((self = [super init]))
    {
        account = a;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receivedIQPacket:)
                                                     name:SmackXMPPIQPacketReceivedNotification
                                                   object:account];
    }
    return self;
}

- (void)dealloc
{
    [phonejid release];
    [listener release];
    [currentCall release];
    [currentCallID release];
    [super dealloc];
}

- (void)connected:(SmackXMPPConnection*)connection
{
    SmackXDiscoverItems *packet = [SmackCocoaAdapter discoverItems];
    discoID = [[packet getPacketID] retain];
    [connection performSelector:@selector(sendPacket:) withObject:packet afterDelay:0.0];
    isSupported = NO;
}

- (void)disconnected:(SmackXMPPConnection*)connection
{
    isSupported = NO;
    [phonejid release];
    phonejid = nil;
    [listener release];
    listener = nil;
    [discoID release];
    discoID = nil;
    [currentCallID release];
    currentCallID = nil;
}

- (void)receivedIQPacket:(NSNotification*)notification
{
    if(!discoID)
        return;
    
    // try to detect if the server supports the phone service
    SmackIQ *iq = [[notification userInfo] objectForKey:SmackXMPPPacket];
    if([SmackCocoaAdapter object:iq isInstanceOfJavaClass:@"org.jivesoftware.smackx.packet.DiscoverItems"])
    {
        if([[iq getPacketID] isEqualToString:discoID])
        {
            [discoID release];
            discoID = nil;
            JavaIterator *iter = [(SmackXDiscoverItems*)iq getItems];
            
            while([iter hasNext])
            {
                SmackXDiscoverItem *item = [iter next];
                if([[item getName] isEqualToString:@"phone"])
                {
                    @try {
                        listener = [[SmackCocoaAdapter phoneListenerForConnection:[account connection] delegate:self] retain];
                    } @catch(NSException *e) {
                        NSLog(@"%@",e);
                        return;
                    }
                    if(!listener)
                    {
                        NSLog(@"Smack: Failed creating Phone Listener, phone service disabled.");
                        return;
                    }
                    
                    // the server has phone support, so load the library and GUI for it
                    // this is done that way in order to avoid loading the library and nib when it's not needed
                    [NSBundle loadNibNamed:@"SmackXMPPPhoneControl" owner:self];
                    if(!window)
                    {
                        NSLog(@"Failed loading SmackXMPPPhoneControl.nib!");
                        [listener release];
                        listener = nil;
                        return;
                    }
                    
                    [phonejid release];
                    phonejid = [[item getEntityID] retain];
                    
                    [window setTitle:[NSString stringWithFormat:AILocalizedString(@"%@ Telephone System","asterisk plugin window title, %@ = phone service name"),phonejid]];
                    [peoplePicker setAccessoryView:numberfieldview];
                    [peoplePicker setAutosaveName:[NSString stringWithFormat:@"%@ peoplepicker",phonejid]]; // do not localize!
                    [peoplePicker setTarget:self];
                    [peoplePicker setNameDoubleAction:@selector(dial:)];
                    
                    [[NSNotificationCenter defaultCenter] addObserver:self
                                                             selector:@selector(peopleSelectionChanged:)
                                                                 name:ABPeoplePickerValueSelectionDidChangeNotification
                                                               object:peoplePicker];
                    
                    isSupported = YES;
                    [SmackCocoaAdapter loadAsteriskPlugin];
                    
                    // reload accounts menu
                    [[adium notificationCenter] postNotificationName:Account_ListChanged
                                                              object:nil
                                                            userInfo:nil];
                    
                    break;
                }
            }
        }
    }
}

- (NSArray *)accountActionMenuItems
{
    NSMutableArray *menuItems = [NSMutableArray array];
    
    NSLog(@"Smack Phone: isSupported: %@",isSupported?@"YEP":@"NOPE");
    
    if(isSupported) {
        NSMenuItem *mitem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Telephone System","Telephone System") action:@selector(showWindow:) keyEquivalent:@""];
        [mitem setTarget:self];
        [menuItems addObject:mitem];
        [mitem release];
    }
    
    return menuItems;
}

- (IBAction)showWindow:(id)sender
{
    [window makeKeyAndOrderFront:nil];
}

- (void)setCurrentCall:(SmackPhoneCall*)call
{
    id old = currentCall;
    currentCall = [call retain];
    [old release];
}

- (void)setPhoneEvent:(id<SmackPhoneEvent>)event
{
    NSString *status = [[event getEventStatus] name];
    [currentCallID release];
    currentCallID = [[event getCallID] retain];
    
    if([status isEqualToString:@"RING"])
    {
        SmackPhoneRingEvent *ringevent = (SmackPhoneRingEvent*)event;
        
        [self setCurrentCall:[ringevent getCall]];
        [eventfield setStringValue:AILocalizedString(@"! RING !","Event is thrown when the user's phone is ringing.")];
        [eventfield setHidden:NO];
        
        [numberfield setStringValue:[ringevent getCallerID]];
    } else if([status isEqualToString:@"ON_PHONE"])
    {
        SmackPhoneOnPhoneEvent *onphoneevent = (SmackPhoneOnPhoneEvent*)event;
        
        [self setCurrentCall:[onphoneevent getCall]];
        [eventfield setStringValue:AILocalizedString(@"TALKING","This event will be dispatched when the user answer's his/her phone. This will also be sent when the user has called someone and the other party has picked up the phone.")];
        [eventfield setHidden:NO];

        [numberfield setStringValue:[onphoneevent getCallerID]];
    } else if([status isEqualToString:@"HANG_UP"])
    {
//        SmackPhoneHangUpEvent *hangupevent = (SmackPhoneHangUpEvent*)event;
        
        [self setCurrentCall:nil];
        [eventfield setHidden:YES];
    } else if([status isEqualToString:@"DIALED"])
    {
        SmackPhoneDialedEvent *dialedevent = (SmackPhoneDialedEvent*)event;
        
        [self setCurrentCall:[dialedevent getCall]];
        [eventfield setStringValue:AILocalizedString(@"DIALED","Event is dispatched when the user has dialed and we are waiting for someone to answer, this doesn't seem to be be dispatched when originating (PhoneClient#dial) calls with asterisk.")];
        [eventfield setHidden:NO];
    }
}

- (void)peopleSelectionChanged:(NSNotification*)notification
{
    ABRecord *phone = [[peoplePicker selectedValues] lastObject];
    if(phone)
        [numberfield setStringValue:phone];
}

#pragma mark Keypad

- (IBAction)dial0:(id)sender
{
    [numberfield insertText:@"0"];
}

- (IBAction)dial1:(id)sender
{
    [numberfield insertText:@"1"];
}

- (IBAction)dial2:(id)sender
{
    [numberfield insertText:@"2"];
}

- (IBAction)dial3:(id)sender
{
    [numberfield insertText:@"3"];
}

- (IBAction)dial4:(id)sender
{
    [numberfield insertText:@"4"];
}

- (IBAction)dial5:(id)sender
{
    [numberfield insertText:@"5"];
}

- (IBAction)dial6:(id)sender
{
    [numberfield insertText:@"6"];
}

- (IBAction)dial7:(id)sender
{
    [numberfield insertText:@"7"];
}

- (IBAction)dial8:(id)sender
{
    [numberfield insertText:@"8"];
}

- (IBAction)dial9:(id)sender
{
    [numberfield insertText:@"9"];
}

- (IBAction)dialPound:(id)sender
{
    [numberfield insertText:@"#"];
}

- (IBAction)dialAsterisk:(id)sender
{
    [numberfield insertText:@"*"];
}

#pragma mark Actions

- (IBAction)dial:(id)sender
{
    [window makeFirstResponder:nil];
    NSString *number = [numberfield stringValue];
    
    if([number rangeOfString:@"@"].location == NSNotFound)
        [[listener getPhoneClient] dialByExtension:number];
    else
        [[listener getPhoneClient] dialByJID:number];
}

- (IBAction)forward:(id)sender
{
    [window makeFirstResponder:nil];
    NSString *number = [numberfield stringValue];

    if([number rangeOfString:@"@"].location == NSNotFound)
        [[listener getPhoneClient] dialByExtension:number];
    else
        [[listener getPhoneClient] dialByJID:number];
}

- (IBAction)invite:(id)sender
{
    [window makeFirstResponder:nil];
    NSLog(@"invite %@",[numberfield stringValue]);
}

@end

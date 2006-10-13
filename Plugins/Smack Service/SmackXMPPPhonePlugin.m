//
//  SmackXMPPPhonePlugin.m
//  Adium
//
//  Created by Andreas Monitzer on 2006-08-14.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import "SmackXMPPPhonePlugin.h"
#import "SmackXMPPAccount.h"
#import "SmackCocoaAdapter.h"
#import "SmackInterfaceDefinitions.h"

#import <AddressBook/ABPeoplePickerView.h>
#import <AddressBook/ABRecord.h>

#import <Adium/AIAccount.h>
#import <Adium/AIListContact.h>
#import <Adium/AIJavaControllerProtocol.h>
#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIInterfaceControllerProtocol.h>
#import <AIUtilities/AIStringUtilities.h>

#define ASTERISKIM_JAR @"asterisk-im-client"

static JavaClassLoader *classLoader = nil;

@interface SmackPhoneEventStatus : NSObject {
}

- (BOOL)equals:(id)o;
- (NSString *)name;

@end

@protocol SmackPhoneEvent

- (NSString *)getCallID;
- (NSString *)getDevice;
- (SmackPhoneEventStatus*)getEventStatus;

@end

@interface SmackPhoneCall : NSObject {
}

- (NSString *)getId;
- (BOOL)isActive;

@end

@interface SmackPhoneEventDispatcher : NSObject {
}

- (void)dispatchEvent:(id<SmackPhoneEvent>)event;

@end

@interface SmackPhoneRingEvent : NSObject <SmackPhoneEvent, SmackPacketExtension> {
}

- (SmackPhoneCall*)getCall;
- (NSString *)getCallerID;
- (NSString *)getCallerIDName;
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
- (NSString *)getCallerID;
- (NSString *)getCallerIDName;
- (void)initCall:(SmackPhoneEventDispatcher*)dispatcher;

@end

@interface SmackPhoneHangUpEvent : NSObject <SmackPhoneEvent, SmackPacketExtension> {
}
@end

@interface SmackPhoneClient : NSObject {
}

- (void)dialByExtension:(NSString *)extension;
- (void)dialByJID:(NSString *)jid;
- (void)forward:(SmackPhoneCall*)call :(NSString *)extension;
- (void)forwardByJID:(SmackPhoneCall*)call :(NSString *)jid;
- (BOOL)isPhoneEnabled:(NSString *)jid;

@end

@interface SmackPhoneListener : NSObject {
}

- (SmackPhoneClient*)getPhoneClient;

@end

@interface SmackPhoneStatusExtension : NSObject <SmackPacketExtension> {
}

- (NSString *)getStatus;

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
    if (!classLoader) {
        NSString *asteriskIMJarPath = [[NSBundle bundleForClass:[self class]] pathForResource:ASTERISKIM_JAR
                                                                                       ofType:@"jar"
                                                                                  inDirectory:@"Java"];
        
        classLoader = [[[[AIObject sharedAdiumInstance] javaController] classLoaderWithJARs:[NSArray arrayWithObject:asteriskIMJarPath] parentClassLoader:[self classLoader]] retain];
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
    return [[[classLoader loadClass:@"net.adium.smackBridge.SmackXMPPAsteriskListener"] newWithSignature:@"(Lorg/jivesoftware/smack/XMPPConnection;Ljava/lang/ClassLoader;Lcom/apple/cocoa/foundation/NSObject;)",connection,classLoader,delegate] autorelease];
}

@end

static BOOL registered = NO;

@implementation SmackXMPPPhonePlugin

- (id)initWithAccount:(SmackXMPPAccount*)a
{
    if ((self = [super init]))
    {
        account = a;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receivedIQPacket:)
                                                     name:SmackXMPPIQPacketReceivedNotification
                                                   object:account];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receivedPresencePacket:)
                                                     name:SmackXMPPPresencePacketReceivedNotification
                                                   object:account];
        if (!registered) {
            // our class is a tooltip plugin for displaying the phone status
            [[adium interfaceController] registerContactListTooltipEntry:self secondaryEntry:YES];
            registered = YES;
        }
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [phonejid release];
    [listener release];
    [currentCall release];
    [currentCallID release];
    [discoID release];
    [super dealloc];
}

- (void)connected:(SmackXMPPConnection*)connection
{
    SmackXDiscoverItems *packet = [SmackCocoaAdapter discoverItems];
    discoID = [[packet getPacketID] retain];
    [self performSelector:@selector(delayedSend:) withObject:packet afterDelay:0.0];
    isSupported = NO;
}

- (void)delayedSend:(SmackPacket*)packet
{
    SmackXMPPConnection *connection = [account connection];
    if (connection) // only do this if the connection didn't fail
        [connection sendPacket:packet];
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

#pragma mark Tooltip Handling

- (NSString *)labelForObject:(AIListObject *)inObject
{
	if ([inObject statusObjectForKey:@"XMPPPhoneStatus"])
        return AILocalizedString(@"Phone Status","phone status tooltip entry title");

	return nil;
}

- (NSAttributedString *)entryForObject:(AIListObject *)inObject
{
    if ((![inObject isKindOfClass:[AIListContact class]]) ||
		([(AIListContact *)inObject account] != account)) {
        return nil;
	}

    NSString *status = [inObject statusObjectForKey:@"XMPPPhoneStatus"];
    if (!status)
        return nil;

    if ([status isEqualToString:@"ON_PHONE"])
        return [[[NSAttributedString alloc] initWithString:AILocalizedString(@"On the phone","phone status tooltip entry on the phone")] autorelease];

    /* Just use the string as is if we don't know it. The proto-JEP doesn't mention any other
     * status than ON_PHONE, but you never know...
	 */
    return [[[NSAttributedString alloc] initWithString:status] autorelease];
}

#pragma mark Java Callbacks

- (void)receivedIQPacket:(NSNotification*)notification
{
    // try to detect if the server supports the phone service
    SmackIQ *iq = [[notification userInfo] objectForKey:SmackXMPPPacket];
    if (discoID && [SmackCocoaAdapter object:iq isInstanceOfJavaClass:@"org.jivesoftware.smackx.packet.DiscoverItems"])
    {
        if ([[iq getPacketID] isEqualToString:discoID])
        {
            [discoID release];
            discoID = nil;
            JavaIterator *iter = [(SmackXDiscoverItems*)iq getItems];
            
            while([iter hasNext])
            {
                SmackXDiscoverItem *item = [iter next];
                if ([[item getName] isEqualToString:@"phone"])
                {
                    @try {
                        listener = [[SmackCocoaAdapter phoneListenerForConnection:[account connection] delegate:self] retain];
                    } @catch(NSException *e) {
                        NSLog(@"%@",e);
                        return;
                    }
                    if (!listener)
                    {
                        NSLog(@"Smack: Failed creating Phone Listener, phone service disabled.");
                        return;
                    }
                    
                    // the server has phone support, so load the library and GUI for it
                    // this is done that way in order to avoid loading the library and nib when it's not needed
                    [NSBundle loadNibNamed:@"SmackXMPPPhoneControl" owner:self];
                    if (!window)
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
    } else if (isSupported && [SmackCocoaAdapter object:iq isInstanceOfJavaClass:@"org.jivesoftware.smackx.packet.DiscoverInfo"])
    {
        // check if that packet applies to us
        if ([[iq getFrom] isEqualToString:phonejid])
            [self performSelectorOnMainThread:@selector(receivedServiceDiscoveryForPhone:) withObject:iq waitUntilDone:YES];
    }
}

- (void)receivedServiceDiscoveryForPhone:(SmackXDiscoverInfo*)iq
{
    NSString *jid = [NSString stringWithFormat:@"%@@%@",[iq getNode],[[account UID] jidHost]];
    AIListContact *contact = [[adium contactController] existingContactWithService:[account service] account:account UID:jid];
    
    if (contact)
        [contact setStatusObject:[NSNumber numberWithBool:[iq containsFeature:@"http://jivesoftware.com/phone"]] forKey:@"XMPPPhoneSupport" notify:NotifyNow];
}

- (void)receivedPresencePacket:(NSNotification*)n
{
    SmackPresence *packet = [[n userInfo] objectForKey:SmackXMPPPacket];
    
    // prefilter everything that can be done in this secondary thread to avoid blocking the main thread when possible

    if (![[[packet getType] toString] isEqualToString:@"unavailable"])
        [self performSelectorOnMainThread:@selector(receivedPresencePacketMainThread:) withObject:n waitUntilDone:YES];
}

- (void)receivedPresencePacketMainThread:(NSNotification*)n
{
    SmackPresence *packet = [[n userInfo] objectForKey:SmackXMPPPacket];
    // the following line is the reason why we have to do this in the main thread
    AIListContact *contact = [[adium contactController] existingContactWithService:[account service] account:account UID:[[packet getFrom] jidUserHost]];
    
    if (contact)
    {
        if (isSupported && [[[packet getFrom] jidHost] isEqualToString:[[account UID] jidHost]])
        {
            // this phone service only works with people on the same server
            
            if (![contact statusObjectForKey:@"XMPPPhoneSupport"])
            {
                // we don't know if that user supports the phone service yet, so query the server
                SmackXDiscoverInfo *info = [SmackCocoaAdapter discoverInfo];
                [info setTo:phonejid];
                [info setNode:[[packet getFrom] jidUsername]];
                [[account connection] sendPacket:info];
            }
        }
        SmackPhoneStatusExtension *phonestatus = [packet getExtension:@"phone-status" :@"http://jivesoftware.com/xmlns/phone"];
        // the following sets to nil if there's no extension or the status is missing, which is what we want
        [contact setStatusObject:[phonestatus getStatus] forKey:@"XMPPPhoneStatus" notify:NotifyNow];
    }
}

- (NSArray *)accountActionMenuItems
{
    NSMutableArray *menuItems = [NSMutableArray array];
    
    if (isSupported) {
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

- (NSArray *)menuItemsForContact:(AIListContact *)inContact {
    NSMutableArray *menuItems = [NSMutableArray array];
    
    if (isSupported && [[inContact statusObjectForKey:@"XMPPPhoneSupport"] boolValue])
    {
        NSMenuItem *mitem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Call","Call") action:@selector(callContact:) keyEquivalent:@""];
        [mitem setTarget:self];
        [mitem setRepresentedObject:inContact];
        [menuItems addObject:mitem];
        [mitem release];
    }
    
    return menuItems;
}

- (void)callContact:(NSMenuItem*)sender
{
    AIListContact *contact = [sender representedObject];
    
    [[listener getPhoneClient] dialByJID:[[contact UID] jidUserHost]];
    // -jidUserHost wouldn't be required, but we'll do it anyways just to make sure
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
    
    if ([status isEqualToString:@"RING"])
    {
        SmackPhoneRingEvent *ringevent = (SmackPhoneRingEvent*)event;
        
        [self setCurrentCall:[ringevent getCall]];
        [eventfield setStringValue:AILocalizedString(@"! RING !","Event is thrown when the user's phone is ringing.")];
        [eventfield setHidden:NO];
        
        [numberfield setStringValue:[ringevent getCallerID]];
    } else if ([status isEqualToString:@"ON_PHONE"])
    {
        SmackPhoneOnPhoneEvent *onphoneevent = (SmackPhoneOnPhoneEvent*)event;
        
        [self setCurrentCall:[onphoneevent getCall]];
        [eventfield setStringValue:AILocalizedString(@"TALKING","This event will be dispatched when the user answer's his/her phone. This will also be sent when the user has called someone and the other party has picked up the phone.")];
        [eventfield setHidden:NO];

        [numberfield setStringValue:[onphoneevent getCallerID]];
    } else if ([status isEqualToString:@"HANG_UP"])
    {
//        SmackPhoneHangUpEvent *hangupevent = (SmackPhoneHangUpEvent*)event;
        
        [self setCurrentCall:nil];
        [eventfield setHidden:YES];
    } else if ([status isEqualToString:@"DIALED"])
    {
        SmackPhoneDialedEvent *dialedevent = (SmackPhoneDialedEvent*)event;
        
        [self setCurrentCall:[dialedevent getCall]];
        [eventfield setStringValue:AILocalizedString(@"DIALED","Event is dispatched when the user has dialed and we are waiting for someone to answer, this doesn't seem to be be dispatched when originating (PhoneClient#dial) calls with asterisk.")];
        [eventfield setHidden:NO];
    }
}

- (void)peopleSelectionChanged:(NSNotification*)notification
{
    NSString *phone = [[peoplePicker selectedValues] lastObject];
    if (phone)
        [numberfield setStringValue:phone];
}

#pragma mark Keypad

- (IBAction)dial0:(id)sender
{
    [window makeFirstResponder:nil];
    [numberfield setStringValue:[[numberfield stringValue] stringByAppendingString:@"0"]];
}

- (IBAction)dial1:(id)sender
{
    [window makeFirstResponder:nil];
    [numberfield setStringValue:[[numberfield stringValue] stringByAppendingString:@"1"]];
}

- (IBAction)dial2:(id)sender
{
    [window makeFirstResponder:nil];
    [numberfield setStringValue:[[numberfield stringValue] stringByAppendingString:@"2"]];
}

- (IBAction)dial3:(id)sender
{
    [window makeFirstResponder:nil];
    [numberfield setStringValue:[[numberfield stringValue] stringByAppendingString:@"3"]];
}

- (IBAction)dial4:(id)sender
{
    [window makeFirstResponder:nil];
    [numberfield setStringValue:[[numberfield stringValue] stringByAppendingString:@"4"]];
}

- (IBAction)dial5:(id)sender
{
    [window makeFirstResponder:nil];
    [numberfield setStringValue:[[numberfield stringValue] stringByAppendingString:@"5"]];
}

- (IBAction)dial6:(id)sender
{
    [window makeFirstResponder:nil];
    [numberfield setStringValue:[[numberfield stringValue] stringByAppendingString:@"6"]];
}

- (IBAction)dial7:(id)sender
{
    [window makeFirstResponder:nil];
    [numberfield setStringValue:[[numberfield stringValue] stringByAppendingString:@"7"]];
}

- (IBAction)dial8:(id)sender
{
    [window makeFirstResponder:nil];
    [numberfield setStringValue:[[numberfield stringValue] stringByAppendingString:@"8"]];
}

- (IBAction)dial9:(id)sender
{
    [window makeFirstResponder:nil];
    [numberfield setStringValue:[[numberfield stringValue] stringByAppendingString:@"9"]];
}

- (IBAction)dialPound:(id)sender
{
    [window makeFirstResponder:nil];
    [numberfield setStringValue:[[numberfield stringValue] stringByAppendingString:@"#"]];
}

- (IBAction)dialAsterisk:(id)sender
{
    [window makeFirstResponder:nil];
    [numberfield setStringValue:[[numberfield stringValue] stringByAppendingString:@"*"]];
}

#pragma mark Actions

- (IBAction)dial:(id)sender
{
    [window makeFirstResponder:nil];
    NSString *number = [numberfield stringValue];
    
    if ([number rangeOfString:@"@"].location == NSNotFound)
        [[listener getPhoneClient] dialByExtension:number];
    else
        [[listener getPhoneClient] dialByJID:number];
}

- (IBAction)forward:(id)sender
{
    [window makeFirstResponder:nil];
    NSString *number = [numberfield stringValue];

    if ([number rangeOfString:@"@"].location == NSNotFound)
        [[listener getPhoneClient] dialByExtension:number];
    else
        [[listener getPhoneClient] dialByJID:number];
}

- (IBAction)invite:(id)sender
{
    [window makeFirstResponder:nil];
    NSLog(@"invite %@",[numberfield stringValue]);
    // this even isn't mentioned in the proto-jep and the phone client, but there's an action in the library. I'll ignore it for now.
}

@end

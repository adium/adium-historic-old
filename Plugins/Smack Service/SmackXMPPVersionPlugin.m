//
//  SmackXMPPVersionPlugin.m
//  Adium
//
//  Created by Andreas Monitzer on 2006-08-03.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import "SmackXMPPVersionPlugin.h"
#import "SmackCocoaAdapter.h"
#import "SmackInterfaceDefinitions.h"
#import <Carbon/Carbon.h>
#import <AIUtilities/AIStringUtilities.h>
#import "SmackXMPPAccount.h"
#import "AIAdium.h"
#import "AIInterfaceController.h"
#import "AIListContact.h"
#import "SmackListContact.h"

@interface SmackCocoaAdapter (versionPlugin)

+ (SmackXVersion*)version;

@end

@implementation SmackCocoaAdapter (versionPlugin)

+ (SmackXVersion*)version
{
    return [[[[self classLoader] loadClass:@"org.jivesoftware.smackx.packet.Version"] newWithSignature:@"()"] autorelease];
}

@end

@implementation SmackXMPPVersionPlugin

- (id)initWithAccount:(SmackXMPPAccount*)a {
    if ((self = [super init])) {
        account = a;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receivedIQPacket:)
                                                     name:SmackXMPPIQPacketReceivedNotification
                                                   object:account];
    }
    return self;
}

- (void)receivedIQPacket:(NSNotification*)notification
{
    SmackIQ *packet = [[notification userInfo] objectForKey:SmackXMPPPacket];
    
    if ([SmackCocoaAdapter object:packet isInstanceOfJavaClass:@"org.jivesoftware.smackx.packet.Version"])
    {
        SmackXVersion *version = (SmackXVersion*)packet;
        if ([[[packet getType] toString] isEqualToString:@"get"])
        {
            // construct reply
            
            SmackXVersion *reply = [SmackCocoaAdapter version];
            
            NSDictionary *appinfo = [[NSBundle mainBundle] infoDictionary];
            
            [reply setName:[appinfo objectForKey:(NSString *)kCFBundleNameKey]];
            [reply setVersion:[appinfo objectForKey:(NSString *)kCFBundleVersionKey]];
            
            [reply setType:[SmackCocoaAdapter staticObjectField:@"RESULT" inJavaClass:@"org.jivesoftware.smack.packet.IQ$Type"]];
            
            OSErr tError;
            unsigned long tSystemVersionMajor,tSystemVersionMinor,tSystemVersionBugFix;
            
            tError=Gestalt(gestaltSystemVersionMajor,(long*)&tSystemVersionMajor);
            if (tError == noErr)
            {
                tError=Gestalt(gestaltSystemVersionMinor,(long*)&tSystemVersionMinor);
                if (tError == noErr)
                {
                    tError=Gestalt(gestaltSystemVersionBugFix,(long*)&tSystemVersionBugFix);
                    if (tError == noErr)
                    {
                        [reply setOs:[NSString stringWithFormat:@"Mac OS X %u.%u.%u",tSystemVersionMajor,tSystemVersionMinor,tSystemVersionBugFix]];
                    }
                }
            }
            
            [reply setTo:[packet getFrom]];
            [[account connection] sendPacket:reply];
        } else if ([[[packet getType] toString] isEqualToString:@"result"]) {
            [[adium interfaceController] handleMessage:[NSString stringWithFormat:AILocalizedString(@"Version Query Result From %@","Version Query Result From %@"),[packet getFrom]]
                                       withDescription:[NSString stringWithFormat:AILocalizedString(@"Application \"%@\", Version %@\nOperating System = %@","Application %@, Version %@\nOperating System = %@"),[version getName]?[version getName]:AILocalizedString(@"(unknown)","(unknown)"),[version getVersion]?[version getVersion]:AILocalizedString(@"(unknown)","(unknown)"),[version getOs]?[version getOs]:AILocalizedString(@"(unknown)","(unknown)")]
                                       withWindowTitle:AILocalizedString(@"Version Information","Version Information")];
        }
    }
}

- (NSArray *)menuItemsForContact:(AIListContact *)inContact {
//    if (![inContact statusObjectForKey:@"XMPPSubscriptionType"])
//        return nil; // not a contact from our contact list (might be groupchat)
    
    NSMutableArray *menuItems = [NSMutableArray array];
    
    NSMenuItem *mitem;
    if ([inContact isKindOfClass:[SmackListContact class]] || [[[inContact UID] jidResource] length] == 0)
        mitem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Get Client Version","Get Client Version") action:@selector(requestVersionInformation:) keyEquivalent:@""];
    else
        mitem = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:AILocalizedString(@"Get Client Version (%@)","Get Client Version (resource)"),[[inContact UID] jidResource]] action:@selector(requestVersionInformation:) keyEquivalent:@""];

    [mitem setTarget:self];
    [mitem setRepresentedObject:inContact];
    [menuItems addObject:mitem];
    [mitem release];
    
    return menuItems;
}

- (void)requestVersionInformation:(NSMenuItem*)mitem
{
    NSEnumerator *e;
    if (![[mitem representedObject] isKindOfClass:[SmackListContact class]])
        e = [[NSArray arrayWithObject:[mitem representedObject]] objectEnumerator];
    else
        e = [[(SmackListContact*)[mitem representedObject] containedObjects] objectEnumerator];
    AIListContact *contact;
    
    while((contact = [e nextObject]))
    {
        SmackXVersion *version = [SmackCocoaAdapter version];
        [version setType:[SmackCocoaAdapter staticObjectField:@"GET" inJavaClass:@"org.jivesoftware.smack.packet.IQ$Type"]];
        [version setTo:[contact UID]];
        
        [[account connection] sendPacket:version];
    }
}

@end

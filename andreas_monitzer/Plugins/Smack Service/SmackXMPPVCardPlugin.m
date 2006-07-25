//
//  SmackXMPPVCardPlugin.m
//  Adium
//
//  Created by Andreas Monitzer on 2006-07-25.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import "SmackXMPPVCardPlugin.h"
#import "SmackXMPPAccount.h"
#import "AIAdium.h"
#import <AIUtilities/AIStringUtilities.h>
#import "SmackCocoaAdapter.h"
#import "SmackInterfaceDefinitions.h"
#import "AIListContact.h"

@interface SmackCocoaAdapter (vCardPlugin)

+ (SmackXVCard*)vCard;

@end

@implementation SmackCocoaAdapter (vCardPlugin)

+ (SmackXVCard*)vCard
{
    return [[[NSClassFromString(@"org.jivesoftware.smackx.packet.VCard") alloc] init] autorelease];
}

@end

@implementation SmackXMPPAccount (vCardPlugin)

- (void)delayedUpdateContactStatus:(AIListContact *)inContact
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"XMPPUpdateContact"
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObject:inContact forKey:@"contact"]];
}

@end

@implementation SmackXMPPVCardPlugin

- (id)initWithAccount:(SmackXMPPAccount*)a
{
    if((self = [super init]))
    {
        account = a;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receivedPresencePacket:)
                                                     name:SmackXMPPPresencePacketReceivedNotification
                                                   object:account];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(updateContact:)
                                                     name:@"XMPPUpdateContact"
                                                   object:account];
    }
    return self;
}

// since getting the vCard is a synchronous API, we have to move to a secondary thread, get the vCard, and then move back
// (since Adium doesn't like being talked to from a secondary thread)
- (void)updateContact:(NSNotification*)notification
{
    [NSThread detachNewThreadSelector:@selector(updateContactThread:)
                             toTarget:self
                           withObject:[[notification userInfo] objectForKey:@"contact"]];
}

- (void)updateContactThread:(AIListContact*)inContact
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    SmackXVCard *vCard = [[SmackCocoaAdapter vCard] retain];
    @try {
        [vCard load:[account connection] :[inContact UID]];
    } @catch (NSException *e) {
        // probably a timeout happened
        
        NSXMLElement *root = [NSXMLNode elementWithName:@"html"];
        [root addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:@"http://www.w3.org/1999/xhtml"]];
        
        NSXMLElement *head = [NSXMLNode elementWithName:@"head"];
        [root addChild:head];
        
        [head addChild:[NSXMLNode elementWithName:@"style" children:[NSArray arrayWithObject:
            [NSXMLNode textWithStringValue:
                @"body { font-family:'Lucida Grande'; }"
                ]] attributes:[NSArray arrayWithObject:
                    [NSXMLNode attributeWithName:@"type" stringValue:@"text/css"]]]];
        
        NSXMLElement *body = [NSXMLNode elementWithName:@"body"];
        [root addChild:body];
        
        [body addChild:[NSXMLNode elementWithName:@"p" stringValue:AILocalizedString(@"Error loading vCard!","Error loading vCard!")]];
        [body addChild:[NSXMLNode elementWithName:@"p" stringValue:[e reason]]];
        
        NSXMLDocument *doc = [NSXMLNode documentWithRootElement:root];
        [doc setCharacterEncoding:@"UTF-8"];
        [doc setDocumentContentKind:NSXMLDocumentXHTMLKind];
        
        [self performSelectorOnMainThread:@selector(updateContactMainThread:) withObject:[NSArray arrayWithObjects:inContact,doc,nil] waitUntilDone:YES]; // wait, so the NSArray doesn't suddenly get released
        [pool release];
        return;
    }
    
    // convert vCard into XHTML
    // for performance reasons, this is done on the secondary thread
    
    NSXMLElement *root = [NSXMLNode elementWithName:@"html"];
    [root addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:@"http://www.w3.org/1999/xhtml"]];

    NSXMLElement *head = [NSXMLNode elementWithName:@"head"];
    [root addChild:head];
    
    [head addChild:[NSXMLNode elementWithName:@"style" children:[NSArray arrayWithObject:
                [NSXMLNode textWithStringValue:
                    @"body { font-family:'Lucida Grande'; }"
                    @"table { width: 100%; table-layout: fixed; }"
                    @"th { text-align: right; width: 180px; white-space: nowrap; vertical-align: top; }"
                    @"td { vertical-align: top; }"
                    ]] attributes:[NSArray arrayWithObject:
                    [NSXMLNode attributeWithName:@"type" stringValue:@"text/css"]]]];

    NSXMLElement *body = [NSXMLNode elementWithName:@"body"];
    [root addChild:body];
    
    NSXMLElement *table = [NSXMLNode elementWithName:@"table"];
    [body addChild:table];

#define row(title,content) [table addChild:[NSXMLNode elementWithName:@"tr" children:[NSArray arrayWithObjects: \
    [NSXMLNode elementWithName:@"th" stringValue:title], \
    [NSXMLNode elementWithName:@"td" stringValue:content], nil] attributes:nil]]
    
    // NICKNAME, PHOTO, BDAY, JABBERID, MAILER, TZ, GEO, TITLE, ROLE, LOGO, NOTE, PRODID, REV, SORT-STRING, SOUND, UID, URL, DESC
    row(AILocalizedString(@"First Name","vCard First Name"),[vCard getFirstName]);
    row(AILocalizedString(@"Middle Name","vCard Middle Name"),[vCard getMiddleName]);
    row(AILocalizedString(@"Last Name","vCard Last Name"),[vCard getLastName]);
    row(AILocalizedString(@"Title","vCard Title"),[vCard getField:@"TITLE"]);
    row(AILocalizedString(@"Nickname","vCard Nickname"),[vCard getNickName]);
    row(AILocalizedString(@"Birthday","vCard Birthday"),[vCard getField:@"BDAY"]);
    row(AILocalizedString(@"Organization","vCard Organization"),[vCard getOrganization]);
    row(AILocalizedString(@"Organization Unit","vCard Organization Unit"),[vCard getOrganizationUnit]);
    
    [table addChild:[NSXMLNode elementWithName:@"tr" children:[NSArray arrayWithObjects:
        [NSXMLNode elementWithName:@"th" stringValue:AILocalizedString(@"URL","vCard URL")],
        [NSXMLNode elementWithName:@"td" children:[NSArray arrayWithObject:
            [NSXMLNode elementWithName:@"a" children:[NSArray arrayWithObject:
                [NSXMLNode textWithStringValue:[vCard getField:@"URL"]]] attributes:[NSArray arrayWithObject:
                     [NSXMLNode attributeWithName:@"href" stringValue:[vCard getField:@"URL"]]
                    ]
                ]] attributes:nil
            ], nil] attributes:nil]];
    
    row(AILocalizedString(@"Description","vCard Description"),[vCard getField:@"DESC"]);
    row(AILocalizedString(@"Note","vCard Note"),[vCard getField:@"NOTE"]);
    
#undef row

    NSXMLDocument *doc = [NSXMLNode documentWithRootElement:root];
    [doc setCharacterEncoding:@"UTF-8"];
    [doc setDocumentContentKind:NSXMLDocumentXHTMLKind];
    
    [self performSelectorOnMainThread:@selector(updateContactMainThread:) withObject:[NSArray arrayWithObjects:inContact,doc,nil] waitUntilDone:YES]; // wait, so the NSArray doesn't suddenly get released
    [pool release];
}

- (void)updateContactMainThread:(NSArray*)params
{
    AIListContact *inContact = [params objectAtIndex:0];
    NSXMLDocument *doc = [params objectAtIndex:1];
    
    // note that converting to an attributed string can't happen on the secondary thread, since that method uses webkit,
    // which is not thread-safe
    NSAttributedString *result = [[NSAttributedString alloc] initWithHTML:
        [doc XMLDataWithOptions:NSXMLDocumentTidyHTML | NSXMLDocumentIncludeContentTypeDeclaration]
                                                                  options:
        [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:NSUTF8StringEncoding] forKey:NSCharacterEncodingDocumentOption]
                                                       documentAttributes:NULL];
    [inContact setProfile:result notify:NotifyNow];
    [result release];
}

- (void)receivedPresencePacket:(NSNotification*)notification
{
    
}

@end

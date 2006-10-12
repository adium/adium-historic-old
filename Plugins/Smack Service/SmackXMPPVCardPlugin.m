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
#import <AIUtilities/AIImageAdditions.h>
#import "SmackCocoaAdapter.h"
#import "SmackInterfaceDefinitions.h"
#import "AIListContact.h"
#import "AIInterfaceController.h"
#import "AIContactController.h"
#import "ESDebugAILog.h"

#import <JavaVM/NSJavaVirtualMachine.h>

@interface SmackCocoaAdapter (vCardPlugin)

+ (SmackXVCard*)vCard;
+ (void)setAvatar:(NSData*)avatar forVCard:(SmackXVCard*)vCard;
+ (NSData*)getAvatarForVCard:(SmackXVCard*)vCard;
+ (SmackVCardUpdateExtension*)VCardUpdateExtensionWithPhotoHash:(NSString*)hash;
+ (BOOL)avatarIsEmpty:(SmackXVCard*)vCard;

@end

@implementation SmackCocoaAdapter (vCardPlugin)

+ (SmackXVCard*)vCard
{
    return [[[[[self classLoader] loadClass:@"org.jivesoftware.smackx.packet.VCard"] alloc] init] autorelease];
}

+ (void)setAvatar:(NSData*)avatar forVCard:(SmackXVCard*)vCard
{
    [(Class)[[self classLoader] loadClass:@"net.adium.smackBridge.SmackBridge"] setVCardAvatar:vCard :avatar];
}

+ (NSData*)getAvatarForVCard:(SmackXVCard*)vCard
{
    return [(Class)[[self classLoader] loadClass:@"net.adium.smackBridge.SmackBridge"] getVCardAvatar:vCard];
}

+ (SmackVCardUpdateExtension*)VCardUpdateExtensionWithPhotoHash:(NSString*)hash
{
    SmackVCardUpdateExtension *ext = [[[self classLoader] loadClass:@"net.adium.smackBridge.VCardUpdateExtension"] newWithSignature:@"()"];
    [ext setPhoto:hash];
    return [ext autorelease];
}

+ (BOOL)avatarIsEmpty:(SmackXVCard*)vCard
{
    return [(Class)[[self classLoader] loadClass:@"net.adium.smackBridge.SmackBridge"] isAvatarEmpty:vCard];
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
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(updateStatus:)
                                                     name:SmackXMPPUpdateStatusNotification
                                                   object:account];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(complementPresence:)
                                                     name:SmackXMPPPresenceSentNotification
                                                   object:account];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [editorwindow release];
    [ownvCard release];
    [vCardPacket release];
    @synchronized(self) {
        [avatarhash release]; avatarhash = nil;
    }
    [resourcesBlockingAvatar release];
    [super dealloc];
}

- (void)connected:(SmackXMPPConnection*)conn
{
    resourcesBlockingAvatar = [[NSMutableArray alloc] init];
    
    // we're not logged in yet, defer the vcard updates until we are
    [self performSelector:@selector(delayedConnected) withObject:nil afterDelay:0.0];
}

- (void)delayedConnected
{   
    if([account connection]) { // only do this if the connection hasn't failed
        // sync local avatar to the one on the server
        avatarUpdateInProgress = YES;
        [NSThread detachNewThreadSelector:@selector(updateAvatarUploadingNewOne:) toTarget:self withObject:[NSNumber numberWithBool:YES]];
    }
}

- (void)disconnected:(SmackXMPPConnection*)conn
{
    [resourcesBlockingAvatar release];
    resourcesBlockingAvatar = nil;
}

#pragma mark Avatar Handling

- (void)complementPresence:(NSNotification*)notification
{
    if([resourcesBlockingAvatar count] == 0)
    {
        SmackPresence *presence = [[notification userInfo] objectForKey:SmackXMPPPacket];
        
        @synchronized(self) {
            [presence addExtension:[SmackCocoaAdapter VCardUpdateExtensionWithPhotoHash:avatarhash]];
        }
        
    }
}

- (void)updateStatus:(NSNotification*)notification
{
    if([[account statusObjectForKey:@"Online"] boolValue]) {
        NSString *key = [[notification userInfo] objectForKey:SmackXMPPStatusKey];
        // getting/setting the vCard is a blocking operation, so we'll use a secondary thread for it
        // ignore the new avatar if the old one wasn't published yet
        if(!avatarUpdateInProgress && [key isEqualToString:KEY_USER_ICON])
        {
            avatarUpdateInProgress = YES;
            [NSThread detachNewThreadSelector:@selector(updateAvatarUploadingNewOne:) toTarget:self withObject:[NSNumber numberWithBool:YES]];
        }
    }
}

- (void)updateAvatarUploadingNewOne:(NSNumber*)flag
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    @try {
        SmackXVCard *vCard = [SmackCocoaAdapter vCard];
        [vCard load:[account connection]];
        
        if(![flag boolValue])
        {
            // we don't want to upload ours, just update our own hash
            NSString *newhash = [vCard getAvatarHash];
            
            @synchronized(self) {
                [avatarhash release];
                // "If the BINVAL is empty or missing, advertise an empty photo element in future presence broadcasts."
                avatarhash = newhash?[newhash retain]:@"";
            }
        } else {
            // check if the server side hash is equal to the local one
            if(![[vCard getAvatarHash] isEqualToString:avatarhash])
            {
                NSData *data = [account userIconData];
                
                if(!data)
                {
                    // handle the case that we don't have any avatar set
                    [SmackCocoaAdapter setAvatar:nil forVCard:vCard];
                    
                    [vCard save:[account connection]];
                    
                    @synchronized(self) {
                        [avatarhash release];
                        avatarhash = @"";
                    }
                } else {
                    // convert to JPEG
                    // The reason we aren't using png is that Smack just assumes
                    // (according to the source code) this format, even though
                    // PNG is is only format support required by the JEP, JPEG is
                    // only recommended. Oh well...
                    NSImage *avatarimage = [[NSImage alloc] initWithData:data];
                    NSSize avatarsize = [avatarimage size];
                    
                    // scale down the image if it's too large (96x96 is max according to the spec)
                    if(avatarsize.width > 96.0 || avatarsize.height > 96.0)
                    {
                        NSImage *smallerimage;
                        NSSize newsize;
                        if(avatarsize.width > avatarsize.height)
                            smallerimage = [[NSImage alloc] initWithSize:newsize = NSMakeSize(96.0,96.0 * (avatarsize.height / avatarsize.width))];
                        else
                            smallerimage = [[NSImage alloc] initWithSize:newsize = NSMakeSize(96.0 * (avatarsize.width / avatarsize.height),96.0)];
                        [smallerimage lockFocus];
                        [avatarimage drawInRect:NSMakeRect(0.0,0.0,newsize.width,newsize.height) fromRect:NSMakeRect(0.0,0.0,avatarsize.width,avatarsize.height) operation:NSCompositeCopy fraction:1.0];
                        [smallerimage unlockFocus];
                        [avatarimage release];
                        avatarimage = smallerimage;
                    }
                    
                    NSData *jpgdata = [avatarimage JPEGRepresentation];
                    [avatarimage release];
                    
                    // cheap way to calculate SHA1 hash, just let Smack do it
                    NSString *serverhash = [vCard getAvatarHash];
                    [SmackCocoaAdapter setAvatar:jpgdata forVCard:vCard];
                    NSString *localhash = [vCard getAvatarHash];
                    
                    // do local and server-side avatars match?
                    if(![serverhash isEqualToString:localhash])
                        // otherwise, store on server
                        [vCard save:[account connection]];
                    
                    @synchronized(self) {
                        [avatarhash release];
                        avatarhash = [localhash retain];
                    }
                }
            }
        }

        // let the contacts know about our new avatar
        // this should better be handled by PEP, but that's not implemented anywhere yet
        [account performSelectorOnMainThread:@selector(broadcastCurrentPresence) withObject:nil waitUntilDone:YES];
    } @catch(NSException *e) {
//        [[adium interfaceController] handleErrorMessage:[NSString stringWithFormat:AILocalizedString(@"Error while handling avatar image on account %@.","Error while handling avatar image on account %@."),[account explicitFormattedUID]] withDescription:[e reason]];
        AILog(@"Error handling avatar image on account %@. Reason: %@",[account explicitFormattedUID],[e reason]);
    }
    
    avatarUpdateInProgress = NO;
    [pool release];
}

- (void)receivedPresencePacket:(NSNotification*)notification
{
    SmackPresence *presence = [[notification userInfo] objectForKey:SmackXMPPPacket];
    
    NSString *from = [presence getFrom];
    
    if([[from jidUserHost] isEqualToString:[[account explicitFormattedUID] jidUserHost]])
    {
        // See JEP-153 section 4.3 "Multiple Resources" for a description of the magic that
        // has to happen here.

        NSString *resource = [from jidResource];
        
        if([resource isEqualToString:[account resource]])
            return; // ignore presences for ourselves
        
        if([[[presence getType] toString] isEqualToString:@"unavailable"])
        {
            if([resourcesBlockingAvatar count] == 1 && [[resourcesBlockingAvatar lastObject] isEqualToString:resource])
            {
                [resourcesBlockingAvatar removeObject:resource];
                // now we're finally able to broadcast our avatar!
                avatarUpdateInProgress = YES;
                [NSThread detachNewThreadSelector:@selector(updateAvatarUploadingNewOne:) toTarget:self withObject:[NSNumber numberWithBool:NO]];
            } else
                [resourcesBlockingAvatar removeObject:resource];
            return;
        }
        
        SmackVCardUpdateExtension *ext = [presence getExtension:@"x" :@"vcard-temp:x:update"];
        
        if(!ext)
            /* If the presence stanza received from the other resource does not contain the update child element,
             * then the other resource does not support vCard-based avatars. That resource could modify the contents
             * of the vCard (including the photo element); because polling for vCard updates is not allowed, the
             * client MUST stop advertising the avatar image hash.
             */
        {
            [resourcesBlockingAvatar addObject:resource];
        }
        else {
            NSString *photo = [ext getPhoto];
            /* If the update child element is empty, then the other resource supports the protocol but does not have
             * its own avatar image. Therefore the client can ignore the other resource and continue to broadcast
             * the existing image hash.
             */
            if(photo)
            {
                /* If the update child element contains an empty photo element, then the other resource has updated
                 * the vCard with an empty BINVAL. Therefore the client MUST retrieve the vCard. If the retrieved
                 * vCard contains a photo element with an empty BINVAL, then the client MUST stop advertising the
                 * old image.
                 */
                if([photo length] == 0)
                {
                    SmackXVCard *vCard = [SmackCocoaAdapter vCard];
                    [vCard load:[account connection]];
                    
                    if([SmackCocoaAdapter avatarIsEmpty:vCard])
                    {
                        [resourcesBlockingAvatar addObject:resource];
                    }
                } else @synchronized(self) {
                    if(![photo isEqualToString:avatarhash])
                    {
                        /* If the update child element contains a non-empty photo element, then the client MUST compare
                        * the image hashes. If the hashes are identical, then the client can ignore the other resource
                        * and continue to broadcast the existing image hash. If the hashes are different, then the
                        * client MUST NOT attempt to resolve the conflict by uploading its avatar image again. Instead,
                        * it MUST defer to the content of the retrieved vCard by resetting its image hash (see below)
                        * and providing that hash in future presence broadcasts.
                        */
                        [avatarhash release];
                        avatarhash = [photo retain];
                    }
                }
            }
        }
    } else
        // don't block this thread!
        [NSThread detachNewThreadSelector:@selector(checkVCardPhoto:) toTarget:self withObject:[presence retain]];
}

- (void)checkVCardPhoto:(SmackPresence*)presence
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    // somebody else's presence, check for vcard photo
    SmackVCardUpdateExtension *ext = [presence getExtension:@"x" :@"vcard-temp:x:update"];
    
    if(ext)
    {
        NSString *uid = [[presence getFrom] jidUserHost];
        NSString *hash = [ext getPhoto];
        AIListContact *contact = [[adium contactController] existingContactWithService:[account service] account:account UID:uid];
        if(contact)
        {
            NSString *oldhash = [contact preferenceForKey:@"XMPP:IconHash" group:@"XMPP"];
            
            if(!oldhash || ![hash isEqualToString:oldhash])
            {
                NSData *avatar;
                if(!hash || [hash isEqualToString:@""]) // empty avatar?
                    avatar = [NSData data];
                else {
                    @try {
                        SmackXVCard *vCard = [SmackCocoaAdapter vCard];
                        [vCard load:[account connection] :uid];
                        
                        avatar = [SmackCocoaAdapter getAvatarForVCard:vCard];
                    } @catch(NSException *e) {
                        [presence release];
                        [pool release];
                        return;
                    }
                    
                    [contact setPreference:hash forKey:@"XMPP:IconHash" group:@"XMPP"];
                }
                
                if([avatar length] > 0) // don't remove the avatar
                    [self performSelectorOnMainThread:@selector(setAvatar:) withObject:[NSArray arrayWithObjects:avatar,contact,nil] waitUntilDone:YES];
            }
        } else
            NSLog(@"******* unknown contact %@",uid);
    }
    [presence release];// retained before forking
    [pool release];
}


- (void)setAvatar:(NSArray*)params
{
    NSData *data = [params objectAtIndex:0];
    
    [[params objectAtIndex:1] setServersideIconData:([data length]!=0)?data:nil notify:NotifyLater];

    [[params objectAtIndex:1] notifyOfChangedStatusSilently:[account silentAndDelayed]];
}

#pragma mark vCard Viewing And Editing

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
/*    row(AILocalizedString(@"First Name","vCard First Name"),[vCard getFirstName]);
    row(AILocalizedString(@"Middle Name","vCard Middle Name"),[vCard getMiddleName]);
    row(AILocalizedString(@"Last Name","vCard Last Name"),[vCard getLastName]);*/
    row(AILocalizedString(@"Full Name","vCard Full Name"),[vCard getField:@"FN"]);
    row(AILocalizedString(@"Title","vCard Title"),[vCard getField:@"TITLE"]);
    row(AILocalizedString(@"Nickname","vCard Nickname"),[vCard getNickName]);
    row(AILocalizedString(@"Birthday","vCard Birthday"),[vCard getField:@"BDAY"]);
    row(AILocalizedString(@"Phone (Home)","vCard Phone Home"),[vCard getPhoneHome:@"VOICE"]);
    row(AILocalizedString(@"Phone (Work)","vCard Phone Word"),[vCard getPhoneWork:@"VOICE"]);
    row(AILocalizedString(@"Email (Home)","vCard email Home"),[vCard getEmailHome]);
    row(AILocalizedString(@"Email (Work)","vCard email Word"),[vCard getEmailWork]);
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

- (NSArray *)accountActionMenuItems
{
    NSMutableArray *menuItems = [NSMutableArray array];
    
    NSMenuItem *mitem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Edit Own vCard...","Edit Own vCard...") action:@selector(editvCard:) keyEquivalent:@""];
    [mitem setTarget:self];
    [menuItems addObject:mitem];
    [mitem release];
    
    return menuItems;
}

- (void)editvCard:(NSMenuItem*)sender
{
    if(!editorwindow)
        [NSBundle loadNibNamed:@"SmackXMPPVCardEditor" owner:self];
    if(!editorwindow)
    {
        NSBeep();
        NSLog(@"Error loading SmackXMPPVCardEditor.nib!");
        return;
    }
    
    if(!ownvCard)
        [self reloadvCard:nil];
    [editorwindow makeKeyAndOrderFront:nil];
}

- (IBAction)reloadvCard:(id)sender
{
    vCardPacket = [[SmackCocoaAdapter vCard] retain];
    
    @try {
        [vCardPacket load:[account connection]];
    } @catch(NSException *e) {
        [[adium interfaceController] handleErrorMessage:AILocalizedString(@"Error Loading vCard","Error Loading vCard") withDescription:[e reason]];
        return;
    }
    
    [editorwindow makeFirstResponder:nil];
    [self willChangeValueForKey:@"ownvCard"];
    [ownvCard release];
    ownvCard = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
/*                  ([vCardPacket getFirstName]?[vCardPacket getFirstName]:@""), @"firstName",
                ([vCardPacket getMiddleName]?[vCardPacket getMiddleName]:@""), @"middleName",
                    ([vCardPacket getLastName]?[vCardPacket getLastName]:@""), @"lastName",*/
              ([vCardPacket getField:@"FN"]?[vCardPacket getField:@"FN"]:@""), @"fullName",
        ([vCardPacket getField:@"TITLE"]?[vCardPacket getField:@"TITLE"]:@""), @"title",
                    ([vCardPacket getNickName]?[vCardPacket getNickName]:@""), @"nickName",
                  ([vCardPacket getEmailWork]?[vCardPacket getEmailWork]:@""), @"emailWork",
                  ([vCardPacket getEmailHome]?[vCardPacket getEmailHome]:@""), @"emailHome",
         ([vCardPacket getEmailHome]?[vCardPacket getPhoneHome:@"VOICE"]:@""), @"phoneHome",
         ([vCardPacket getEmailHome]?[vCardPacket getPhoneWork:@"VOICE"]:@""), @"phoneWork",
            ([vCardPacket getOrganization]?[vCardPacket getOrganization]:@""), @"organization",
    ([vCardPacket getOrganizationUnit]?[vCardPacket getOrganizationUnit]:@""), @"organizationUnit",
          ([vCardPacket getField:@"DESC"]?[vCardPacket getField:@"DESC"]:@""), @"description",
          ([vCardPacket getField:@"NOTE"]?[vCardPacket getField:@"NOTE"]:@""), @"notes",
        ([vCardPacket getField:@"BDAY"]?[NSCalendarDate dateWithString:[vCardPacket getField:@"BDAY"] calendarFormat:@"%Y-%m-%d"]:nil), @"birthday",
        nil];
    [self didChangeValueForKey:@"ownvCard"];
    [editorwindow makeFirstResponder:fullnameField];
}

- (IBAction)savevCard:(id)sender
{
    [editorwindow makeFirstResponder:nil];
    
    [vCardPacket setField:@"FN" :[ownvCard objectForKey:@"fullName"]];
    [vCardPacket setField:@"TITLE" :[ownvCard objectForKey:@"title"]];
    [vCardPacket setNickName:[ownvCard objectForKey:@"nickName"]];
    [vCardPacket setEmailWork:[ownvCard objectForKey:@"emailWork"]];
    [vCardPacket setEmailHome:[ownvCard objectForKey:@"emailHome"]];
    [vCardPacket setPhoneWork:@"VOICE" :[ownvCard objectForKey:@"phoneWork"]];
    [vCardPacket setPhoneHome:@"VOICE" :[ownvCard objectForKey:@"phoneHome"]];
    [vCardPacket setOrganization:[ownvCard objectForKey:@"organization"]];
    [vCardPacket setOrganizationUnit:[ownvCard objectForKey:@"organizationUnit"]];
    [vCardPacket setField:@"DESC" :[ownvCard objectForKey:@"description"]];
    [vCardPacket setField:@"NOTE" :[ownvCard objectForKey:@"notes"]];
    if([[ownvCard objectForKey:@"birthday"] timeIntervalSinceReferenceDate] != 0)
        [vCardPacket setField:@"BDAY" :[[ownvCard objectForKey:@"birthday"] descriptionWithCalendarFormat:@"%Y-%m-%d" timeZone:nil locale:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]]];
    [vCardPacket save:[account connection]];

    [editorwindow orderOut:nil];
}

@end

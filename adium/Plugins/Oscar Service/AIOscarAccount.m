/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2003, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
 | This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 | General Public License as published by the Free Software Foundation; either version 2 of the License,
 | or (at your option) any later version.
 |
 | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 | Public License for more details.
 |
 | You should have received a copy of the GNU General Public License along with this program; if not,
 | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 \------------------------------------------------------------------------------------------------------ */

/* PLEASE NOTE -------------------------------------------------------------------------------------------
    The contents of this file, and the majority of this plugin, are an obj-c rewrite of Gaim's libfaim/oscar
    library.  In fact, portions of the original Gaim code may still remain intact, and other portions may
    have simply been re-arranged, removed, or rewritten.

    More information on Gaim is available at http://gaim.sourceforge.net
 -------------------------------------------------------------------------------------------------------*/

#import "AIOscarAccount.h"
#import <AIUtilities/AIUtilities.h>
#import <Adium/Adium.h>
#import "AIAdium.h"
#import "AIOscarPacket.h"
#import "AIOscarTLVBlock.h"
#import "AIOscarConnection.h"
#import "AIOscarAccountViewController.h"

#import "AIOscarService.h"
#import "AIOscarAuth.h"
#import "AIOscarInfo.h"
#import "AIOscarContactList.h"
#import "AIOscarMessage.h"
#import "AIOscarBOS.h"
#import "AIOscarSSI.h"
#import "AIOscarInvite.h"
#import "AIOscarPopups.h"
#import "AIOscarSearch.h"
#import "AIOscarStats.h"
#import "AIOscarTranslate.h"
#import "AIOscarICQ.h"
#import "AIOscarIcon.h"

#define ICON_REQUEST_DELAY	1.0				//This delay can be anything it seems...
#define SIGN_ON_EVENT_DURATION	20.0				//Amount of time to wait for initial sign on updates
#define ICON_CACHE_DIRECTORY	@"~/Library/Caches/Adium/Icons"

@interface AIOscarAccount (PRIVATE)
- (void)connect;
- (void)finishConnect:(NSString *)inPassword;
- (void)disconnect;
- (void)_sendFlapVersionToConnection:(AIOscarConnection *)authConnection;
- (void)_sendLoginRequestToConnection:(AIOscarConnection *)authConnection;
- (void)_registerModuleForClass:(Class)inClass;
- (void)silenceAllHandleUpdatesForInterval:(NSTimeInterval)interval;
- (void)_endSilenceAllUpdates;
- (AIChat *)_openChatWithHandle:(AIHandle *)handle;
- (void)_setInstantMessagesWithHandle:(AIHandle *)inHandle enabled:(BOOL)enable;
@end

@implementation AIOscarAccount

// AIAccount_Required --------------------------------------------------------------------------------
// Init anything relating to the account
- (void)initAccount
{    
    //Init
    handleDict = [[NSMutableDictionary alloc] init];
    chatDict = [[NSMutableDictionary alloc] init];
    moduleDict = [[NSMutableDictionary alloc] init];
    connectionArray = [[NSMutableArray alloc] init];
    iconRequestArray = [[NSMutableArray alloc] init];
    
    //Register our modules
    [self _registerModuleForClass:[AIOscarAuth class]];
    [self _registerModuleForClass:[AIOscarService class]];
    [self _registerModuleForClass:[AIOscarInfo class]];
    [self _registerModuleForClass:[AIOscarContactList class]];
    [self _registerModuleForClass:[AIOscarMessage class]];
    [self _registerModuleForClass:[AIOscarInvite class]];
    [self _registerModuleForClass:[AIOscarPopups class]];
    [self _registerModuleForClass:[AIOscarBOS class]];
    [self _registerModuleForClass:[AIOscarSearch class]];
    [self _registerModuleForClass:[AIOscarStats class]];
    [self _registerModuleForClass:[AIOscarTranslate class]];
    [self _registerModuleForClass:[AIOscarSSI class]];
    [self _registerModuleForClass:[AIOscarICQ class]];
    [self _registerModuleForClass:[AIOscarIcon class]];

    //Clear the online state.  'Auto-Connect' values are used, not the previous online state.
    [[owner accountController] setStatusObject:[NSNumber numberWithInt:STATUS_OFFLINE] forKey:@"Status" account:self];
    [[owner accountController] setStatusObject:[NSNumber numberWithBool:NO] forKey:@"Online" account:self];    
}

// Return a view for the connection window
- (id <AIAccountViewController>)accountView{
    return([AIOscarAccountViewController accountViewForOwner:owner account:self]);
}

// Return a unique ID specific to THIS account plugin, and the user's account name
- (NSString *)accountID{
    return([NSString stringWithFormat:@"OSCAR.%@",[[propertiesDict objectForKey:@"Handle"] compactedString]]);
}

//The user's account name
- (NSString *)UID{
    return([[propertiesDict objectForKey:@"Handle"] compactedString]);
}

//The service ID (shared by any account code accessing this service)
- (NSString *)serviceID{
    return(@"AIM");
}

//ServiceID.UID
- (NSString *)UIDAndServiceID{
    return([NSString stringWithFormat:@"%@.%@",[self serviceID],[self UID]]);
}

// Return a readable description of this account's username
- (NSString *)accountDescription
{
    NSString	*description = [propertiesDict objectForKey:@"Handle"];

    return(description ? description : @"");
}



//Module and Connection management ---------------------------------------------------------------------------
//Register a module for the specified module class
- (void)_registerModuleForClass:(Class)inClass
{
    NSNumber		*moduleFamily;

    //Add it to our module dict
    moduleFamily = [NSNumber numberWithInt:[inClass moduleFamily]];
    [moduleDict setObject:inClass forKey:moduleFamily];
}

//Returns the available modules
- (NSDictionary *)availableModules
{
    return(moduleDict);
}

//Returns an available module for the given family
- (id <AIOscarModule>)moduleForFamily:(int)inFamily
{
    NSEnumerator	*enumerator;
    AIOscarConnection	*connection;

    enumerator = [connectionArray objectEnumerator];
    while(connection = [enumerator nextObject]){
        id <AIOscarModule>	module;

        if(module = [connection moduleForFamily:inFamily]){
            return(module);
        }
    }

    return(nil);
}

//Add a connection
- (void)addConnection:(AIOscarConnection *)inConnection supportingModules:(NSArray *)supportedModules
{
    //Add connection
    [connectionArray addObject:inConnection];

    //Load the modules for this connection
    [inConnection addSupportedModules:supportedModules];
}



//Server-stored icons -----------------------------------------------------------------------------
//Return our user's icon data
- (NSData *)userImageData
{
    return([NSData dataWithContentsOfFile:@"/Users/adamiser/Desktop/quack.jpg"]);
}

//Request a contact's icon
//When a valid checksum is passed, the icon will be fetched from the server.  Pass nil to request the icon via messages
//
- (void)requestIconForContact:(NSString *)name
{
}

//
- (void)requestIconForContact:(NSString *)name checksum:(NSData *)checksum
{
    AIHandle	*handle;
    NSImage	*cacheImage = nil;
    
    //Check our cache for this icon
    if(checksum){
        NSString	*cacheName = [AIOscarIcon convertDataToBase16:checksum];
        NSString	*cachePath = [ICON_CACHE_DIRECTORY stringByExpandingTildeInPath];

        cacheImage = [[[NSImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/(%@)%@.tiff", cachePath, [name compactedString], cacheName]] autorelease];
    }

    if(cacheImage){
        //If a cached icon was found, we apply it
        [self noteContact:name icon:cacheImage checksum:nil]; //pass nil to show we're loading from cache
        
    }else if(checksum){
        //Que a request for this icon
        [iconRequestArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:name, @"Name", checksum, @"Checksum", nil]];

        //Ensure our request timer is active
        if(!iconRequestTimer){
            iconRequestTimer = [[NSTimer scheduledTimerWithTimeInterval:ICON_REQUEST_DELAY target:self selector:@selector(iconRequestTimer:) userInfo:nil repeats:YES] retain];
        }
        
    }else{
        //Flag this contact so their icon is requested the next time we message them
        if(handle = [handleDict objectForKey:[name compactedString]]){
            [[handle statusDictionary] setObject:[NSNumber numberWithBool:YES] forKey:@"Oscar_RequestIcon"];
        }

    }
}

//Delayed request of an icon
- (void)iconRequestTimer:(NSTimer *)timer
{
    static BOOL 	loading = NO;
    NSDictionary	*requestDict = [iconRequestArray objectAtIndex:0];
    AIOscarIcon 	*module = [self moduleForFamily:0x0010];

    if(module){
        NSLog(@"requesting icon (%@)",[requestDict objectForKey:@"Name"]);
        [module requestIconForContact:[[requestDict objectForKey:@"Name"] compactedString]
                             checksum:[requestDict objectForKey:@"Checksum"]];

        [iconRequestArray removeObject:requestDict];
        if([iconRequestArray count] == 0){
            [iconRequestTimer invalidate];
            [iconRequestTimer release];
            iconRequestTimer = nil;
        }

        //---------
        static BOOL sentOurIcon = NO;

        // horribly temp
        if(!sentOurIcon){
            [(AIOscarIcon *)[self moduleForFamily:0x0010] uploadIcon];
            sentOurIcon = YES;
        }

    }else if(!loading){
        loading = YES;
        [(AIOscarService *)[self moduleForFamily:0x0001] requestServiceForFamily:0x0010];
        NSLog(@"requesting icon server...");
    }
}

//Note the icon of a contact (Passing a checksum allows the image to be cached)
- (void)noteContact:(NSString *)name icon:(NSImage *)image checksum:(NSData *)checksum
{
    AIHandle	*handle;

    //Cache the icon locally
    if(checksum){
        NSString	*cacheName = [AIOscarIcon convertDataToBase16:checksum];
        NSString	*path = [ICON_CACHE_DIRECTORY stringByExpandingTildeInPath];

        //
        [AIFileUtilities createDirectory:path];
        [[image TIFFRepresentation] writeToFile:[NSString stringWithFormat:@"%@/(%@)%@.tiff", path, [name compactedString], cacheName] atomically:NO];

    }

    //Apply the icon
    if(handle = [handleDict objectForKey:[name compactedString]]){
        [[handle statusDictionary] setObject:image forKey:@"BuddyImage"];
        [[owner contactController] handleStatusChanged:handle modifiedStatusKeys:[NSArray arrayWithObject:@"BuddyImage"] delayed:(silenceAndDelayBuddyUpdates) silent:(silenceAndDelayBuddyUpdates)];
    }
}
















































//--------------------------------
//Note the list of contacts and groups at sign on
- (void)noteContactList:(NSArray *)inContactList
{
    NSEnumerator	*groupEnumerator;
    NSDictionary	*groupDict;

    groupEnumerator = [inContactList objectEnumerator];
    while(groupDict = [groupEnumerator nextObject]){
        NSString	*groupName;
        NSEnumerator	*handleEnumerator;
        NSString	*handleUID;

        groupName = [groupDict objectForKey:@"Name"];
        handleEnumerator = [[groupDict objectForKey:@"Contents"] objectEnumerator];
        while(handleUID = [handleEnumerator nextObject]){
            NSString	*compactedHandleUID = [handleUID compactedString];
            AIHandle	*handle;

            //Create the handle
            handle = [AIHandle handleWithServiceID:[[service handleServiceType] identifier]
                                               UID:compactedHandleUID
                                       serverGroup:groupName
                                         temporary:NO
                                        forAccount:self];

            //Set the handle's formatted name
            [[handle statusDictionary] setObject:handleUID forKey:@"DisplayName"];

            //Add the handle
            [handleDict setObject:handle forKey:compactedHandleUID];

        }
    }

    //Let the account controller know our handles changed
    [[owner contactController] handlesChangedForAccount:self];
}

//
- (void)updateContact:(NSString *)name online:(BOOL)online onlineSince:(NSDate *)signOnDate away:(BOOL)away idle:(double)idleTime
{
    NSMutableArray	*alteredStatusKeys = [[[NSMutableArray alloc] init] autorelease];
    NSString		*compactedName = [name compactedString];
    AIHandle		*handle = nil;

    //Get the handle
    if(handle = [handleDict objectForKey:compactedName]){
        NSMutableDictionary	*handleStatusDict = [handle statusDictionary];
        NSNumber		*storedValue;
        NSDate			*storedDate;
        NSString		*storedString;

        //Online/Offline
        storedValue = [handleStatusDict objectForKey:@"Online"];
        if(storedValue == nil || online != [storedValue intValue]){
            [handleStatusDict setObject:[NSNumber numberWithInt:online] forKey:@"Online"];
            [alteredStatusKeys addObject:@"Online"];

            //Enable/disable any instant messages with this handle
            [self _setInstantMessagesWithHandle:handle enabled:online];
        }

        //Idle time
        idleTime *= 60; //Convert to seconds for Adium
        storedDate = [handleStatusDict objectForKey:@"IdleSince"];
        if(storedDate == nil || (idleTime != -[storedDate timeIntervalSinceNow])){
            if(idleTime == 0 && storedDate){
                [handleStatusDict removeObjectForKey:@"IdleSince"];
                [alteredStatusKeys addObject:@"IdleSince"];
            }else if(idleTime > 0){
                [handleStatusDict setObject:[NSDate dateWithTimeIntervalSinceNow:-idleTime] forKey:@"IdleSince"];
                [alteredStatusKeys addObject:@"IdleSince"];
            }
        }

        //Sign on date
        if(signOnDate){
            storedDate = [handleStatusDict objectForKey:@"Signon Date"];
            if(storedDate == nil || ![signOnDate isEqualToDate:storedDate]){
                [handleStatusDict setObject:signOnDate forKey:@"Signon Date"];
                [alteredStatusKeys addObject:@"Signon Date"];
            }
        }

        //Away
        storedValue = [handleStatusDict objectForKey:@"Away"];
        if(storedValue == nil || away != [storedValue boolValue]){
            [handleStatusDict setObject:[NSNumber numberWithBool:away] forKey:@"Away"];
            [alteredStatusKeys addObject:@"Away"];

            if(away){
                //Request away msg
                [(AIOscarInfo *)[self moduleForFamily:0x0002] getAwayMessageForUser:compactedName];

            }else{
                //Remove away message
                [[handle statusDictionary] removeObjectForKey:@"StatusMessage"];
                [alteredStatusKeys addObject:@"StatusMessage"];
                
            }
        }

        //Display Name
        storedString = [handleStatusDict objectForKey:@"Display Name"];
        if(storedString == nil || [name compare:storedString] != 0){
            [handleStatusDict setObject:name forKey:@"Display Name"];
            [alteredStatusKeys addObject:@"Display Name"];
        }

        //Let the contact list know a handle's status changed
        if([alteredStatusKeys count]){
            [[owner contactController] handleStatusChanged:handle modifiedStatusKeys:alteredStatusKeys delayed:(silenceAndDelayBuddyUpdates) silent:(silenceAndDelayBuddyUpdates)];
        }
    }else{
        NSLog(@"Don't know of %@  (%i contact loaded)", compactedName, [handleDict count]);
    }

}


//
- (void)updateContact:(NSString *)name awayMessage:(NSString *)inAwayMessage
{
    NSString		*compactedName = [name compactedString];
    AIHandle		*handle = nil;

    //Get the handle
    if(handle = [handleDict objectForKey:compactedName]){
        if(inAwayMessage){
            [[handle statusDictionary] setObject:[AIHTMLDecoder decodeHTML:inAwayMessage] forKey:@"StatusMessage"];
        }else{
            [[handle statusDictionary] removeObjectForKey:@"StatusMessage"];
        }
        [[owner contactController] handleStatusChanged:handle modifiedStatusKeys:[NSArray arrayWithObject:@"StatusMessage"] delayed:NO silent:NO];
    }
    
}

//
- (void)receivedMessage:(NSString *)message fromContact:(NSString *)name
{
    AIHandle		*handle;
    AIContentMessage	*messageObject;
    AIChat		*chat;

    //Ensure a handle exists (creating a stranger if necessary)
    handle = [handleDict objectForKey:[name compactedString]];
    if(!handle){
        //NSLog(@"creating stranger %@ %@",name,[name compactedString]);
        handle = [self addHandleWithUID:[name compactedString] serverGroup:nil temporary:YES];
    }

    //Ensure this handle is 'online'.  If we receive a message from someone offline, it's best to assume that their offline status is incorrect, and flag them as online so the user can respond to their messages.
    if(![[[handle statusDictionary] objectForKey:@"Online"] boolValue]){
        [[handle statusDictionary] setObject:[NSNumber numberWithBool:YES] forKey:@"Online"];
        [[owner contactController] handleStatusChanged:handle modifiedStatusKeys:[NSArray arrayWithObject:@"Online"] delayed:NO silent:YES];
    }

    //Clear the 'typing' flag
    //[self setTypingFlagOfHandle:handle to:NO];

    //Get chat
    chat = [self _openChatWithHandle:handle];

    //Add a content object for the message
    messageObject = [AIContentMessage messageInChat:chat
                                         withSource:[handle containingContact]
                                        destination:self
                                               date:nil
                                            message:[AIHTMLDecoder decodeHTML:message]];
    [[owner contentController] addIncomingContentObject:messageObject];
}

//
- (void)noteContact:(NSString *)name typing:(BOOL)typing
{
    AIHandle		*handle;

    if(handle = [handleDict objectForKey:[name compactedString]]){

        BOOL currentValue = [[[handle statusDictionary] objectForKey:@"Typing"] boolValue];

        if((typing && !currentValue) || (!typing && currentValue)){
            [[handle statusDictionary] setObject:[NSNumber numberWithBool:typing] forKey:@"Typing"];
            [[owner contactController] handleStatusChanged:handle modifiedStatusKeys:[NSArray arrayWithObject:@"Typing"] delayed:YES silent:NO];
        }

    }
}









//Update Silencing --------------------------------------------------------------------------------------------
//
- (void)silenceAllHandleUpdatesForInterval:(NSTimeInterval)interval
{
    silenceAndDelayBuddyUpdates = YES;

    [NSTimer scheduledTimerWithTimeInterval:interval
                                     target:self
                                   selector:@selector(_endSilenceAllUpdates)
                                   userInfo:nil
                                    repeats:NO];
}

//
- (void)_endSilenceAllUpdates
{
    silenceAndDelayBuddyUpdates = NO;
}



// AIAccount_Handles ---------------------------------------------------------------------------
// Add a handle
- (AIHandle *)addHandleWithUID:(NSString *)inUID serverGroup:(NSString *)inGroup temporary:(BOOL)inTemporary
{
    AIHandle		*handle;
    
    if(inTemporary) inGroup = @"__Strangers";
    if(!inGroup) inGroup = @"Unknown";

    //Check to see if the handle already exists, and remove the duplicate if it does
    if(handle = [handleDict objectForKey:inUID]){
        [self removeHandleWithUID:inUID]; //Remove the handle
    }
    handle = [AIHandle handleWithServiceID:[[[self service] handleServiceType] identifier] UID:inUID serverGroup:inGroup temporary:inTemporary forAccount:self];

   [handleDict setObject:handle forKey:[handle UID]]; //Add it locally

    [[owner contactController] handle:handle addedToAccount:self];
       
    return(handle);

    //return(nil);
}

// Remove a handle
- (BOOL)removeHandleWithUID:(NSString *)inUID
{
    return(NO);
}

// Add a group to this account
- (BOOL)addServerGroup:(NSString *)inGroup
{
    return(NO);
}

// Remove a group
- (BOOL)removeServerGroup:(NSString *)inGroup
{
    return(NO);
}

// Rename a group
- (BOOL)renameServerGroup:(NSString *)inGroup to:(NSString *)newName
{
    return(NO);
}

// Return YES if the contact list is editable
- (BOOL)contactListEditable
{
    //return(NO);
    return([[[owner accountController] statusObjectForKey:@"Status" account:self] intValue] == STATUS_ONLINE);
}

// Return a dictionary of our handles
- (NSDictionary *)availableHandles
{
    return(handleDict);
}

 

// AIAccount_Messaging ---------------------------------------------------------------------------
// Send a content object
- (BOOL)sendContentObject:(AIContentObject *)object
{
    BOOL		sent = NO;
    NSString		*message;
    AIListContact	*listObject;
    AIHandle		*handle;

    if([[object type] compare:CONTENT_MESSAGE_TYPE] == 0){
        //Convert the message to HTML
        message = [AIHTMLDecoder encodeHTML:[(AIContentMessage *)object message] encodeFullString:YES];

        //Get the destination handle
        listObject = (AIListContact *)[[object chat] listObject];
        handle = [listObject handleForAccount:self];
        if(!handle){
            handle = [self addHandleWithUID:[[listObject UID] compactedString] serverGroup:nil temporary:YES];
        }

        //We want to advertise our icon and request their icon on the first message sent
        NSMutableDictionary	*handleStatusDict = [handle statusDictionary];
        BOOL		advertiseIcon = NO;
        BOOL		requestIcon = NO;
        
        if(![[handleStatusDict objectForKey:@"Oscar_AdvertisedIcon"] boolValue]){
            advertiseIcon = YES;
            requestIcon = YES;
            [handleStatusDict setObject:[NSNumber numberWithBool:YES] forKey:@"Oscar_AdvertisedIcon"];
        }

        //Message
        [(AIOscarMessage *)[self moduleForFamily:0x0004] sendMessage:message
                                                           toContact:[handle UID]
                                                       advertiseIcon:advertiseIcon
                                                         requestIcon:requestIcon];
        
        sent = YES;


    }else if([[object type] compare:CONTENT_TYPING_TYPE] == 0){
        //Get the handle for receiving this content
        listObject = (AIListContact *)[[object chat] listObject];
        handle = [listObject handleForAccount:self];

        //Send the typing event
        if(handle){
            [(AIOscarMessage *)[self moduleForFamily:0x0004] sendTyping:[(AIContentTyping *)object typing]
                                                              toContact:[handle UID]];
            sent = YES;
        }

    }
    return(sent);
}

//Return YES if we're available for sending the specified content.  If inListObject is NO, we can return YES if we will 'most likely' be able to send the content.
- (BOOL)availableForSendingContentType:(NSString *)inType toListObject:(AIListObject *)inListObject
{
    BOOL 	available = NO;
    BOOL	weAreOnline = ([[[owner accountController] statusObjectForKey:@"Status" account:self] intValue] == STATUS_ONLINE);

    if([inType compare:CONTENT_MESSAGE_TYPE] == 0){
        if(weAreOnline){
            if(inListObject == nil){
                available = YES; //If we're online, we're most likely available to message this object

            }else{
                if([inListObject isKindOfClass:[AIListContact class]]){
                    AIHandle	*handle = [(AIListContact *)inListObject handleForAccount:self];

                    if(handle && [[[handle statusDictionary] objectForKey:@"Online"] boolValue]){
                        available = YES; //This handle is online and on our list
                    }
                }
            }
        }
    }

    return(available);
}

//Initiate a new chat
- (AIChat *)openChatWithListObject:(AIListObject *)inListObject
{
    AIHandle		*handle;
    AIChat		*chat = nil;

    if([inListObject isKindOfClass:[AIListContact class]]){
        //Get our handle for this contact
        handle = [(AIListContact *)inListObject handleForAccount:self];
        if(!handle){
            handle = [self addHandleWithUID:[[inListObject UID] compactedString] serverGroup:nil temporary:YES];
        }
        chat = [self _openChatWithHandle:handle];
    }

    return(chat);
}

//
- (AIChat *)_openChatWithHandle:(AIHandle *)handle
{
    AIChat	*chat;

    //Create chat
    if(!(chat = [chatDict objectForKey:[handle UID]])){
        AIListContact	*containingContact = [handle containingContact];
        BOOL		handleIsOnline;

        //Create the chat
        chat = [AIChat chatWithOwner:owner forAccount:self];

        //NSLog(@"adding list object %@ containingContact %@",[handle UID],[handle containingContact]);
        //Set the chat participants
        [chat addParticipatingListObject:containingContact];
        
        //Correctly enable/disable the chat
        handleIsOnline = [[[handle statusDictionary] objectForKey:@"Online"] boolValue];
        [[chat statusDictionary] setObject:[NSNumber numberWithBool:handleIsOnline] forKey:@"Enabled"];
        
        //
        [chatDict setObject:chat forKey:[handle UID]];
        [[owner contentController] noteChat:chat forAccount:self];
    }

    return(chat);
}


//Close a chat instance
- (BOOL)closeChat:(AIChat *)inChat
{
    NSEnumerator	*enumerator;
    NSString		*key;

    //Remove the chat from our tracking dict
    enumerator = [[chatDict allKeys] objectEnumerator];
    while(key = [enumerator nextObject]){
        if([chatDict objectForKey:key] == inChat){
            [chatDict removeObjectForKey:key];
            break;
        }
    }

    return(YES); //Success
}

//
- (void)_setInstantMessagesWithHandle:(AIHandle *)inHandle enabled:(BOOL)enable
{
    NSEnumerator	*enumerator;
    AIChat		*chat;
    AIListContact	*contact = [inHandle containingContact];

    //Search for any chats with this contact
    enumerator = [[chatDict allValues] objectEnumerator];
    while(chat = [enumerator nextObject]){
        if([chat listObject] == contact){
            //Enable/disable the chat
            [[chat statusDictionary] setObject:[NSNumber numberWithBool:enable] forKey:@"Enabled"];

            //Notify
            [[owner notificationCenter] postNotificationName:Content_ChatStatusChanged object:chat userInfo:[NSDictionary dictionaryWithObject:[NSArray arrayWithObject:@"Enabled"] forKey:@"Keys"]];

            //Exit early
            break;
        }
    }
}



//AIAccount_Status --------------------------------------------------------------------------------
//Returns an array of the status keys we support
- (NSArray *)supportedStatusKeys
{
    return([NSArray arrayWithObjects:@"Online", @"IdleSince", @"IdleManuallySet", @"TextProfile", @"AwayMessage", nil]);
}

//Respond to account status changes
- (void)statusForKey:(NSString *)key willChangeTo:(id)inValue
{
    ACCOUNT_STATUS	status = [[[owner accountController] statusObjectForKey:@"Status" account:self] intValue];
    //Online/Offline
    if([key compare:@"Online"] == 0){
        if([inValue boolValue]){
            if(status == STATUS_OFFLINE) [self connect]; //Connect
        }else{
            if(status == STATUS_ONLINE) [self disconnect]; //Disconnect
        }
    }

    //Ignore the following keys unless we're online
    if(status == STATUS_ONLINE){
        if([key compare:@"IdleSince"] == 0){
            NSDate	*oldIdle = [[owner accountController] statusObjectForKey:@"IdleSince" account:self];
            NSDate	*newIdle = inValue;
    
            //If an idle time is already set, we unidle, then re-idle to the new value.
            if(oldIdle != nil && newIdle != nil){
                [(AIOscarService *)[self moduleForFamily:0x0001] setIdleTime:0];
            }
    
            //Set the new idle time
            [(AIOscarService *)[self moduleForFamily:0x0001] setIdleTime:(-[newIdle timeIntervalSinceNow])];


        }else if([key compare:@"TextProfile"] == 0){
            NSString	*profile = [AIHTMLDecoder encodeHTML:[NSAttributedString stringWithData:inValue] encodeFullString:YES];
            
            //Set the new profile
            [(AIOscarInfo *)[self moduleForFamily:0x0002] setProfile:profile awayMessage:nil capabilities:nil];


        }else if([key compare:@"AwayMessage"] == 0){
            NSLog(@"AwayMsg:%@",inValue);
            
            if(inValue){
                NSString	*awayMessage = [AIHTMLDecoder encodeHTML:[NSAttributedString stringWithData:inValue] encodeFullString:YES];

                //Set the new away
                [(AIOscarInfo *)[self moduleForFamily:0x0002] setProfile:nil awayMessage:awayMessage capabilities:nil];        

            }else{
                //Remove our existing away
                [(AIOscarInfo *)[self moduleForFamily:0x0002] setProfile:nil awayMessage:@"" capabilities:nil];        

            }
        }
    }
}

//Update the status of a handle
- (void)updateContactStatus:(NSNotification *)notification
{
    
}


//Connecting and Disconnecting ---------------------------------------------------------------------------
//Connect
- (void)connect
{
    //Get password
    [[owner accountController] passwordForAccount:self notifyingTarget:self selector:@selector(finishConnect:)];
}

//Finish connecting (after the password is received)
- (void)finishConnect:(NSString *)inPassword
{
    AIOscarConnection	*authConnection;

    if(inPassword && [inPassword length] != 0){
        //Set our status as connecting
        [[owner accountController] setStatusObject:[NSNumber numberWithInt:STATUS_CONNECTING] forKey:@"Status" account:self];

        //Remember the account name and password
        if(userName != [propertiesDict objectForKey:@"Handle"]){
            [userName release]; userName = [[propertiesDict objectForKey:@"Handle"] copy];
        }
        if(password != inPassword){
            [password release]; password = [inPassword copy];
        }

        //Connect to the authentication server
        authConnection = [AIOscarConnection connectionForAccount:self withHost:@"login.oscar.aol.com" port:5190 delegate:self];
        [self _sendFlapVersionToConnection:authConnection]; //Send flap version
        [self _sendLoginRequestToConnection:authConnection]; //Login request
        [self addConnection:authConnection supportingModules:
            [NSArray arrayWithObject:[moduleDict objectForIntegerKey:0x0017]]];

        //hold until all presence info is received
        [self silenceAllHandleUpdatesForInterval:SIGN_ON_EVENT_DURATION];
    }
}

//Access to active username and pass
- (NSString *)userName{
    return(userName);
}
- (NSString *)password{
    return(password);
}

//Disconnects or cancels
- (void)disconnect
{
//    NSEnumerator	*enumerator;
//    AIHandle		*handle;

    //Set our status as disconnecting
    [[owner accountController] setStatusObject:[NSNumber numberWithInt:STATUS_DISCONNECTING] forKey:@"Status" account:self];

    //Flush all our handle status flags
/*    enumerator = [[handleDict allValues] objectEnumerator];
    while((handle = [enumerator nextObject])){
        [self removeAllStatusFlagsFromHandle:handle];
    }*/

    //Remove all our handles
    [handleDict release]; handleDict = [[NSMutableDictionary alloc] init];
    [[owner contactController] handlesChangedForAccount:self];

    //Clean up and close down
/*    [silenceUpdateArray release]; silenceUpdateArray = nil;
    [socket release]; socket = nil;
    [pingTimer invalidate];
    [pingTimer release]; pingTimer = nil;
    [updateTimer invalidate];
    [updateTimer release]; updateTimer = nil;*/

    //Set our status as offline
    [[owner accountController] setStatusObject:[NSNumber numberWithInt:STATUS_OFFLINE] forKey:@"Status" account:self];
    [[owner accountController] setStatusObject:[NSNumber numberWithBool:NO] forKey:@"Online" account:self];
}

//
- (void)_sendFlapVersionToConnection:(AIOscarConnection *)authConnection
{
    AIOscarPacket	*packet = [authConnection emptyPacketOnChannel:CHANNEL_SIGNON];

    [packet addLong:0x00000001];

    [authConnection sendPacket:packet];
}

//
- (void)_sendLoginRequestToConnection:(AIOscarConnection *)authConnection
{
    AIOscarPacket	*packet = [authConnection snacPacketWithFamily:0x0017 type:0x0006 flags:0x0000];
    AIOscarTLVBlock	*requestBlock = [AIOscarTLVBlock TLVBlock];
    
    [requestBlock addType:0x0001 string:userName];

    [packet addTLVBlock:requestBlock];
    [authConnection sendPacket:packet];
}

//Sends the necessary sign on requests
- (void)sendSignonRequestsForConnection:(AIOscarConnection *)connection
{
    AIOscarService	*serviceModule = [connection moduleForFamily:0x0001];
    AIOscarInfo		*infoModule = [connection moduleForFamily:0x0002];
    AIOscarContactList	*contactModule = [connection moduleForFamily:0x0003];
    AIOscarMessage	*messageModule = [connection moduleForFamily:0x0004];
    AIOscarBOS		*bosModule = [connection moduleForFamily:0x0009];
    AIOscarSSI		*ssiModule = [connection moduleForFamily:0x0013];
    AIOscarICQ		*icqModule = [connection moduleForFamily:0x0015];
    BOOL		mainConnection = (infoModule != nil);

    //Capabilities
    NSArray	*capabilities = [NSArray arrayWithObjects:
        [NSNumber numberWithInt:AIM_CAPS_CHAT],
        [NSNumber numberWithInt:AIM_CAPS_BUDDYICON],
        [NSNumber numberWithInt:AIM_CAPS_IMIMAGE],
        [NSNumber numberWithInt:AIM_CAPS_SENDFILE],
        [NSNumber numberWithInt:AIM_CAPS_INTEROPERATE],
        nil];
    [infoModule setProfile:nil awayMessage:nil capabilities:capabilities];

    //Various requests
    if(mainConnection){ //Only for the main connection
        [serviceModule requestPersonalInformation]; //Request personal information
    }
    [ssiModule requestSSIRights]; //Request our SSI rights
    [ssiModule requestSSIData]; //Request our SSI data
    [infoModule requestLocatorRights]; //Request locator rights
    [contactModule requestContactRights]; //Request buddy rights
    [messageModule requestMessageRights]; //Request message rights
    [bosModule requestBOSRights]; //Request BOS rights
    
    //Profile and away message
    if(mainConnection){ //Only for the main connection
        NSAttributedString	*profile = [NSAttributedString stringWithData:[[owner accountController] statusObjectForKey:@"TextProfile" account:self]];
        NSAttributedString	*away = [NSAttributedString stringWithData:[[owner accountController] statusObjectForKey:@"AwayMessage" account:self]];

        [infoModule setProfile:(profile ? [AIHTMLDecoder encodeHTML:profile encodeFullString:YES] : @"")
                   awayMessage:(away ? [AIHTMLDecoder encodeHTML:away encodeFullString:YES] : @"")
                  capabilities:nil];
    }

    //More requests
    [messageModule sendMessageRights]; //message rights
    [icqModule setICQStatus]; //ICQ status

    //Idle time
    if(mainConnection){ //Only for the main connection
        NSDate	*idle = [[owner accountController] statusObjectForKey:@"IdleSince" account:self];
        [serviceModule setIdleTime:(idle ? (-[idle timeIntervalSinceNow]) : 0)];
    }

    //Send the client ready command, activating this connection
    [serviceModule sendClientReady];

    //
    if(mainConnection){ //Only for the main connection
        [[owner accountController] setStatusObject:[NSNumber numberWithInt:STATUS_ONLINE] forKey:@"Status" account:self]; //Set our status as online
    }    
}

@end




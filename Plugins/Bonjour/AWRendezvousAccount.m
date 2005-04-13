/*
 * Project:     Adium Rendezvous Plugin
 * File:        AWRendezvousAccount.m
 * Author:      Andrew Wellington <proton[at]wiretapped.net>
 *
 * License:
 * Copyright (C) 2004-2005 Andrew Wellington.
 * All rights reserved.
 * 
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation; either version 2 of the License, or (at your
 * option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "AIContactController.h"
#import "AIContentController.h"
#import "AIStatusController.h"
#import "AWEzv.h"
#import "AWEzvContact.h"
#import "AWEzvDefines.h"
#import "AWRendezvousAccount.h"
#import "AWRendezvousPlugin.h"
#import <Adium/AIChat.h>
#import <Adium/AIContentMessage.h>
#import <Adium/AIContentTyping.h>
#import <Adium/AIHTMLDecoder.h>
#import <Adium/AIListContact.h>
#import <Adium/AIStatus.h>
#import <Adium/NDRunLoopMessenger.h>
#import <AIUtilities/AIMutableOwnerArray.h>
#import <AIUtilities/CBObjectAdditions.h>

static	NSLock				*threadPreparednessLock = nil;
static	NDRunLoopMessenger	*rendezvousThreadMessenger = nil;
static	AWEzv				*libezvThreadProxy = nil;
static	NSAutoreleasePool	*currentAutoreleasePool = nil;

#define	AUTORELEASE_POOL_REFRESH	5.0

@interface AWRendezvousAccount (PRIVATE)
- (NSString *)UIDForContact:(AWEzvContact *)contact;

- (void)setAccountIdleTo:(NSDate *)idle;
- (void)setAccountAwayTo:(NSAttributedString *)awayMessage;
- (void)setAccountUserImage:(NSImage *)image;
@end

@implementation AWRendezvousAccount
//
- (void)initAccount
{
    [super initAccount];
	
    libezvContacts = [[NSMutableSet alloc] init];
    libezv = [[AWEzv alloc] initWithClient:self];	
}

- (void)dealloc
{
	[libezvContacts release];
	[libezv release];

	[super dealloc];
}

- (BOOL)disconnectOnFastUserSwitch
{
	return(YES);
}

//No need for a password for Rendezvous accounts
- (BOOL)requiresPassword
{
	return(NO);
}

- (void)connect
{
	if(!libezvThreadProxy){
		//Obtain the lock
		threadPreparednessLock = [[NSLock alloc] init];
		[threadPreparednessLock lock];
		
		//Detach the thread, which will unlock threadPreparednessLock when it is ready
		[NSThread detachNewThreadSelector:@selector(prepareRendezvousThread)
								 toTarget:self
							   withObject:nil];
		
		//Obtain the lock - this will spinlock until the thread is ready
		[threadPreparednessLock lock];
		[threadPreparednessLock release]; threadPreparednessLock = nil;
	}
	
    // Say we're connecting...
    [self setStatusObject:[NSNumber numberWithBool:YES] forKey:@"Connecting" notify:YES];

    [libezvThreadProxy setName:[self displayName]];
	AILog(@"%@: Logging in using libezvThreadProxy %@",self, libezvThreadProxy);
    [libezvThreadProxy login];
}

- (void)disconnect
{
	//As per AIAccount's documentation, call super's implementation
	[super disconnect];

    // Say we're disconnecting...
    [self setStatusObject:[NSNumber numberWithBool:YES] forKey:@"Disconnecting" notify:YES];
    
    [libezvThreadProxy logout];
}

- (void)removeContacts:(NSArray *)objects
{

}

#pragma mark Libezv Callbacks
/*
 * @brief Logged in, called on the main thread
 */
- (void)mainThreadReportLoggedIn
{
	[self didConnect];
    
	//We need to set our user icon after connecting
    [self updateStatusForKey:KEY_USER_ICON];	
}

/*
 * @brief libezv: we logged in
 *
 * Sent on the libezv thread
 */
- (void)reportLoggedIn
{
	AILog(@"%@: reportLoggedIn",self);
	[self mainPerformSelector:@selector(mainThreadReportLoggedIn)];
}

/*
 * @brief libezv: we logged out
 *
 * Sent on the libezv thread
 */
- (void)reportLoggedOut 
{
	AILog(@"%@: reportLoggedOut",self);
	[libezvContacts removeAllObjects];
		
	[self mainPerformSelector:@selector(didDisconnect)];
}

- (void)mainThreadUserChangedState:(AWEzvContact *)contact
{
    AIListContact	*listContact;
	NSString		*contactName, *statusMessage;
	NSDate			*idleSinceDate;
	NSImage			*contactImage;
	
    listContact = [[adium contactController] contactWithService:service
														account:self
															UID:[self UIDForContact:contact]];  
	
	if (![listContact remoteGroupName]){
		[listContact setRemoteGroupName:AILocalizedString(@"Bonjour", @"Bonjour group name")];
	}
	
	//We only get state change updates on Online contacts
	if (![listContact online]){
		[listContact setStatusObject:[NSNumber numberWithBool:YES] forKey:@"Online" notify:NO];
	}
	
	switch ([contact status]) {
		case AWEzvAway:
			if (![listContact integerStatusObjectForKey:@"Away"]){
				[listContact setStatusObject:[NSNumber numberWithBool:YES] forKey:@"Away" notify:NO];
			}
			break;
		case AWEzvOnline:
		case AWEzvIdle:
		default:
			if ([listContact integerStatusObjectForKey:@"Away"]){
				[listContact setStatusObject:nil forKey:@"Away" notify:NO];
			}
	}
	
	if (idleSinceDate = [contact idleSinceDate]){
		//Only set the new date object if the time interval has changed
		if ([[listContact statusObjectForKey:@"IdleSince"] timeIntervalSinceDate:idleSinceDate] != 0){
			[listContact setStatusObject:idleSinceDate forKey:@"IdleSince" notify:NO];
			[listContact setStatusObject:[NSNumber numberWithBool:YES] forKey:@"IsIdle" notify:NO];
		}
	}else{
		[listContact setStatusObject:nil forKey:@"IdleSince" notify:NO];
		[listContact setStatusObject:nil forKey:@"IsIdle" notify:NO];
	}
	
    if (statusMessage = [contact statusMessage]){
		NSString	*oldStatusMessage = [listContact stringFromAttributedStringStatusObjectForKey:@"StatusMessage"];
		
		if (!oldStatusMessage || ![oldStatusMessage isEqualToString:statusMessage]){
			[listContact setStatusObject:[[[NSAttributedString alloc] initWithString:statusMessage] autorelease]
								  forKey:@"StatusMessage"
								  notify:NO];
		}
	}else{
		[listContact setStatusObject:nil forKey:@"StatusMessage" notify:NO];
	}
	
	contactImage = [contact contactImage];
	if(contactImage != [listContact userIcon]){
		[listContact setStatusObject:contactImage forKey:KEY_USER_ICON notify:NO];
	}
	
    //Use the contact alias as the serverside display name
	contactName = [contact name];
	if (![[listContact statusObjectForKey:@"Server Display Name"] isEqualToString:contactName]){
		//This is the server display name.  Set it as such.
		[listContact setStatusObject:contactName
							  forKey:@"Server Display Name"
							  notify:NO];
		
		[[listContact displayArrayForKey:@"Display Name"] setObject:contactName
														  withOwner:self
													  priorityLevel:Low_Priority];
		
		//Notify of display name changes
		[[adium contactController] listObjectAttributesChanged:listContact
												  modifiedKeys:[NSSet setWithObject:@"Display Name"]];
		
		//XXX - There must be a cleaner way to do this alias stuff!  This works for now
		//Request an alias change
		[[adium notificationCenter] postNotificationName:Contact_ApplyDisplayName
												  object:listContact
												userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES]
																					 forKey:@"Notify"]];		
	}

    //Apply any changes
    [listContact notifyOfChangedStatusSilently:silentAndDelayed];	
}

/*
 * @brief libezv: A contact was updated 
 *
 * Sent on the libezv thread
 */
- (void)userChangedState:(AWEzvContact *)contact
{
	[self mainPerformSelector:@selector(mainThreadUserChangedState:)
				   withObject:contact];
	
	//Adding an existing object to a set has no effect, so just ensure it is added
	[libezvContacts addObject:contact];
}

- (void)mainThreadUserWithUIDLoggedOut:(NSString *)inUID
{
    AIListContact *listContact;
    
    listContact = [[adium contactController] existingContactWithService:service
																account:self 
																	UID:inUID];
    
    [listContact setRemoteGroupName:nil];	
}

- (void)userLoggedOut:(AWEzvContact *)contact
{
	[self mainPerformSelector:@selector(mainThreadUserWithUIDLoggedOut:)
				   withObject:[contact uniqueID]];

    [libezvContacts removeObject:contact];
}

- (void)mainThreadUserWithUID:(NSString *)inUID sentMessage:(NSString *)message withHtml:(NSString *)html
{
    AIListContact		*listContact;
    AIContentMessage	*msgObj;
    AIChat				*chat;
	
    listContact = [[adium contactController] existingContactWithService:service
																account:self
																	UID:inUID];
	chat = [[adium contentController] chatWithContact:listContact];
	
    msgObj = [AIContentMessage messageInChat:chat
								  withSource:listContact
								 destination:self
										date:nil
									 message:[AIHTMLDecoder decodeHTML:html]
								   autoreply:NO];
    
    [[adium contentController] receiveContentObject:msgObj];
	
	//Clear the typing flag
	[chat setStatusObject:nil
				   forKey:KEY_TYPING
				   notify:YES];	
}

//We received a message from an AWEzvContact
- (void)user:(AWEzvContact *)contact sentMessage:(NSString *)message withHtml:(NSString *)html
{
	[self mainPerformSelector:@selector(mainThreadUserWithUID:sentMessage:withHtml:)
				   withObject:[contact uniqueID]
				   withObject:message
				   withObject:html];
}

- (void)mainThreadUserWithUID:(NSString *)inUID typingNotificationNumber:(NSNumber *)typingNumber
{
    AIListContact   *listContact;
    AIChat			*chat;
    listContact = [[adium contactController] existingContactWithService:service
																account:self
																	UID:inUID];
	chat = [[adium contentController] existingChatWithContact:listContact];
	
    [chat setStatusObject:typingNumber
				   forKey:KEY_TYPING
				   notify:YES];	
}

- (void)user:(AWEzvContact *)contact typingNotification:(AWEzvTyping)typingStatus
{
	[self mainPerformSelector:@selector(mainThreadUserWithUID:typingNotificationNumber:)
				   withObject:[contact uniqueID]
				   withObject:((typingStatus == AWEzvIsTyping) ? [NSNumber numberWithInt:AITyping] : nil)];;
}

- (void)user:(AWEzvContact *)contact typeAhead:(NSString *)message withHtml:(NSString *)html {
/* unimplemented in libezv at this stage */
}

- (void)user:(AWEzvContact *)contact sentFile:(NSString *)filename size:(size_t)size cookie:(int)cookie
{
/* sorry, no file transfer in libezv at the moment */
}

- (void)reportError:(NSString *)error ofLevel:(AWEzvErrorSeverity)severity
{

}

- (void)reportError:(NSString *)error ofLevel:(AWEzvErrorSeverity)severity forUser:(NSString *)contact
{

}

#pragma mark AIAccount Messaging
// AIAccount_Messaging ---------------------------------------------------------------------------
// Send a content object
- (BOOL)sendContentObject:(AIContentObject *)object
{
    BOOL sent = NO;
    if([[object type] isEqualToString:CONTENT_MESSAGE_TYPE]){
		NSAttributedString  *attributedMessage = [(AIContentMessage *)object message];
		NSString			*message = [attributedMessage string];
		NSString			*htmlMessage = [AIHTMLDecoder encodeHTML:attributedMessage
															 headers:NO
															fontTags:YES
												  includingColorTags:YES
													   closeFontTags:YES
														   styleTags:YES
										  closeStyleTagsOnFontChange:YES
													  encodeNonASCII:YES
														encodeSpaces:NO
														  imagesPath:nil
												   attachmentsAsText:YES
									  attachmentImagesOnlyForSending:NO
													  simpleTagsOnly:NO
													  bodyBackground:NO];
		
		AIChat			*chat = [(AIContentMessage *)object chat];
		AIListObject    *listObject = [chat listObject];
		NSString		*to = [listObject UID];
		
		[libezvThreadProxy sendMessage:message 
									to:to 
							  withHtml:htmlMessage];

		sent = YES;

    } else if([[object type] isEqualToString:CONTENT_TYPING_TYPE]) {
		AIContentTyping *contentTyping = (AIContentTyping*)object;
		AIChat			*chat = [contentTyping chat];
		AIListObject    *listObject = [chat listObject];
		NSString		*to = [listObject UID];
		
		[libezvThreadProxy sendTypingNotification:(([contentTyping typingState] == AITyping) ? AWEzvIsTyping : AWEzvNotTyping)
											   to:to];
		sent = YES;
    }
	
    return sent;
}

//Return YES if we're available for sending the specified content.  If inListObject is NO, we can return YES if we will 'most likely' be able to send the content.
- (BOOL)availableForSendingContentType:(NSString *)inType toContact:(AIListContact *)inContact
{
    if([inType isEqualToString:CONTENT_MESSAGE_TYPE] && [self online]){
		return(YES);
    }
    
    return NO;
}

//Initiate a new chat
- (BOOL)openChat:(AIChat *)chat
{
    return(YES);
}

//Close a chat instance
- (BOOL)closeChat:(AIChat *)inChat
{
    return(YES);
}

#pragma mark Account Status
//Respond to account status changes
- (void)updateStatusForKey:(NSString *)key
{
    [super updateStatusForKey:key];
    
    BOOL    areOnline = [[self statusObjectForKey:@"Online"] boolValue];
    
    //Now look at keys which only make sense while online
    if(areOnline){
        if([key isEqualToString:@"IdleSince"]){
            NSDate	*idleSince = [self preferenceForKey:@"IdleSince" group:GROUP_ACCOUNT_STATUS];
			
			[libezvThreadProxy setStatus:AWEzvIdle
							 withMessage:[[self statusMessage] string]];
            [self setAccountIdleTo:idleSince];
			
        }else if([key isEqualToString:KEY_USER_ICON]){
			NSData  *data = [self preferenceForKey:KEY_USER_ICON group:GROUP_ACCOUNT_STATUS];

			[self setAccountUserImage:(data ? [[[NSImage alloc] initWithData:data] autorelease] : nil)];
		}
    }
}

- (void)setStatusState:(AIStatus *)statusState usingStatusMessage:(NSAttributedString *)statusMessage
{
	if([self online]){
		AIStatusType	statusType = [statusState statusType];
		switch(statusType){
			case AIAvailableStatusType:
				[self setAccountAwayTo:nil];
				break;
			case AIAwayStatusType:
			case AIInvisibleStatusType:
				[self setAccountAwayTo:statusMessage];
				break;
		}
	}
}

- (void)setAccountIdleTo:(NSDate *)idle
{
	[libezvThreadProxy setIdleTime:idle];

	//We are now idle
	[self setStatusObject:idle forKey:@"IdleSince" notify:YES];
}

- (void)setAccountAwayTo:(NSAttributedString *)awayMessage
{
	if(!awayMessage || ![[awayMessage string] isEqualToString:[[self statusObjectForKey:@"StatusMessage"] string]]){
		if (awayMessage != nil)
		    [libezvThreadProxy setStatus:AWEzvAway withMessage:[awayMessage string]];
		else
		    [libezvThreadProxy setStatus:AWEzvOnline withMessage:nil];
		
		//We are now away or not
		[self setStatusObject:[NSNumber numberWithBool:(awayMessage != nil)] forKey:@"Away" notify:YES];
		[self setStatusObject:awayMessage forKey:@"StatusMessage" notify:YES];
	}
}

/*!
 * @brief Set our user image
 *
 * Pass nil for no image.
 */
- (void)setAccountUserImage:(NSImage *)image
{
	[libezvThreadProxy setContactImage:image];	

	//We now have an icon
	[self setStatusObject:image forKey:KEY_USER_ICON notify:YES];
}

//Status keys this account supports
- (NSSet *)supportedPropertyKeys
{
	static NSMutableSet *supportedPropertyKeys = nil;
	
	if (!supportedPropertyKeys){
		supportedPropertyKeys = [[NSMutableSet alloc] initWithObjects:
			@"Online",
			@"Offline",
			@"IdleSince",
			@"IdleManuallySet",
			@"Away",
			@"AwayMessage",
			nil];

		[supportedPropertyKeys unionSet:[super supportedPropertyKeys]];
	}

	return supportedPropertyKeys;
}

- (NSString *)UIDForContact:(AWEzvContact *)contact
{
	/*
	NSString	*uniqueID = [contact uniqueID];
	NSArray		*components = [uniqueID componentsSeparatedByString:@"@"];
	NSString	*userName = [contact name];
	return([NSString stringWithFormat:@"%@ [%@]",name,[ substringFromIndex:[name length]]]);
	 */
	return([contact uniqueID]);
}

#pragma mark Bonjour Thread

- (void)prepareRendezvousThread
{
	NSTimer	*autoreleaseTimer;
	
	currentAutoreleasePool = [[NSAutoreleasePool alloc] init];
		
	rendezvousThreadMessenger = [[NDRunLoopMessenger runLoopMessengerForCurrentRunLoop] retain];
	libezvThreadProxy = [[rendezvousThreadMessenger target:libezv] retain];
	
	//Use a timer to periodically release our autorelease pool so we don't continually grow in memory usage
	autoreleaseTimer = [[NSTimer scheduledTimerWithTimeInterval:AUTORELEASE_POOL_REFRESH
														 target:self
													   selector:@selector(refreshAutoreleasePool:)
													   userInfo:nil
														repeats:YES] retain];
	//We're good to go; release that lock
	[threadPreparednessLock unlock];
	CFRunLoopRun();
	
	[autoreleaseTimer invalidate]; [autoreleaseTimer release];
	[rendezvousThreadMessenger release]; rendezvousThreadMessenger = nil;
	[libezvThreadProxy release]; libezvThreadProxy = nil;
    [currentAutoreleasePool release];
}

/*
 * @brief Release and recreate our autorelease pool
 *
 * Our autoreleased objects will only be released when the outermost autorelease pool is released.
 * This is handled automatically in the main thread, but we need to do it manually here.
 * Release the current pool, then create a new one.
 */
- (void)refreshAutoreleasePool:(NSTimer *)inTimer
{
	[currentAutoreleasePool release];
	currentAutoreleasePool = [[NSAutoreleasePool alloc] init];
}

@end

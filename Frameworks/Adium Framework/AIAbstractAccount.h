/* 
Adium, Copyright 2001-2005, Adam Iser
 
 This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 General Public License as published by the Free Software Foundation; either version 2 of the License,
 or (at your option) any later version.
 
 This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 Public License for more details.
 
 You should have received a copy of the GNU General Public License along with this program; if not,
 write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import <Cocoa/Cocoa.h>
#import "AIAccount.h"

@interface AIAccount (Abstract)

- (id)initWithUID:(NSString *)inUID internalObjectID:(NSString *)inInternalObjectID service:(AIService *)inService;
- (NSData *)userIconData;
- (void)setUserIconData:(NSData *)inData;

//Status
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key object:(AIListObject *)object
					preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime;
- (void)silenceAllContactUpdatesForInterval:(NSTimeInterval)interval;
- (void)updateContactStatus:(AIListContact *)inContact;
- (void)updateCommonStatusForKey:(NSString *)key;

//Auto-Refreshing Status String
- (NSAttributedString *)autoRefreshingOutgoingContentForStatusKey:(NSString *)key;
- (void)autoRefreshingOutgoingContentForStatusKey:(NSString *)key selector:(SEL)selector;
- (void)autoRefreshingOutgoingContentForStatusKey:(NSString *)key selector:(SEL)selector context:(id)originalContext;
- (void)setStatusObject:(id)value forKey:(NSString *)key notify:(NotifyTiming)notify;
- (void)startAutoRefreshingStatusKey:(NSString *)key;
- (void)stopAutoRefreshingStatusKey:(NSString *)key;
- (void)_startAttributedRefreshTimer;
- (void)_stopAttributedRefreshTimer;

//Contacts
- (NSArray *)contacts;
- (AIListContact *)contactWithUID:(NSString *)sourceUID;

//Connectivity
- (void)connectScriptCommand:(NSScriptCommand *)command;
- (void)disconnectScriptCommand:(NSScriptCommand *)command;

//FUS Disconnecting
- (void)autoReconnectAfterDelay:(int)delay;
- (void)initFUSDisconnecting;

@end

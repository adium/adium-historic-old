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

#import <Cocoa/Cocoa.h>
#import <Adium/Adium.h>

@class AIOscarAccount, AIOscarPacket, AIOscarConnection;

@protocol AIOscarModule <NSObject>
- (id)initWithAccount:(AIOscarAccount *)inAccount forConnection:(AIOscarConnection *)inConnection;
+ (unsigned short)moduleFamily;
+ (unsigned short)moduleVersion;
+ (unsigned short)toolID;
+ (unsigned short)toolVersion;
- (void)handleRequest:(long)requestID type:(unsigned short)type flags:(unsigned short)flags packet:(AIOscarPacket *)inPacket;
@end

@class AISocket, AIGroup, AIMTOC2AccountViewController, AIOscarConnection;
@protocol AIAccount_Content, AIAccount_Handles;

@interface AIOscarAccount : AIAccount <AIAccount_Content, AIAccount_Handles> {
    NSMutableDictionary		*handleDict;			//Known handles
    NSMutableDictionary		*moduleDict;			//Avaiable modules
    NSMutableArray		*connectionArray;		//Open connections
    BOOL			silenceAndDelayBuddyUpdates; 	//Mute and delay updates
    NSTimer			*iconRequestTimer; 		//Used to spread out icon requests
    NSMutableArray		*iconRequestArray;		//Qued icon requests

    NSString			*userName;			//Active account name
    NSString			*password;			//Active password
}

- (void)initAccount;
- (NSString *)accountID;
- (NSString *)accountDescription;
- (NSDictionary *)availableModules;
- (id <AIOscarModule>)moduleForFamily:(int)inFamily;
- (void)updateContact:(NSString *)name online:(BOOL)online onlineSince:(NSDate *)signOnDate away:(BOOL)away idle:(double)idleTime;
- (void)updateContact:(NSString *)name awayMessage:(NSString *)inAwayMessage;
- (void)noteContactList:(NSArray *)inContactList;
- (NSData *)userImageData;
- (void)receivedMessage:(NSString *)message fromContact:(NSString *)name;
- (void)sendSignonRequestsForConnection:(AIOscarConnection *)connection;
- (void)noteContact:(NSString *)name typing:(BOOL)typing;
- (void)noteContact:(NSString *)name icon:(NSImage *)image checksum:(NSData *)checksum;
- (void)silenceAllHandleUpdatesForInterval:(NSTimeInterval)interval;
- (void)_endSilenceAllUpdates;
- (void)requestIconForContact:(NSString *)name checksum:(NSData *)checksum;
- (void)requestIconForContact:(NSString *)name;
- (void)addConnection:(AIOscarConnection *)inConnection supportingModules:(NSArray *)supportedModules;
- (NSString *)userName;
- (NSString *)password;

@end

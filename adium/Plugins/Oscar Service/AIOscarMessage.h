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

@protocol AIOscarModule;
@class AIOscarAccount, AIOscarPacket, AIOscarConnection;

@interface AIOscarMessage : NSObject <AIOscarModule> {
    AIOscarAccount	*account;
    AIOscarConnection	*connection;
    
    //Message rights
    unsigned short 	maxchan, maxMessageLength, maxSenderWarn, maxReceiverWarn;
    unsigned long 	flags, minMessageInterval;

}

- (void)sendMessageRights;
- (void)requestMessageRights;
- (void)sendMessage:(NSString *)message toContact:(NSString *)name advertiseIcon:(BOOL)advertiseIcon requestIcon:(BOOL)requestIcon;
- (void)sendTyping:(BOOL)typing toContact:(NSString *)name;
- (void)sendIconToContact:(NSString *)name;

+ (NSData *)randomCookie;
+ (NSData *)randomAlphanumericCookie;
+ (void)addICBMHeaderToPacket:(AIOscarPacket *)packet withCookie:(NSData *)cookie channel:(unsigned short)channel name:(NSString *)name;
+ (unsigned short)checksumData:(NSData *)data;

@end

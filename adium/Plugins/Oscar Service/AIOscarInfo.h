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

typedef enum{
    OscarInfo_General = 0x00001,
    OscarInfo_AwayMessage = 0x00003,
    OscarInfo_Capabilities = 0x0004
} OscarInfoType;

#define AIM_CAPS_BUDDYICON	0x00000001
#define AIM_CAPS_VOICE		0x00000002
#define AIM_CAPS_IMIMAGE	0x00000004
#define AIM_CAPS_CHAT		0x00000008
#define AIM_CAPS_GETFILE	0x00000010
#define AIM_CAPS_SENDFILE	0x00000020
#define AIM_CAPS_GAMES		0x00000040
#define AIM_CAPS_SAVESTOCKS	0x00000080
#define AIM_CAPS_SENDBUDDYLIST	0x00000100
#define AIM_CAPS_GAMES2		0x00000200
#define AIM_CAPS_ICQ		0x00000400
#define AIM_CAPS_APINFO		0x00000800
#define AIM_CAPS_ICQRTF		0x00001000
#define AIM_CAPS_EMPTY		0x00002000
#define AIM_CAPS_ICQSERVERRELAY	0x00004000
#define AIM_CAPS_ICQUNKNOWN	0x00008000
#define AIM_CAPS_TRILLIANCRYPT	0x00010000
#define AIM_CAPS_ICQUTF8	0x00020000
#define AIM_CAPS_INTEROPERATE	0x00040000
#define AIM_CAPS_ICHAT		0x00080000
#define AIM_CAPS_HIPTOP		0x00100000
#define AIM_CAPS_LAST		0x00200000

@protocol AIOscarModule;
@class AIOscarAccount, AIOscarPacket, AIOscarTLVBlock, AIOscarConnection;

@interface AIOscarInfo : NSObject <AIOscarModule> {
    AIOscarAccount	*account;
    AIOscarConnection	*connection;

}

+ (NSString *)stringOfCaps:(NSArray *)capArray;
+ (NSArray *)getCapsFromString:(NSString *)capString;
+ (AIOscarTLVBlock *)extractInfoFromPacket:(AIOscarPacket *)inPacket name:(NSString **)outName warnLevel:(unsigned short *)outWarnLevel;
- (void)requestLocatorRights;
- (void)setProfile:(NSString *)profile awayMessage:(NSString *)awayMessage capabilities:(NSArray *)capabilities;
- (void)getInfo:(OscarInfoType)infoType forUser:(NSString *)name;
- (void)setDirectoryInfoPrivacy:(unsigned short)privacy first:(NSString *)first last:(NSString *)last middle:(NSString *)middle maiden:(NSString *)maiden state:(NSString *)state city:(NSString *)city nickname:(NSString *)nickname zip:(NSString *)zip street:(NSString *)street;
- (void)setDirectoryInfoPrivacy:(unsigned short)privacy interests:(NSArray *)interests;
- (void)getAwayMessageForUser:(NSString *)name;

@end
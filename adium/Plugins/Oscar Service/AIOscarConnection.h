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
#import "AIOscarPacket.h"

@class AISocket, AIOscarPacket, AIOscarAccount;
@protocol AIOscarModule;

@interface NSObject (AIOscarConnectionDelegate)
@end

@interface AIOscarConnection : NSObject {
    AIOscarAccount	*account;
    
    NSString		*host;
    int			port;

    id 			delegate;

    unsigned short	localSequence;		// Current local packet sequence
    unsigned long	localRequest;		//

    AISocket		*socket;

    NSMutableDictionary	*supportedModules;
    NSTimer		*updateTimer;    
}

+ (id)connectionForAccount:(AIOscarAccount *)inAccount withHost:(NSString *)inHost port:(int)inPort delegate:(id)inDelegate;
- (void)addSupportedModules:(NSArray *)inArray;
- (NSDictionary *)supportedModules;
- (void)setDelegate:(id)inDelegate;
- (void)sendPacket:(AIOscarPacket *)inPacket;
//- (unsigned short *)localSequence;
//- (unsigned long *)localRequest;

- (AIOscarPacket *)snacPacketWithFamily:(unsigned short)inFamily type:(unsigned short)inType flags:(unsigned short)inFlags;
- (AIOscarPacket *)emptyPacketOnChannel:(OSCARCHANNEL)inChannel;
- (id <AIOscarModule>)moduleForFamily:(int)inFamily;

@end

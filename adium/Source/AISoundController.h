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

#import <Cocoa/Cocoa.h>
#import "AIAdium.h"

//typedef enum {
//    SOUND_TEST = -1, SOUND_SIGNED_OFF, SOUND_SIGNED_ON, SOUND_IM_RECEIVE, SOUND_IM_RECEIVE_FIRST, SOUND_IM_SEND, SOUND_IM_STRANGER
//    SOUND_SIGNED_ON, SOUND_SIGNED_OFF, SOUND_IM_SEND, SOUND_IM_RECEIVE, SOUND_IM_RECEIVE_FIRST, SOUND_IM_STRANGER, SOUND_CHAT_SEND, SOUND_CHAT_RECEIVE
//} SoundType;

//@class AIAway;

@interface AISoundController (INTERNAL)

- (void)initController;
- (void)closeController;

// These methods are for internal Adium use only.  The public interface is in Adium.h.

//+ (AISound *)sharedInstance;
//- (void)soundIdle:(NSTimer *)timer;
//- (void)playSound:(SoundType)soundID;
//- (void)playSound:(NSString *)fileName custom:(BOOL)custom volume:(int)soundVolume;

//private
//- (id)init;

@end

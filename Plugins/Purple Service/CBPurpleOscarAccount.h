/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "CBGaimAccount.h"
#import <Libgaim/oscar.h>

@class AIHTMLDecoder;

struct buddyinfo {
	gboolean typingnot;
	guint32 ipaddr;
	
	unsigned long ico_me_len;
	unsigned long ico_me_csum;
	time_t ico_me_time;
	gboolean ico_informed;
	
	unsigned long ico_len;
	unsigned long ico_csum;
	time_t ico_time;
	gboolean ico_need;
	gboolean ico_sent;
};

//From oscar.c
#define OSCAR_STATUS_ID_INVISIBLE	"invisible"
#define OSCAR_STATUS_ID_OFFLINE		"offline"
#define OSCAR_STATUS_ID_AVAILABLE	"available"
#define OSCAR_STATUS_ID_AWAY		"away"
#define OSCAR_STATUS_ID_DND			"dnd"
#define OSCAR_STATUS_ID_NA			"na"
#define OSCAR_STATUS_ID_OCCUPIED	"occupied"
#define OSCAR_STATUS_ID_FREE4CHAT	"free4chat"
#define OSCAR_STATUS_ID_CUSTOM		"custom"

@class AIHTMLDecoder;

@interface CBGaimOscarAccount : CBGaimAccount  <AIAccount_Files> {
	AIHTMLDecoder	*oscarGaimThreadHTMLDecoder;
	
	NSTimer			*delayedSignonUpdateTimer;
	NSMutableArray  *arrayOfContactsForDelayedUpdates;
}

@end

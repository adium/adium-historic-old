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

#ifdef DEBUG_BUILD
//Extensive debug logging is always on for a debug build
#define GAIM_DEBUG  TRUE
#else
//Extensive debug logging may be preferentially turned on for Gaim for a non-debug build
#define GAIM_DEBUG FALSE
#endif

#if GAIM_DEBUG
	#define GaimDebug AILog
#else
	#define GaimDebug //
#endif

#define TREPIA_NOT_AVAILABLE
//#define MEANWHILE_NOT_AVAILABLE

//Gaim includes
#include <Libgaim/libgaim.h>


#define GAIM_ORPHANS_GROUP_NAME				"__AdiumOrphansUE9FHUE7I"  //A group name no sane user would have

//Events we care about explicitly via signals
typedef enum
{
	GAIM_BUDDY_NONE				= 0x00, /**< No events.                    */
	GAIM_BUDDY_SIGNON			= 0x01, /**< The buddy signed on.          */
	GAIM_BUDDY_SIGNOFF			= 0x02, /**< The buddy signed off.         */
	GAIM_BUDDY_AWAY				= 0x04, /**< The buddy went away.          */
	GAIM_BUDDY_AWAY_RETURN		= 0x08, /**< The buddy returned from away. */
	GAIM_BUDDY_IDLE				= 0x10, /**< The buddy became idle.        */
	GAIM_BUDDY_IDLE_RETURN		= 0x20, /**< The buddy is no longer idle.  */
	GAIM_BUDDY_STATUS_MESSAGE   = 0x40, /**< The buddy's status message changed.     */
	GAIM_BUDDY_INFO_UPDATED		= 0x80, /**< The buddy's information (profile) changed.     */
	GAIM_BUDDY_ICON				= 0x11, /**< The buddy's icon changed.     */
	GAIM_BUDDY_MISCELLANEOUS	= 0x12, /**< The buddy's service-specific miscalleneous info changed.     */
	GAIM_BUDDY_SIGNON_TIME		= 0x14, /**< The buddy's signon time changed.     */
	GAIM_BUDDY_EVIL				= 0x18,  /**< The buddy's warning level changed.     */
	GAIM_BUDDY_DIRECTIM_CONNECTED = 0x21, /**< Connected to the buddy via DirectIM.  */
	GAIM_BUDDY_DIRECTIM_DISCONNECTED = 0x22 /**< Disconnected from the buddy via DirectIM.  */
	
} GaimBuddyEvent;
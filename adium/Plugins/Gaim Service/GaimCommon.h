
//Extensive debug logging
#define GAIM_DEBUG  TRUE

//Gaim includes
#include "internal.h"
#include "connection.h"
#include "conversation.h"
#include "core.h"
#include "debug.h"
#include "ft.h"
#include "imgstore.h"
#include "notify.h"
#include "plugin.h"
#include "pounce.h"
#include "prefs.h"
#include "privacy.h"
#include "proxy.h"
#include "request.h"
#include "signals.h"
#include "sslconn.h"
#include "sound.h"
#include "util.h"

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
	GAIM_BUDDY_EVIL				= 0x18  /**< The buddy's warning level changed.     */
	
} GaimBuddyEvent;

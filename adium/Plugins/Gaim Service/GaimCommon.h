
//Extensive debug logging
#define GAIM_DEBUG  FALSE

//Gaim includes
#include <Libgaim/libgaim.h>

#define KEY_ACCOUNT_GAIM_PROXY_TYPE			@"Proxy Type"
#define KEY_ACCOUNT_GAIM_PROXY_HOST			@"Proxy Host"
#define KEY_ACCOUNT_GAIM_PROXY_PORT			@"Proxy Port"
#define KEY_ACCOUNT_GAIM_PROXY_USERNAME		@"Proxy Username"
#define KEY_ACCOUNT_GAIM_PROXY_PASSWORD		@"Proxy Password"
#define KEY_ACCOUNT_GAIM_CHECK_MAIL			@"Check Mail"

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

//Proxy types
typedef enum
{
	Gaim_Proxy_None		= 0,
	Gaim_Proxy_Default  = 1,
	Gaim_Proxy_HTTP		= 2,
	Gaim_Proxy_SOCKS4   = 3,
	Gaim_Proxy_SOCKS5   = 4
} AdiumGaimProxyType;
	

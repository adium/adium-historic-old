/*
 *  Off-the-Record Messaging plugin for gaim
 *  Copyright (C) 2004-2005  Nikita Borisov and Ian Goldberg
 *                           <otr@cypherpunks.ca>
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of version 2 of the GNU General Public License as
 *  published by the Free Software Foundation.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#ifndef __OTRG_OTR_PLUGIN_H__
#define __OTRG_OTR_PLUGIN_H__

/* Gaim headers */
#include "account.h"
#include "plugin.h"

/* libotr headers */
#include <libotr/context.h>
#include <libotr/userstate.h>

#define PRIVKEYFNAME "otr.private_key"
#define STOREFNAME "otr.fingerprints"

extern GaimPlugin *otrg_plugin_handle;

extern OtrlUserState otrg_plugin_userstate;

/* Send an IM from the given account to the given recipient.  Display an
 * error dialog if that account isn't currently logged in. */
void otrg_plugin_inject_message(GaimAccount *account, const char *recipient,
	const char *message);

/* Generate a private key for the given accountname/protocol */
void otrg_plugin_create_privkey(const char *accountname,
	const char *protocol);

/* Send the default OTR Query message to the correspondent of the given
 * context, from the given account.  [account is actually a
 * GaimAccount*, but it's declared here as void* so this can be passed
 * as a callback.] */
void otrg_plugin_send_default_query(ConnContext *context, void *account);

/* Send the default OTR Query message to the correspondent of the given
 * conversation. */
void otrg_plugin_send_default_query_conv(GaimConversation *conv);

/* Disconnect a context, sending a notice to the other side, if
 * appropriate. */
void otrg_plugin_disconnect(ConnContext *context);

/* Return the user state used by the gaim-otr plugin */
OtrlUserState* otr_plugin_get_userstate(void);

#endif

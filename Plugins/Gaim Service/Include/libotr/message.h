/*
 *  Off-the-Record Messaging library
 *  Copyright (C) 2004-2005  Nikita Borisov and Ian Goldberg
 *                           <otr@cypherpunks.ca>
 *
 *  This library is free software; you can redistribute it and/or
 *  modify it under the terms of version 2.1 of the GNU Lesser General
 *  Public License as published by the Free Software Foundation.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *  Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public
 *  License along with this library; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#ifndef __MESSAGE_H__
#define __MESSAGE_H__

typedef enum {
    OTRL_NOTIFY_ERROR,
    OTRL_NOTIFY_WARNING,
    OTRL_NOTIFY_INFO
} OtrlNotifyLevel;

typedef struct s_OTRConfirmResponse OTRConfirmResponse;

typedef struct s_OtrlMessageAppOps {
    /* Create a private key for the given accountname/protocol if
     * desired. */
    void (*create_privkey)(void *opdata, const char *accountname,
	    const char *protocol);

    /* Send the given IM to the given recipient from the given
     * accountname/protocol. */
    void (*inject_message)(void *opdata, const char *accountname,
	    const char *protocol, const char *recipient, const char *message);

    /* Display a notification dialog */
    void (*notify)(void *opdata, OtrlNotifyLevel level, const char *title,
	    const char *primary, const char *secondary);

    /* When the list of ConnContexts changes (including a change in
     * state), this is called so the UI can be updated. */
    void (*update_context_list)(void *opdata);

    /* Return a newly-allocated string containing a human-friendly name
     * for the given protocol id */
    const char *(*protocol_name)(void *opdata, const char *protocol);

    /* Deallocate a string allocated by protocol_name */
    void (*protocol_name_free)(void *opdata, const char *protocol_name);

    /* Ask the user to confirm an unknown fingerprint (contained in kem)
     * for the given username of the given protocol.  When the user has
     * decided, call response_cb(ops, opdata, response_data, resp) where
     * resp is 1 to accept the fingerprint, 0 to reject it, and -1 if
     * the user didn't make a choice (say, by destroying the dialog
     * window).  BE SURE to call response_cb no matter what happens. */
    void (*confirm_fingerprint)(void *opdata, const char *username,
	    const char *protocol, OTRKeyExchangeMsg kem,
	    void (*response_cb)(struct s_OtrlMessageAppOps *ops, void *opdata,
		OTRConfirmResponse *response_data, int resp),
	    OTRConfirmResponse *response_data);

    /* The list of known fingerprints has changed.  Write them to disk. */
    void (*write_fingerprints)(void *opdata);

    /* A ConnContext has entered a secure state. */
    void (*gone_secure)(void *opdata, ConnContext *context);

    /* A ConnContext has left a secure state. */
    void (*gone_insecure)(void *opdata, ConnContext *context);

    /* A ConnContext has received a Key Exchange Message, which is the
     * same as the one we already knew.  is_reply indicates whether the
     * Key Exchange Message is a reply to one that we sent to them. */
    void (*still_secure)(void *opdata, ConnContext *context, int is_reply);

    /* Log a message.  The passed message will end in "\n". */
    void (*log_message)(void *opdata, const char *message);

} OtrlMessageAppOps;

/* Deallocate a message allocated by other otrl_message_* routines. */
void otrl_message_free(char *message);

gcry_error_t otrl_message_sending(OtrlMessageAppOps *ops, void *opdata,
	const char *accountname, const char *protocol, const char *recipient,
	const char *message, char **messagep);

int otrl_message_receiving(OtrlMessageAppOps *ops, void *opdata,
	const char *accountname, const char *protocol,
	const char *sender, const char *message, char **messagep,
	void (*add_appdata)(void *data, ConnContext *context),
	void *data);

#endif

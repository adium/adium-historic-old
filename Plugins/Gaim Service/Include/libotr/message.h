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

typedef enum {
    OTRL_POLICY_OPPORTUNISTIC,
    OTRL_POLICY_NEVER,
    OTRL_POLICY_MANUAL,
    OTRL_POLICY_ALWAYS
} OtrlPolicy;

#define OTRL_POLICY_DEFAULT OTRL_POLICY_OPPORTUNISTIC

typedef struct s_OTRConfirmResponse OTRConfirmResponse;

typedef struct s_OtrlMessageAppOps {
    /* Return the OTR policy for the given context. */
    OtrlPolicy (*policy)(void *opdata, ConnContext *context);

    /* Create a private key for the given accountname/protocol if
     * desired. */
    void (*create_privkey)(void *opdata, const char *accountname,
	    const char *protocol);

    /* Report whether you think the given user is online.  Return 1 if
     * you think he is, 0 if you think he isn't, -1 if you're not sure.
     *
     * If you return 1, messages such as heartbeats or other
     * notifications may be sent to the user, which could result in "not
     * logged in" errors if you're wrong. */
    int (*is_logged_in)(void *opdata, const char *accountname,
	    const char *protocol, const char *recipient);

    /* Send the given IM to the given recipient from the given
     * accountname/protocol. */
    void (*inject_message)(void *opdata, const char *accountname,
	    const char *protocol, const char *recipient, const char *message);

    /* Display a notification message for a particular accountname /
     * protocol / username conversation. */
    void (*notify)(void *opdata, OtrlNotifyLevel level,
	    const char *accountname, const char *protocol,
	    const char *username, const char *title,
	    const char *primary, const char *secondary);

    /* Display an OTR control message for a particular accountname /
     * protocol / username conversation.  Return 0 if you are able to
     * successfully display it.  If you return non-0 (or if this
     * function is NULL), the control message will be displayed inline,
     * as a received message. */
    int (*display_otr_message)(void *opdata, const char *accountname,
	    const char *protocol, const char *username, const char *msg);

    /* When the list of ConnContexts changes (including a change in
     * state), this is called so the UI can be updated. */
    void (*update_context_list)(void *opdata);

    /* Return a newly-allocated string containing a human-friendly name
     * for the given protocol id */
    const char *(*protocol_name)(void *opdata, const char *protocol);

    /* Deallocate a string allocated by protocol_name */
    void (*protocol_name_free)(void *opdata, const char *protocol_name);

    /* Ask the user of the given accountname to confirm an unknown
     * fingerprint (contained in kem) for the given username of the
     * given protocol.  When the user has decided, call
     * response_cb(us, ops, opdata, response_data, resp) where resp is 1
     * to accept the fingerprint, 0 to reject it, and -1 if the user
     * didn't make a choice (say, by destroying the dialog window).
     * BE SURE to call response_cb no matter what happens. */
    void (*confirm_fingerprint)(OtrlUserState us, void *opdata,
	    const char *accountname, const char *protocol,
	    const char *username, OTRKeyExchangeMsg kem,
	    void (*response_cb)(OtrlUserState us,
		struct s_OtrlMessageAppOps *ops, void *opdata,
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

/* Handle a message about to be sent to the network.  It is safe to pass
 * all messages about to be sent to this routine.  add_appdata is a
 * function that will be called in the event that a new ConnContext is
 * created.  It will be passed the data that you supplied, as well as a
 * pointer to the new ConnContext.  You can use this to add
 * application-specific information to the ConnContext using the
 * "context->app" field, for example.  If you don't need to do this, you
 * can pass NULL for the last two arguments of otrl_message_sending.  
 *
 * If this routine
 * returns non-zero, then the library tried to encrypt the message,
 * but for some reason failed.  DO NOT send the message in the clear in
 * that case.
 * 
 * If *messagep gets set by the call to something non-NULL, then you
 * should replace your message with the contents of *messagep, and
 * send that instead.  Call otrl_message_free(*messagep) when you're
 * done with it. */
gcry_error_t otrl_message_sending(OtrlUserState us, OtrlMessageAppOps
	*ops, void *opdata, const char *accountname, const char *protocol,
	const char *recipient, const char *message, char **messagep,
	void (*add_appdata)(void *data, ConnContext *context),
	void *data);

/* Handle a message just received from the network.  It is safe to pass
 * all received messages to this routine.  add_appdata is a function
 * that will be called in the event that a new ConnContext is created.
 * It will be passed the data that you supplied, as well as
 * a pointer to the new ConnContext.  You can use this to add
 * application-specific information to the ConnContext using the
 * "context->app" field, for example.  If you don't need to do this, you
 * can pass NULL for the last two arguments of otrl_message_receiving.  
 *
 * If otrl_message_receiving returns 1, then the message you received
 * was an internal protocol message, and no message should be delivered
 * to the user.
 *
 * If it returns 0, then check if *messagep was set to non-NULL.  If
 * so, replace the received message with the contents of *messagep, and
 * deliver that to the user instead.  You must call
 * otrl_message_free(*messagep) when you're done with it.
 *
 * If otrl_message_receiving returns 0 and *messagep is NULL, then this
 * was an ordinary, non-OTR message, which should just be delivered to
 * the user without modification. */
int otrl_message_receiving(OtrlUserState us, OtrlMessageAppOps *ops,
	void *opdata, const char *accountname, const char *protocol,
	const char *sender, const char *message, char **messagep,
	void (*add_appdata)(void *data, ConnContext *context),
	void *data);

/* Put a connection into the DISCONNECTED state, first sending the
 * other side a notice that we're doing so if we're currently CONNECTED,
 * and we think he's logged in. */
void otrl_message_disconnect(OtrlUserState us, OtrlMessageAppOps *ops,
	void *opdata, const char *accountname, const char *protocol,
	const char *username);

#endif

/**
 * @file webcam.h Webcam API
 * @ingroup core
 *
 * gaim
 *
 * Copyright (C) 2003, Tim Ringenbach <omarvo@hotmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#ifndef _GAIM_WEBCAM_H_
#define _GAIM_WEBCAM_H_

#include "connection.h"
#include "codec.h"

/**************************************************************************/
/** Data Structures                                                       */
/**************************************************************************/

typedef struct _GaimWebcam GaimWebcam;

/**
 * Everything the core needs to know about webcam it's downloading.
 */
struct _GaimWebcam {
	GaimConnection *gc; /**< The GaimConnection associated with the cam. */
	gchar *name;        /**< The name of the buddy who's cam we're viewing. */
	GaimCodec *codec;   /**< The handle for the codec used to decode it. */
	gpointer ui_data;   /**< A place for the ui to stick its extra data. */
	gpointer proto_data;/**< A place for the prpl to stick its extra data. */
};

/**
 * The reason gaim_webcam_got_close() was called.
 */
enum gaim_webcam_close_reason {
	WEBCAM_UNKNOWN = 0, /**< Unknown reason. */
	WEBCAM_STOPPED_CASTING, /**< They turned the cam off. */
	WEBCAM_PERM_CANC, /**< They canceled permission. */
	WEBCAM_USER_DECL, /**< They declined our attempt to view them. */
	WEBCAM_NOT_ONLINE, /**< The webcam isn't casting. */
	WEBCAM_CONNECTION_PEER_FAILED, /**< The direct connection failed. */
	WEBCAM_CONNECTION_SERVER_FAILED, /**< Connectioning to some centeralized server failed */
};

/**
 * The UI Ops structure.
 *
 * The UI fills this out with functions it wants called when webcam related stuff happens.
 */
struct gaim_webcam_ui_ops
{
	void (*new)(GaimWebcam *gwc); /**< Core calls this when a new webcam window needs opening. */
	void (*update)(GaimWebcam *wc,
			const unsigned char *image, unsigned int size,
			unsigned int timestamp, unsigned int id);      /**< This updates the picture. */
	void (*frame_finished)(GaimWebcam *wc, unsigned int id);     /**< This is called when frame number id is done */
	void (*close_cam)(GaimWebcam *gwc);     /**< The core will call this when it won't call update anymore.*/
	void (*got_invite)(GaimConnection *gc, const gchar *who); /**< Call when an invite is received. */
};

#ifdef __cplusplus
extern "C" {
#endif

/**************************************************************************/
/** @name Webcam Viewing (downloading/receiving) API                      */
/**************************************************************************/
/*@{*/

/**
 * Creates a new webcam.
 *
 * Prpl's call this when they'll have webcam data soon.
 * The core then tells the UI to pop up a window or something
 * and get ready.
 *
 * @param gc The GaimConnection associated with the webcam.
 * @param from The screenname of the buddy who's webcam we are about to view.
 * @param format The format of the data that will be received, so the core
 *               knows which codec to use.
 * @return A newly allocated GaimWebcam pointer, to be used as a handle
 *         for most other functions from here on out.
 */
GaimWebcam *gaim_webcam_new(GaimConnection *gc, const char *from, const char *format);

/**
 * Closes and destroys an open webcam.
 *
 * The UI calls this when the user tells it to close the webcam.
 *
 * @param gwc The webcam to close. It should not be used after this call,
 *            as it will be g_free()'d.
 */
void gaim_webcam_close(GaimWebcam *gwc);

/**
 * Called when we get invited to view a webcam.
 *
 * The prpl calls this function when it receives a
 * webcam invitation.
 *
 * @param gc The GaimConnection associated with the invite.
 * @param from The buddy who invited us.
 */
void gaim_webcam_got_invite(GaimConnection *gc, const char *from);

/**
 * The webcam was closed by the other end.
 *
 * The prpl calls this is the webcam gets closed from the other end.
 *
 * @param gwc The webcam handle. Will be g_free()'d after this call.
 * @param reason The reason for the closure.
 */
void gaim_webcam_got_close(GaimWebcam *gwc, enum gaim_webcam_close_reason reason);

/**
 * Sends image data to the core for processing and shipping (to the UI).
 *
 * @param gwc The GaimWebcam handle.
 * @param image The image data, in the format specified in the gaim_webcam_new() call.
 * @param image_size The length of the entire frame.
 * @param real_size The size of the image buffer.
 * @param timestamp A timestamp. Currently unused.
 * @param id The frame number. Used to look up the frame, for future calls.
 */

void gaim_webcam_got_data(GaimWebcam *gwc,
		unsigned char *image, unsigned int image_size, unsigned int real_size,
		unsigned int timestamp, unsigned int id);

/**
 * Called by UI when we accepted an invite.
 *
 * @param gc The GaimConnection.
 * @param who The person that invited us.
 */
void gaim_webcam_invite_accept(GaimConnection *gc, const gchar *who);

/**
 * Called by UI when we declined an invite.
 *
 * @param gc The GaimConnection.
 * @param who The person that invited us.
 */
void gaim_webcam_invite_decline(GaimConnection *gc, const gchar *who);

/*@}*/

/**************************************************************************/
/** @name Webcam Sending (casting/uploading) API                          */
/**************************************************************************/
/*@{*/

/**
 * Called by the prpl when we're casting and someone connects,
 * disconnects, or requests to connect.
 *
 * @param gc The GaimConnection.
 * @param who The person who is or wants to view our cam.
 * @param connect 0 = disconnect, 1=connect, 2=request. FIXME: change this to an enum.
 */
void gaim_webcam_viewer(GaimConnection *gc, char *who, int connect);

/**
 * Called to request the core send us (the prpl) webcam data.
 *
 * @param gc The gc.
 * @param send Whether or not to send us data.
 */
void gaim_webcam_data_request(GaimConnection *gc, int send);

/**
 * We invited someone to view our webcam, and they accepted.
 *
 * @param gc The GaimConnection associated with invite.
 * @param from The person who accepted our invitation.
 */
void gaim_webcam_got_invite_accept(GaimConnection *gc, const char *from);

/**
 * We invited someone to vie our webcam, but they declined.
 *
 * @param gc The GaimConnection.
 * @param from The person who declined our invite.
 */
void gaim_webcam_got_invite_decline(GaimConnection *gc, const char *from);

/*@}*/

/**************************************************************************/
/** @name UI Registration Functions                                       */
/**************************************************************************/
/*@{*/

/**
 * Sets the UI operations structure to be used for the webcams.
 *
 * @param ops The ops struct.
 */
void gaim_webcam_set_ui_ops(struct gaim_webcam_ui_ops *ops);

/**
 * Returns the UI operations structure to be used for the webcams.
 *
 * @return The UI operations structure.
 */
struct gaim_webcam_ui_ops *gaim_webcam_get_ui_ops(void);

/*@}*/

#ifdef __cplusplus
extern "C" {
#endif
#endif /* _GAIM_WEBCAM_H_ */

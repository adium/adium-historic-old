/**
 * @file codec.h Codec API
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

#ifndef _GAIM_CODEC_H_
#define _GAIM_CODEC_H_

#include <glib.h>

/**************************************************************************/
/** Data Structures                                                       */
/**************************************************************************/

typedef struct _GaimCodec GaimCodec;
typedef enum _GaimCodecFlags GaimCodecFlags;
typedef struct _GaimCodecPlOps GaimCodecPlOps;
typedef struct _GaimCodecData GaimCodecData;
typedef void (*GaimCodecCbFunc)(GaimCodec *c, const gchar *buf, gint len, gint frame_no, gpointer data);

/**
 * The GaimCodec type.
 * Used as a handle and stores state information for codecing.
 */
struct _GaimCodec {
	GaimCodecData *codec_data; /**< Pointer to the object shared by all codecs of the same type */
	GaimCodecCbFunc encoded;  /**< Function to call when the data has been encoded. */
	GaimCodecCbFunc decoded;  /**< Function to call when the data has been decoded.
				       Called in whatever context the codec plugin feels like. */
	gpointer plugin_data;     /**< For the plugin's private data. */
	gpointer cb_data;         /**< Data to be passed to the encoded and decoded callbacks. */
};

/**
 * ORed flags to indicate where the codec is opened for encoding or decoding
 * or both.
 */
enum _GaimCodecFlags {
	GaimCodecEncode = 0x01, /**< Open for encoding. */
	GaimCodecDecode = 0x02, /**< Open for decoding. */
};

/**
 * Struct filled in by the plugins. It may fill out more than one of these, if it
 * supports multiple formats.
 */
struct _GaimCodecPlOps {
	gboolean (*open)(GaimCodec *c, GaimCodecFlags flags); /**< Allows the codec to initialize itself. */
	void (*encode)(GaimCodec *c, gchar *buffer, gint size,
				gint frame_size, gint frame_no); /**< Passes data to be encoded. */
	void (*decode)(GaimCodec *c, gchar *buffer, gint size,
				gint frame_size, gint frame_no); /**< Passes data to be decoded. */
	void (*close)(GaimCodec *c); /**< Indicates no further data will be codeced for now. */
};

/**
 * A struct to store a set of ops along with the format they are for.
 */
struct _GaimCodecData {
	gchar *format; /**< The format of the data. */
	GaimCodecPlOps *ops; /**< The functions to operate on said data. */
};

#ifdef __cplusplus
extern "C" {
#endif

/**************************************************************************/
/** @name Codec API                                                       */
/**************************************************************************/
/*@{*/

/**
 * Opens the codec for encoding/decoding.
 *
 * Currently, decoded data is in the PNM format, although technically any format
 * supported by gdk_pixbuf_loader would work. Although other UI's might not like
 * that.
 *
 * @param foramt The format that needs codecing.
 * @param flags Whether to initalize things for encoding or decoding.
 * @param encoded Callback for when some amount of data has been encoded. Can be NULL.
 * @param decoded Callback for when some amount of data has been decoded. Can be NULL.
 * @param data User supplied data to be passed to the encoded and decoded functions.
 * @return A GaimCodec object to be used as a handle for other calls, or NULL, if no
 *         codec for that specified format and flags could be found, or something else
 *         went wrong.
 */
GaimCodec *gaim_codec_open(const gchar *format, GaimCodecFlags flags, GaimCodecCbFunc encoded,
						GaimCodecCbFunc decoded, gpointer data);

/**
 * Encode some data.
 *
 * @param c The GaimCodec handled returned from gaim_codec_open.
 * @param buffer The data to be encoded.
 * @param size The size of buffer.
 * @param frame_size The size of the total frame, in case buffer isn't all the data.
 * @param frame_no A unique number for this frame. Futher calls to this function with the
 *                 same frame_no will be assumed the rest of the frame. More than one frame
 *                 maybe be in the process of encoding at once.
 */
void gaim_codec_encode(GaimCodec *c, gchar *buffer, gint size, gint frame_size, gint frame_no);

/**
 * Decode some data.
 *
 * @param c The GaimCodec handled returned from gaim_codec_open.
 * @param buffer The data to be decoded.
 * @param size The size of buffer.
 * @param frame_size The size of the total frame, in case buffer isn't all the data.
 * @param frame_no A unique number for this frame. Futher calls to this function with the
 *                 same frame_no will be assumed the rest of the frame. More than one frame
 *                 maybe be in the process of decoding at once.
 */
void gaim_codec_decode(GaimCodec *c, gchar *buffer, gint size, gint frame_size, gint frame_no);

/**
 * Close the codecing session.
 *
 * This function is called when no further encoding/decoding will be
 * performed with the given GaimCodec handle.
 *
 * @param c The GaimCodec to close. The struct will be freed and should not be
 *          used after this call.
 */
void gaim_codec_close(GaimCodec *c);
/*@}*/


/**************************************************************************/
/** @name Codec Plugin API                                                */
/**************************************************************************/
/*@{*/

/**
 * Register a codec.
 *
 * This registers a set of Codec Ops and associates them with the given format.
 *
 * @param format The data format the codec handles. Use multiple calls for mulitple
 *               formats.
 * @param ops The functions to call to perform the encoding/decoding. This struct is
 *            filled out by the caller beforehand.
 */
void gaim_codec_register_codec(const gchar *format, GaimCodecPlOps *ops);

/**
 * Unregister a codec.
 *
 * This is the inverse of gaim_codec_register_codec. It removes the format
 * and ops from Gaim's internal data structures. Both still must be free()'d
 * if they were allocated on the heap. This would only be called normally
 * by a plugin being unloaded.
 *
 * @foramt The data format previously passed to gaim_codec_register_codec.
 * @ops The ops previously passed to gaim_codec_register_coec.
 */
void gaim_codec_unregister_codec(const gchar *format, GaimCodecPlOps *ops);

/**
 * Data has been decoded.
 *
 * The codec plugin calls this function when data has been decoded.
 *
 * @param c The GaimCodec handle.
 * @param buf The buffer of decoded data.
 * @param len The length of buf.
 * @param frame_no The frame number previously given to us.
 */
void gaim_codec_decoded_cb(GaimCodec *c, const gchar *buf, gint len, gint frame_no);

/**
 * Data has been encoded.
 *
 * The codec plugin calls this function when data has been encoded.
 *
 * @param c The GaimCodec handle.
 * @param buf The buffer of encoded data.
 * @param len The length of buf.
 * @param frame_no The frame number previously given to us.
 */
void gaim_codec_encoded_cb(GaimCodec *c, const gchar *buf, gint len, gint frame_no);

/*@}*/

#ifdef __cplusplus
}
#endif
#endif /* _GAIM_CODEC_H_ */

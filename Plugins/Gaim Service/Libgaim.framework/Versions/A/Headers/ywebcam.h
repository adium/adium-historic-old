/* @file ywebcam.h Yahoo Webcam Functions and data structures.
 *
 * gaim
 *
 * Some code copyright (C) 2003, Timothy T Ringenbach <omarvo@hotmail.com>
 * Some code copyright (C) 2002, Philip S Tellis <philip . tellis AT gmx . net>
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
 *
 */

#define YAHOO_WEBCAM_HOST "webcam.yahoo.com"
#define YAHOO_WEBCAM_PORT 5100

extern GaimPrplWebcam yahoo_webcam_cbs;

enum yahoo_webcam_direction {
        YAHOO_WEBCAM_DOWNLOAD=0,
        YAHOO_WEBCAM_UPLOAD
};

struct yahoo_webcam {
	GaimWebcam *gwc;
	GaimConnection *gc;
	enum yahoo_webcam_direction dir; /* Uploading or downloading */
	int conn_type;     /* 0=Dialup, 1=DSL/Cable, 2=T1/Lan */

	char *user;        /* user we are viewing */
	char *server;      /* webcam server to connect to */

	char *key;         /* key to connect to the server with */
	char *description; /* webcam description */
	char *my_ip;       /* own ip number */
	int inpa;
	int fd;
	guchar *rxqueue;
	int rxlen;
	unsigned int data_size;
	unsigned int to_read;
	unsigned int timestamp;
	unsigned char packet_type;

	unsigned int frame_id;
};

/*
void yahoo_webcam_get_feed(GaimConnection *gc, const char *who);
static void yahoo_webcam_close_feed(GaimConnection *gc, const char *who);
*/
void yahoo_process_webcam_key(GaimConnection *gc, struct yahoo_packet *pkt);
void yahoo_webcam_get_feed(GaimConnection *gc, const char *who);

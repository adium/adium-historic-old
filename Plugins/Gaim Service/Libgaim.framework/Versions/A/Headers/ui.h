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

#ifndef __OTRG_UI_H__
#define __OTRG_UI_H__

#include <libotr/context.h>

typedef struct {
    void (*update_fingerprint)(void);

    void (*update_keylist)(void);
	
	Fingerprint *(*selected_fingerprint)(void);
} OtrgUiUiOps;

/* Set the UI ops */
void otrg_ui_set_ui_ops(OtrgUiUiOps *ops);

/* Get the UI ops */
OtrgUiUiOps *otrg_ui_get_ui_ops(void);

/* Call this function when the DSA key is updated; it will redraw the
 * UI. */
void otrg_ui_update_fingerprint(void);

/* Update the keylist, if it's visible */
void otrg_ui_update_keylist(void);

#endif

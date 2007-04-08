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

/*these functions are defined in Libgaim.framework, but they are not declared
 *	in any header.
 */

void gaim_xfer_choose_file_ok_cb(void *user_data, const char *filename);
void gaim_xfer_choose_file_cancel_cb(void *user_data, const char *filename);

/* those aren't actually void * pointers, but it doesn't
 * really matter because in the end all we need is to
 * make gcc STFU about the function def over in the meanwhile stuff.
 * -RAF
 */
char * mwServiceAware_getText(void *, void *);

/* this is probably the wrong prototype, but I honestly
 * don't know where to find the function and the warning
 * is making me angry.
 * I checked our libgaim repo and the upstream gaim cvs repo for it.
 */
void oscar_reformat_screenname(GaimConnection *gc, const char *formattedUID);

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

#ifndef __PRIVKEY_H__
#define __PRIVKEY_H__

#include "context.h"

typedef struct s_PrivKey {
    char *accountname;
    char *protocol;
    gcry_sexp_t privkey;
    unsigned char *pubkey_data;
    size_t pubkey_datalen;
    struct s_PrivKey *next;
    struct s_PrivKey **tous;
} PrivKey;

/* Convert a 20-byte hash value to a 45-byte human-readable value */
void otrl_privkey_hash_to_human(char human[45], unsigned char hash[20]);

/* Calculate a human-readable hash of our DSA public key */
char *otrl_privkey_fingerprint(const char *accountname, const char *protocol);

/* Read a private DSA key from a file on disk. */
gcry_error_t otrl_privkey_read(const char *filename);

/* Generate a private DSA key for a given account, storing it into a
 * file on disk, and loading it into memory.  Overwrite any previously
 * generated key. */
gcry_error_t otrl_privkey_generate(const char *filename,
	const char *accountname, const char *protocol);

/* Read the fingerprint store from a file on disk.  Use add_app_data to
 * add application data to each ConnContext so created. */
gcry_error_t otrl_privkey_read_fingerprints(const char *filename,
	void (*add_app_data)(void *data, ConnContext *context),
	void  *data);

/* Write the fingerprint store to a file on disk. */
gcry_error_t otrl_privkey_write_fingerprints(const char *filename);

/* Fetch the private key associated with the given account */
PrivKey *otrl_privkey_find(const char *accountname, const char *protocol);

/* Forget a private key */
void otrl_privkey_forget(PrivKey *privkey);

/* Forget all private keys */
void otrl_privkey_forget_all(void);

#endif

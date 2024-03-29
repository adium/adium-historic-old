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

#ifndef __TLV_H__
#define __TLV_H__

typedef struct s_OtrlTLV {
    unsigned short type;
    unsigned short len;
    unsigned char *data;
    struct s_OtrlTLV *next;
} OtrlTLV;

/* TLV types */

/* This is just padding for the encrypted message, and should be ignored. */
#define OTRL_TLV_PADDING         0x0000

/* The sender has thrown away his OTR session keys with you */
#define OTRL_TLV_DISCONNECTED    0x0001


/* Make a single TLV, copying the supplied data */
OtrlTLV *otrl_tlv_new(unsigned short type, unsigned short len,
	const unsigned char *data);

/* Construct a chain of TLVs from the given data */
OtrlTLV *otrl_tlv_parse(const unsigned char *serialized, size_t seriallen);

/* Deallocate a chain of TLVs */
void otrl_tlv_free(OtrlTLV *tlv);

/* Find the serialized length of a chain of TLVs */
size_t otrl_tlv_seriallen(const OtrlTLV *tlv);

/* Serialize a chain of TLVs.  The supplied buffer must already be large
 * enough. */
void otrl_tlv_serialize(unsigned char *buf, const OtrlTLV *tlv);

/* Return the first TLV with the given type in the chain, or NULL if one
 * isn't found.  (The tlvs argument isn't const because the return type
 * needs to be non-const.) */
OtrlTLV *otrl_tlv_find(OtrlTLV *tlvs, unsigned short type);

#endif

/*-GNU-GPL-BEGIN-*
RULI - Resolver User Layer Interface - Querying DNS SRV records
Copyright (C) 2003 Everton da Silva Marques

RULI is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2, or (at your option)
any later version.

RULI is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with RULI; see the file COPYING.  If not, write to
the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
Boston, MA 02111-1307, USA.
*-GNU-GPL-END-*/

/*
  $Id: ruli_parse.h,v 1.13 2004/06/06 04:27:48 evertonm Exp $
  */


#ifndef RULI_PARSE_H
#define RULI_PARSE_H


#include <netinet/in.h>
#include "ruli_util.h"

enum {
  RULI_PARSE_RR_OK   = 0,
  RULI_PARSE_RR_FAIL
};

typedef struct {
  ruli_uint16_t      priority;
  ruli_uint16_t      weight;
  ruli_uint16_t      port;
  const ruli_uint8_t *target;
  int                target_len;
} ruli_srv_rdata_t;

int ruli_parse_rr_srv(ruli_srv_rdata_t *srv_rdata,
		      const ruli_uint8_t *rdata, ruli_uint16_t rdlength);

#endif /* RULI_PARSE_H */

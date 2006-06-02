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
  $Id: ruli_parse.c,v 1.20 2005/06/07 22:17:51 evertonm Exp $
  */


#include <assert.h>
#include <string.h>

#include "ruli_parse.h"
#include "ruli_limits.h"

static const ruli_uint8_t *skip_rr_owner(const ruli_uint8_t *msg, 
	         		         const ruli_uint8_t *past_end)
{
  int len;

  /*
   * Iterate over labels
   */
  for (;;) {
    if (msg >= past_end)
      return 0;

    len = *msg;

    /* Last label? */
    if (!len) {
      const ruli_uint8_t *next = msg + 1;

      if (next > past_end)
	return 0;

      return next;
    }

    /* Name compression? */
    if ((len & 0xC0) == 0xC0) {
      const ruli_uint8_t *next = msg + 2;

      if (next > past_end)
	return 0;

      return next;
    }

    msg += len + 1;
  }

  /*
   * NOT REACHED
   */
  assert(0);

  return 0;
}

int ruli_parse_rr_srv(ruli_srv_rdata_t *srv_rdata,
		      const ruli_uint8_t *rdata, ruli_uint16_t rdlength)
{
  const ruli_uint8_t *i;
  const ruli_uint8_t *past_end = rdata + rdlength;

  /* 
     offset data     size
     ------------------------
     0      priority 2
     2      weight   2
     4      port     2
     6      target   1..255
  */

  if (rdlength < 7)
    return RULI_PARSE_RR_FAIL;

  if (rdlength > 261)
    return RULI_PARSE_RR_FAIL;

  srv_rdata->priority = ruli_pack2(rdata);
  srv_rdata->weight   = ruli_pack2(rdata + 2);
  srv_rdata->port     = ruli_pack2(rdata + 4);

  {
    const ruli_uint8_t *trg = rdata + 6;

    i = skip_rr_owner(trg, past_end);
    if (i != past_end)
      return RULI_PARSE_RR_FAIL;
    
    srv_rdata->target     = trg;
    srv_rdata->target_len = past_end - trg;
  }

  assert(srv_rdata->target_len <= RULI_LIMIT_DNAME_ENCODED);

  return RULI_PARSE_RR_OK;
}


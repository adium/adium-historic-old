/*
 *  adiumPurpleCertificateTrustWarning.h
 *  Adium
 *
 *  Created by Andreas Monitzer on 2007-11-05.
 *  Copyright 2007 Andreas Monitzer. All rights reserved.
 *
 */

#include <CoreFoundation/CFArray.h>
#include <libpurple/libpurple.h>

void adium_query_cert_chain(PurpleSslConnection *gsc, OSStatus err, const char *hostname, CFArrayRef certs, void (*cert_cleanup)(void *userdata), void *userdata);

gboolean adium_cert_shouldverify(PurpleSslConnection *gsc);

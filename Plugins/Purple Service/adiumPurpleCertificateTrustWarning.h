/*
 *  adiumPurpleCertificateTrustWarning.h
 *  Adium
 *
 *  Created by Andreas Monitzer on 2007-11-05.
 *  Copyright 2007 Andreas Monitzer. All rights reserved.
 *
 */

#include <CoreFoundation/CFArray.h>

void adium_query_cert_chain(OSStatus err, const char *hostname, CFArrayRef certs, void (*accept_cert)(void *userdata), void (*reject_cert)(void *userdata), void *userdata);

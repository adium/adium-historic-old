//
//  adiumGaimOTR.h
//  Adium
//
//  Created by Evan Schoenberg on 1/22/05.
//  Copyright 2005 The Adium Team. All rights reserved.
//

#import "SLGaimCocoaAdapter.h"

void adium_gaim_otr_connect_conv(GaimConversation *conv);
void adium_gaim_otr_disconnect_conv(GaimConversation *conv);
void initGaimOTRSupprt(void);
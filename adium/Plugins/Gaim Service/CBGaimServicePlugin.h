 //
//  CBGaimServicePlugin.h
//  Adium
//
//  Created by Colin Barrett on Sun Oct 19 2003.
//

#include "internal.h"
#include "connection.h"
#include "conversation.h"
#include "core.h"
#include "debug.h"
#include "ft.h"
#include "notify.h"
#include "plugin.h"
#include "pounce.h"
#include "prefs.h"
#include "privacy.h"
#include "proxy.h"
#include "request.h"
#include "signals.h"
#include "sslconn.h"
#include "sound.h"
#include "util.h"

@class AIServiceType;

@interface CBGaimServicePlugin : AIPlugin <AIServiceController> {
        AIServiceType			*handleServiceType;
        
        IBOutlet 	NSView		*view_preferences;
}

- (void)addAccount:(id)anAccount forGaimAccountPointer:(GaimAccount *)gaimAcct;
- (void)removeAccount:(GaimAccount *)gaimAcct;
- (BOOL)configureGaimProxySettings;

@end

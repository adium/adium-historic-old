 //
//  CBGaimServicePlugin.h
//  Adium
//
//  Created by Colin Barrett on Sun Oct 19 2003.
//

#import "GaimCommon.h"

@class AIServiceType;

@interface CBGaimServicePlugin : AIPlugin{
    id  AIMService;
    id  MSNService;
    id  YahooService;
    id  GaduGaduService;
    id  NapsterService;
    id  JabberService;
}

- (void)addAccount:(id)anAccount forGaimAccountPointer:(GaimAccount *)gaimAcct;
- (void)removeAccount:(GaimAccount *)gaimAcct;
- (BOOL)configureGaimProxySettings;
@end

 //
//  CBGaimServicePlugin.h
//  Adium
//
//  Created by Colin Barrett on Sun Oct 19 2003.
//

#import "GaimCommon.h"

@class AIServiceType;

@interface CBGaimServicePlugin : AIPlugin{
	id  eventLoopAdapter;
	
    id  OscarService;
    id  GaduGaduService;
    id  JabberService;
	id  NapsterService;
	id  MSNService;
	id  TrepiaService;
    id  YahooService;
}

- (void)addAccount:(id)anAccount forGaimAccountPointer:(GaimAccount *)gaimAcct;
- (void)removeAccount:(GaimAccount *)gaimAcct;
- (NSDictionary *)systemSOCKSSettingsDictionary;
@end

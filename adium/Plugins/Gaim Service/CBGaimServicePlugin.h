 //
//  CBGaimServicePlugin.h
//  Adium
//
//  Created by Colin Barrett on Sun Oct 19 2003.
//

#import "GaimCommon.h"

@class AIServiceType;

@interface CBGaimServicePlugin : AIPlugin{
    id  OscarService;
    id  GaduGaduService;
    id  JabberService;
	id  NapsterService;
	id  MSNService;
	id  TrepiaService;
    id  YahooService;
	id  YahooJapanService;
	id  NovellService;
}

@end

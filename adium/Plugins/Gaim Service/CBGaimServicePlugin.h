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
	id  MeanwhileService;
	id  MSNService;
	id  NapsterService;
	id  NovellService;
	id  TrepiaService;
    id  YahooService;
	id  YahooJapanService;
}

@end

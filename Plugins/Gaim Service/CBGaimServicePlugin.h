 //
//  CBGaimServicePlugin.h
//  Adium
//
//  Created by Colin Barrett on Sun Oct 19 2003.
//

#import "GaimCommon.h"
#import "SLGaimCocoaAdapter.h"

@interface CBGaimServicePlugin : AIPlugin{
    id  AIMService;
    id  ICQService;
    id  DotMacService;
	id  GaduGaduService;
    id  JabberService;
	id  MeanwhileService;
	id  MSNService;
	id  NapsterService;
	id  NovellService;
	id  TrepiaService;
    id  YahooService;
	id  YahooJapanService;
	id	ZephyrService;
}

@end

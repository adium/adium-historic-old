//
//  CBGaimServicePlugin.m
//  Adium
//
//  Created by Colin Barrett on Sun Oct 19 2003.
//

#import "CBGaimServicePlugin.h"

#import "GaimServices.h"

@interface CBGaimServicePlugin (PRIVATE)
- (void)_initGaim;
@end

static CBGaimServicePlugin  *servicePluginInstance;

@implementation CBGaimServicePlugin

- (void)_initGaim
{
	[NSThread detachNewThreadSelector:@selector(createThreadedGaimCocoaAdapter)
							 toTarget:[SLGaimCocoaAdapter class]
						   withObject:nil];
}

#pragma mark Plugin Installation
//  Plugin Installation ------------------------------------------------------------------------------------------------

#define GAIM_DEFAULTS   @"GaimServiceDefaults"

- (void)installPlugin
{
	servicePluginInstance = self;

	//Register our defaults
    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:GAIM_DEFAULTS 
																		forClass:[self class]]
										  forGroup:GROUP_ACCOUNT_STATUS];
	
	[self _initGaim];

	/*
	static char buf[10];
	g_snprintf(buf, sizeof(buf), "%s", nil);
	
	NSLog(@"%s",buf);
	*/
	
    //Install the services
	AIMService			= [[ESAIMService alloc] init];
	ICQService			= [[ESICQService alloc] init];
	DotMacService		= [[ESDotMacService alloc] init];
	GaduGaduService		= [[ESGaduGaduService alloc] init];
	MSNService			= [[ESMSNService alloc] init];
	NapsterService		= [[ESNapsterService alloc] init];
	NovellService		= [[ESNovellService alloc] init];
	JabberService		= [[ESJabberService alloc] init];
	YahooService		= [[ESYahooService alloc] init];
	YahooJapanService	= [[ESYahooJapanService alloc] init];	
	ZephyrService		= [[ESZephyrService alloc] init];

#ifndef TREPIA_NOT_AVAILABLE
	TrepiaService		= [[ESTrepiaService alloc] init];
#endif
	
#ifndef MEANWHILE_NOT_AVAILABLE
	MeanwhileService	= [[ESMeanwhileService alloc] init];
#endif
}

- (void)uninstallPlugin
{
	[AIMService release]; AIMService = nil;
	[ICQService release]; ICQService = nil;
	[DotMacService release]; DotMacService = nil;
	[GaduGaduService release]; GaduGaduService = nil;
	[JabberService release]; JabberService = nil;
	[NapsterService release]; NapsterService = nil;
	[MSNService release]; MSNService = nil;
	[YahooService release]; YahooService = nil;
	[YahooJapanService release]; YahooJapanService = nil;
	[NovellService release]; NovellService = nil;
	[ZephyrService release]; ZephyrService = nil;

#ifndef TREPIA_NOT_AVAILABLE
	[TrepiaService release]; TrepiaService = nil;
#endif
	
#ifndef MEANWHILE_NOT_AVAILABLE
	[MeanwhileService release]; MeanwhileService = nil;
#endif
}

@end
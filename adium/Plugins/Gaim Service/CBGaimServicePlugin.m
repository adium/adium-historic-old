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

    //Install the services
	OscarService		= [[CBOscarService alloc] initWithService:self];
	GaduGaduService		= [[ESGaduGaduService alloc] initWithService:self];
	MSNService			= [[ESMSNService alloc] initWithService:self];
	NapsterService		= [[ESNapsterService alloc] initWithService:self];
	NovellService		= [[ESNovellService alloc] initWithService:self];
	JabberService		= [[ESJabberService alloc] initWithService:self];
//	TrepiaService		= [[ESTrepiaService alloc] initWithService:self];
	YahooService		= [[ESYahooService alloc] initWithService:self];
	YahooJapanService	= [[ESYahooJapanService alloc] initWithService:self];
	MeanwhileService	= [[ESMeanwhileService alloc] initWithService:self];
	ZephyrService		= [[ESZephyrService alloc] initWithService:self];
}

- (void)uninstallPlugin
{
	//Services
	[OscarService release]; OscarService = nil;
	[GaduGaduService release]; GaduGaduService = nil;
	[JabberService release]; JabberService = nil;
	[NapsterService release]; NapsterService = nil;
	[MSNService release]; MSNService = nil;
//	[TrepiaService release]; TrepiaService = nil;
	[YahooService release]; YahooService = nil;
	[YahooJapanService release]; YahooJapanService = nil;
	[NovellService release]; NovellService = nil;
	[MeanwhileService release]; MeanwhileService = nil;
	[ZephyrService release]; ZephyrService = nil;
}

@end
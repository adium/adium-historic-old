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

/*
 * Maps GaimAccount*s to CBGaimAccount*s.
 * This is necessary because the gaim people didn't put the same void *ui_data
 * in here that they put in most of their other structures. Maybe we should
 * ask them for one so we can take this out.
 */
NSMutableDictionary *_accountDict;
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
	
	_accountDict = [[NSMutableDictionary alloc] init];
	
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
}

- (void)uninstallPlugin
{
	[_accountDict release]; _accountDict = nil;
    
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
}

#pragma mark AccountDict Methods
// AccountDict ---------------------------------------------------------------------------------------------------------
- (void)addAccount:(id)anAccount forGaimAccountPointer:(GaimAccount *)gaimAcct 
{
 //   [_accountDict setObject:anAccount forKey:[NSValue valueWithPointer:gaimAcct]];
}

- (void)removeAccount:(GaimAccount *)gaimAcct
{
   // [_accountDict removeObjectForKey:[NSValue valueWithPointer:gaimAcct]];
}

- (void)removeAccountWithPointerValue:(NSValue *)inPointer
{
//    [_accountDict removeObjectForKey:inPointer];	
}

@end
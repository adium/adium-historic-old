/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "AIPreferenceController.h"
#import "CBGaimServicePlugin.h"
#import "GaimServices.h"
#import <AIUtilities/AIDictionaryAdditions.h>

@interface CBGaimServicePlugin (PRIVATE)
- (void)_initGaim;
@end

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
	//Register our defaults
    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:GAIM_DEFAULTS forClass:[self class]]
										  forGroup:GROUP_ACCOUNT_STATUS];
	[self _initGaim];
	
    //Install the services
	AIMService			= [[ESAIMService alloc] init];
	AntepoService		= [[ESAntepoService alloc] init];
	ICQService			= [[ESICQService alloc] init];
	DotMacService		= [[ESDotMacService alloc] init];
	GaduGaduService		= [[ESGaduGaduService alloc] init];
	MSNService			= [[ESMSNService alloc] init];
	NovellService		= [[ESNovellService alloc] init];
	JabberService		= [[ESJabberService alloc] init];
	YahooService		= [[ESYahooService alloc] init];
	YahooJapanService	= [[ESYahooJapanService alloc] init];	
	ZephyrService		= [[ESZephyrService alloc] init];

	NapsterService		= nil;//[[ESNapsterService alloc] init];
	
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
	[AntepoService release]; AntepoService = nil;
	[ICQService release]; ICQService = nil;
	[DotMacService release]; DotMacService = nil;
	[GaduGaduService release]; GaduGaduService = nil;
	[JabberService release]; JabberService = nil;
	[MSNService release]; MSNService = nil;
	[YahooService release]; YahooService = nil;
	[YahooJapanService release]; YahooJapanService = nil;
	[NovellService release]; NovellService = nil;
	[ZephyrService release]; ZephyrService = nil;

	[NapsterService release]; NapsterService = nil;

#ifndef TREPIA_NOT_AVAILABLE
	[TrepiaService release]; TrepiaService = nil;
#endif
	
#ifndef MEANWHILE_NOT_AVAILABLE
	[MeanwhileService release]; MeanwhileService = nil;
#endif
}

@end
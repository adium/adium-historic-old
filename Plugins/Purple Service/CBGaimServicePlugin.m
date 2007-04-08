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

#import "CBGaimServicePlugin.h"
#import "GaimServices.h"
#import "SLGaimCocoaAdapter.h"
#import <Adium/AIPreferenceControllerProtocol.h>
#import <Adium/AIAccount.h>
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AdiumLibgaim/SLGaimCocoaAdapter.h>

@implementation CBGaimServicePlugin

#pragma mark Plugin Installation
//  Plugin Installation ------------------------------------------------------------------------------------------------

#define GAIM_DEFAULTS   @"GaimServiceDefaults"

- (void)installPlugin
{
	//Register our defaults
    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:GAIM_DEFAULTS
																		forClass:[self class]]
										  forGroup:GROUP_ACCOUNT_STATUS];
	
    //Install the services
#ifndef JOSCAR_SUPERCEDE_LIBGAIM
	/* Not currently compiled */
	AIMService			= [[ESAIMService alloc] init];
	DotMacService		= [[ESDotMacService alloc] init];
#endif
	ICQService			= [[ESICQService alloc] init];

	GaduGaduService		= [[ESGaduGaduService alloc] init];
	GTalkService		= [[AIGTalkService alloc] init];
	LiveJournalService  = [[AILiveJournalService alloc] init];
	MSNService			= [[ESMSNService alloc] init];
	QQService			= [[ESQQService alloc] init];
	SimpleService		= [[ESSimpleService alloc] init];
	NovellService		= [[ESNovellService alloc] init];
	JabberService		= [[ESJabberService alloc] init];
	YahooService		= [[ESYahooService alloc] init];
	YahooJapanService	= [[ESYahooJapanService alloc] init];	
	ZephyrService		= [[ESZephyrService alloc] init];

#ifndef MEANWHILE_NOT_AVAILABLE
	MeanwhileService	= [[ESMeanwhileService alloc] init];
#endif
	
	[SLGaimCocoaAdapter pluginDidLoad];
}

- (void)uninstallPlugin
{
#ifndef JOSCAR_SUPERCEDE_LIBGAIM
	[AIMService release]; AIMService = nil;
	[DotMacService release]; DotMacService = nil;
#endif
	[ICQService release]; ICQService = nil;

	[GaduGaduService release]; GaduGaduService = nil;
	[GTalkService release]; GTalkService = nil;
	[LiveJournalService release]; LiveJournalService = nil;
	[JabberService release]; JabberService = nil;
	[MSNService release]; MSNService = nil;
	[SimpleService release]; SimpleService = nil;
	[QQService release]; QQService = nil;
	[YahooService release]; YahooService = nil;
	[YahooJapanService release]; YahooJapanService = nil;
	[NovellService release]; NovellService = nil;
	[ZephyrService release]; ZephyrService = nil;

#ifndef MEANWHILE_NOT_AVAILABLE
	[MeanwhileService release]; MeanwhileService = nil;
#endif
}

@end

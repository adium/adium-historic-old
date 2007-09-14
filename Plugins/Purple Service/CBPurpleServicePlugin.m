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

#import "CBPurpleServicePlugin.h"
#import "PurpleServices.h"
#import "SLPurpleCocoaAdapter.h"
#import <Adium/AIPreferenceControllerProtocol.h>
#import <Adium/AIAccount.h>
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AdiumLibpurple/SLPurpleCocoaAdapter.h>
#import "AMPurpleTuneTooltip.h"

@implementation CBPurpleServicePlugin

#pragma mark Plugin Installation
//  Plugin Installation ------------------------------------------------------------------------------------------------

#define PURPLE_DEFAULTS   @"PurpleServiceDefaults"

- (void)installPlugin
{
	//Register our defaults
    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:PURPLE_DEFAULTS
																		forClass:[self class]]
										  forGroup:GROUP_ACCOUNT_STATUS];
	
    //Install the services
	AIMService			= [[ESAIMService alloc] init];
	DotMacService		= [[ESDotMacService alloc] init];
	ICQService			= [[ESICQService alloc] init];
	GaduGaduService		= [[ESGaduGaduService alloc] init];
	GTalkService		= [[AIGTalkService alloc] init];
	LiveJournalService  = [[AILiveJournalService alloc] init];
	MSNService			= [[ESMSNService alloc] init];
	MySpaceService		= [[PurpleMySpaceService alloc] init];
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
	
	[SLPurpleCocoaAdapter pluginDidLoad];
	
	//tooltip for tunes
	tunetooltip = [[AMPurpleTuneTooltip alloc] init];
	[[adium interfaceController] registerContactListTooltipEntry:tunetooltip secondaryEntry:YES];
}

- (void)uninstallPlugin
{
	[AIMService release]; AIMService = nil;
	[DotMacService release]; DotMacService = nil;
	[ICQService release]; ICQService = nil;

	[GaduGaduService release]; GaduGaduService = nil;
	[GTalkService release]; GTalkService = nil;
	[LiveJournalService release]; LiveJournalService = nil;
	[JabberService release]; JabberService = nil;
	[MSNService release]; MSNService = nil;
	[MySpaceService release]; MySpaceService = nil;
	[SimpleService release]; SimpleService = nil;
	[QQService release]; QQService = nil;
	[YahooService release]; YahooService = nil;
	[YahooJapanService release]; YahooJapanService = nil;
	[NovellService release]; NovellService = nil;
	[ZephyrService release]; ZephyrService = nil;

#ifndef MEANWHILE_NOT_AVAILABLE
	[MeanwhileService release]; MeanwhileService = nil;
#endif
	
	[[adium interfaceController] unregisterContactListTooltipEntry:tunetooltip secondaryEntry:YES];
	[tunetooltip release];
	tunetooltip = nil;	
}

@end

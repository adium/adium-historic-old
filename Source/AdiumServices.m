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

#import "AIAccountControllerProtocol.h"
#import "AdiumServices.h"
#import "AIService.h"
#import "AIAccount.h"

@implementation AdiumServices

/*!
 * @brief Init
 */
- (id)init
{
	if ((self = [super init])) {
		services = [[NSMutableDictionary alloc] init];
	}
	
	return self;
}

/*!
 * @brief Dealloc
 */
- (void)dealloc
{
	[services release]; services = nil;
	[super dealloc];
}

/*!
 * @brief Register an AIService instance
 *
 * All services should be registered before they are used
 */
- (void)registerService:(AIService *)inService
{
    [services setObject:inService forKey:[inService serviceCodeUniqueID]];
}

/*!
 * @brief Returns an array of all available services
 *
 * @return NSArray of AIService instances
 */
- (NSArray *)services
{
	return [services allValues];
}

/*!
 * @brief Returns an array of all active services
 *
 * Active services are those for which the user has an enabled account (or enabled compatible account)
 * @return NSArray of AIService instances
 */
- (NSSet *)activeServicesIncludingCompatibleServices:(BOOL)includeCompatible
{
	NSMutableSet	*activeServices = [NSMutableSet set];
	NSEnumerator	*accountEnumerator = [[[adium accountController] accounts] objectEnumerator];
	AIAccount		*account;

	if (includeCompatible) {
		//Scan our user's accounts and build a list of service classes that they cover
		NSMutableSet	*serviceClasses = [NSMutableSet set];
		
		while ((account = [accountEnumerator nextObject])) {
			if ([account enabled]) {
				[serviceClasses addObject:[[account service] serviceClass]];
			}
		}
		
		//Gather and return all services compatible with these service classes
		NSEnumerator	*serviceEnumerator = [services objectEnumerator];
		AIService		*service;
		
		while ((service = [serviceEnumerator nextObject])) {
			if ([serviceClasses containsObject:[service serviceClass]]) {
				[activeServices addObject:service];
			}
		}
		
	} else {
		while ((account = [accountEnumerator nextObject])) {
			if ([account enabled]) {
				[activeServices addObject:[account service]];
			}
		}		
	}

	return activeServices;
}

/*!
 * @brief Retrieves a service by its unique ID
 *
 * @param uniqueID The serviceCodeUniqueID of the desired service
 * @return AIService if found, nil if not found
 */
- (AIService *)serviceWithUniqueID:(NSString *)uniqueID
{
    return [services objectForKey:uniqueID];
}


//XXX - Re-evaluate this method and its presence in the core
- (AIService *)firstServiceWithServiceID:(NSString *)serviceID
{
	NSEnumerator	*enumerator = [services objectEnumerator];
	AIService		*service;
	
	while ((service = [enumerator nextObject])) {
		if ([[service serviceID] isEqualToString:serviceID]) break;
	}
	
	return service;
}

@end

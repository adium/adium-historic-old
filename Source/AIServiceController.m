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

#import "AIAccountController.h"
#import "AIServiceController.h"
#import <Adium/AIService.h>
#import <Adium/AIAccount.h>

@implementation AIServiceController

- (void)initController {
	services = [[NSMutableDictionary alloc] init];
}

- (void)closeController {
	[services release]; services = nil;
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
- (NSArray *)services {
	return([[services allValues] sortedArrayUsingSelector:@selector(compareLongDescription:)]);
}

/*!
 * @brief Returns an array of all active services
 *
 * Active services are those for which the user has an account (or compatible account)
 * @return NSArray of AIService instances
 */
- (NSArray *)activeServices {

	//Scan our user's accounts and build a list of service classes that they cover
	NSMutableArray	*serviceClasses = [NSMutableArray array];
	NSEnumerator	*accountEnumerator = [[[adium accountController] accountArray] objectEnumerator];
	AIAccount		*account;
	
	while((account = [accountEnumerator nextObject])){
		NSString	*serviceClass = [[account service] serviceClass];
		
		if(![serviceClasses containsObject:serviceClass]){
			[serviceClasses addObject:serviceClass];
		}
	}

	//Gather and return all services compatible with these service classes
	NSMutableArray	*activeServices = [NSMutableArray array];
	NSEnumerator	*serviceEnumerator = [services objectEnumerator];
	AIService		*service;

	while((service = [serviceEnumerator nextObject])){
		if([serviceClasses containsObject:[service serviceClass]]){
			[activeServices addObject:service];
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
- (AIService *)serviceWithUniqueID:(NSString *)uniqueID {
    return([services objectForKey:uniqueID]);
}



/*!
 * Update this
 */ 
- (AIService *)firstServiceWithServiceID:(NSString *)serviceID
{
	NSEnumerator	*enumerator = [services objectEnumerator];
	AIService		*service;
	
	while((service = [enumerator nextObject])){
		if([[service serviceID] isEqualToString:serviceID]) break;
	}
	
	return(service);
}

/*!
 * Get rid of this
 */ 
- (BOOL)serviceWithUniqueIDIsOnline:(NSString *)identifier
{
	AIService		*service = [self serviceWithUniqueID:identifier];
    NSEnumerator	*enumerator = [[[adium accountController] accountArray] objectEnumerator];
    AIAccount		*account;
    
    while((account = [enumerator nextObject])){
		if(([account service] == service) &&
		   [account online]) return YES;
    }
    
    return(NO);
}
	

//Return the first service with the specified serviceID

//- (NSArray *)servicesWithServiceClass:(NSString *)serviceClass
//{
//	NSEnumerator	*enumerator = [availableServiceDict objectEnumerator];
//	AIService		*service;
//	NSMutableArray	*servicesArray = [NSMutableArray array];
//	
//	while((service = [enumerator nextObject])){
//		if([[service serviceClass] isEqualToString:serviceClass]) [servicesArray addObject:service];
//	}
//	
//	return(servicesArray);
//}




@end

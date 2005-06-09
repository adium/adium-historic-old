//
//  AIServiceMenu.m
//  Adium
//
//  Created by Adam Iser on 5/19/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "AIServiceMenu.h"
#import "AIAccountController.h"
#import <Adium/AIService.h>
#import <Adium/AIServiceIcons.h>
#import <AIUtilities/AIMenuAdditions.h>

@implementation AIServiceMenu

//Returns a menu of all services.
//- Selector called on service selection is selectAccount:
//- The menu item's represented objects are the service controllers they represent
//- Format allows the description to be placed within a format string. If it is nil, the description alone will be used.
+ (NSMenu *)menuOfServicesWithTarget:(id)target activeServicesOnly:(BOOL)activeServicesOnly
					 longDescription:(BOOL)longDescription format:(NSString *)format
{
	AIServiceImportance	importance;
	unsigned			numberOfItems = 0;
	NSArray				*serviceArray;
	
	//Prepare our menu
	NSMenu *menu = [[NSMenu alloc] init];
	
	serviceArray = (activeServicesOnly ? [[[AIObject sharedAdiumInstance] accountController] activeServices] : [[[AIObject sharedAdiumInstance] accountController] services]);
	
	//Divide our menu into sections.  This helps separate less important services from the others (sorry guys!)
	for (importance = AIServicePrimary; importance <= AIServiceUnsupported; importance++) {
		NSEnumerator	*enumerator;
		AIService		*service;
		unsigned		currentNumberOfItems;
		BOOL			addedDivider = NO;
		
		//Divider
		currentNumberOfItems = [menu numberOfItems];
		if (currentNumberOfItems > numberOfItems) {
			[menu addItem:[NSMenuItem separatorItem]];
			numberOfItems = currentNumberOfItems + 1;
			addedDivider = YES;
		}
		
		//Insert a menu item for each service of this importance
		enumerator = [serviceArray objectEnumerator];
		while ((service = [enumerator nextObject])) {
			if ([service serviceImportance] == importance) {
				NSString	*description = (longDescription ?
											[service longDescription] :
											[service shortDescription]);
				
				NSMenuItem	*menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:(format ? 
																									 [NSString stringWithFormat:format,description] :
																									 description)
																							 target:target 
																							 action:@selector(selectServiceType:) 
																					  keyEquivalent:@""];
				[menuItem setRepresentedObject:service];
				[menuItem setImage:[AIServiceIcons serviceIconForService:service
																	type:AIServiceIconSmall
															   direction:AIIconNormal]];
				[menu addItem:menuItem];
				[menuItem release];
			}
		}
		
		//If we added a divider but didn't add any items, remove it
		currentNumberOfItems = [menu numberOfItems];
		if (addedDivider && (currentNumberOfItems <= numberOfItems) && (currentNumberOfItems > 0)) {
			[menu removeItemAtIndex:(currentNumberOfItems-1)];
		}
	}
	
	return([menu autorelease]);
}	


@end

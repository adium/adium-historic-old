//
//  ESGaimAntepoAccountViewController.m
//  Adium
//
//  Created by Evan Schoenberg on 11/24/04.
//  Copyright 2004-2005 The Adium Team. All rights reserved.
//

#import "ESGaimAntepoAccountViewController.h"

@implementation ESGaimAntepoAccountViewController

//Configure our controls
- (void)configureForAccount:(AIAccount *)inAccount
{
	[super configureForAccount:inAccount];
	
	//Force allowing of plain text passwords over unencrypted streams
	[checkBox_allowPlaintext setState:NSOnState];
	[checkBox_allowPlaintext setEnabled:NO];
}

//Update display for account status change - don't allow the superclass to change the allowPlainText checkbox
//XXX - We're not doing any dynamic disabling/enabling at the moment in account views -ai
//- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
//{
//	NSSet	*returnSet = [super updateListObject:inObject keys:inModifiedKeys silent:silent];
//
//	if(inObject == nil || inObject == account){
//		if(inModifiedKeys == nil || [inModifiedKeys containsObject:@"Online"]){
//			[checkBox_allowPlaintext setEnabled:NO];
//		}
//	}
//	
//	return(returnSet);
//}

@end

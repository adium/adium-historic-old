//
//  ESGaimRequestActionWindowController.m
//  Adium
//
//  Created by Evan Schoenberg on Wed May 05 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "ESGaimRequestActionWindowController.h"
#import "GaimCommon.h"

@implementation ESGaimRequestActionWindowController

+ (void)showActionWindowWithDict:(NSDictionary *)infoDict
{
	int			actionCount = [[infoDict objectForKey:@"Count"] intValue];
	NSArray		*buttonNamesArray = [infoDict objectForKey:@"Button Names"];
	NSString	*titleString = [infoDict objectForKey:@"TitleString"];
	NSString	*msg = [infoDict objectForKey:@"Message"];
	GCallback   *callBacks = [[infoDict objectForKey:@"callBacks"] pointerValue];
	void		*userData = [[infoDict objectForKey:@"userData"] pointerValue];
	
	int		    alertReturn;
	
	switch (actionCount)
	{ 
		case 1:
			alertReturn = NSRunInformationalAlertPanel(titleString,msg,
													   [buttonNamesArray objectAtIndex:0],nil,nil);
			break;
		case 2:
			alertReturn = NSRunInformationalAlertPanel(titleString,msg,
													   [buttonNamesArray objectAtIndex:1],
													   [buttonNamesArray objectAtIndex:0],nil);
			break;
		case 3:
			alertReturn = NSRunInformationalAlertPanel(titleString,msg,
													   [buttonNamesArray objectAtIndex:2],
													   [buttonNamesArray objectAtIndex:1],
													   [buttonNamesArray objectAtIndex:0]);
			break;		    
	}
	
	//Convert the return value to an array index
	alertReturn = (alertReturn + (actionCount - 2));
	
	if (callBacks[alertReturn] != NULL){
		((GaimRequestActionCb)callBacks[alertReturn])(userData, alertReturn);
	}
	
}
@end

//
//  AIListContactBubbleToFitCell.m
//  Adium
//
//  Created by Adam Iser on Wed Aug 04 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "AIListContactBubbleToFitCell.h"


@implementation AIListContactBubbleToFitCell

//Copy
- (id)copyWithZone:(NSZone *)zone
{
	id newCell = [super copyWithZone:zone];
	return(newCell);
}

//Adjust the bubble rect to tightly fit our label string
- (NSRect)bubbleRectForFrame:(NSRect)rect
{
	NSAttributedString	*displayName = [[NSAttributedString alloc] initWithString:[self labelString]
																	   attributes:[self labelAttributes]];
	NSSize				nameSize = [displayName size];
	float				originalWidth = rect.size.width;
	
	//Alignment
	switch([self textAlignment]){
		case NSCenterTextAlignment:
			rect.origin.x += ((rect.size.width - nameSize.width) / 2.0) - [self leftPadding];
			break;
		case NSRightTextAlignment:
			rect.origin.x += (rect.size.width - nameSize.width) - [self leftPadding] - [self rightPadding];
			break;
		default:
			break;
	}
	
	//Fit the bubble to their name
	rect.size.width = nameSize.width + [self leftPadding] + [self rightPadding];
	
	//Handle the icons (only works properly if they are on the same side as the text)
	
	//User icon
	if(userIconVisible){
		float userIconChange;

		userIconChange = userIconSize.width;
		userIconChange += USER_ICON_LEFT_PAD + USER_ICON_RIGHT_PAD;
		
		rect.size.width += userIconChange;
		
		//Shift left to accomodate an icon on the right
		if (userIconPosition == LIST_POSITION_RIGHT){
			rect.origin.x -= userIconChange;
		}
	}
	
	//Status icon
	if(statusIconsVisible &&
	   (statusIconPosition != LIST_POSITION_BADGE_LEFT && statusIconPosition != LIST_POSITION_BADGE_RIGHT)){
		float	statusIconChange;

		statusIconChange = [[self statusImage] size].width;
		statusIconChange += STATUS_ICON_LEFT_PAD + STATUS_ICON_RIGHT_PAD;
		
		rect.size.width += statusIconChange;
		
		//Shift left to accomodate an icon on the right
		if (statusIconPosition == LIST_POSITION_RIGHT || statusIconPosition == LIST_POSITION_FAR_RIGHT){
			rect.origin.x -= statusIconChange;
		}
	}
	
	//Service icon
	if(serviceIconsVisible &&
	   (serviceIconPosition != LIST_POSITION_BADGE_LEFT && serviceIconPosition != LIST_POSITION_BADGE_RIGHT)){
		float serviceIconChange;
		
		serviceIconChange = [[self serviceImage] size].width;
		serviceIconChange += SERVICE_ICON_LEFT_PAD + SERVICE_ICON_RIGHT_PAD;
		
		rect.size.width += serviceIconChange;
		
		//Shift left to accomodate an icon on the right
		if (serviceIconPosition == LIST_POSITION_RIGHT || serviceIconPosition == LIST_POSITION_FAR_RIGHT){
			rect.origin.x -= serviceIconChange;
		}
	}

	//Don't let the bubble try to draw larger than the width we were passed, which was the full width possible
	if (rect.size.width > originalWidth) rect.size.width = originalWidth;
	
	return(rect);
}

@end

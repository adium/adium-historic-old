//
//  AIContactProfilePane.m
//  Adium
//
//  Created by Adam Iser on Sun May 23 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "AIContactProfilePane.h"


@implementation AIContactProfilePane

//Preference pane properties
- (CONTACT_INFO_CATEGORY)contactInfoCategory{
    return(AIInfo_Profile);
}
- (NSString *)label{
    return(@"Profile");
}
- (NSString *)nibName{
    return(@"ContactProfilePane");
}

//Configure the preference view
- (void)viewDidLoad
{
    
}

//Preference view is closing
- (void)viewWillClose
{
    
}

//Configure the pane for a list object
- (void)configureForListObject:(AIListObject *)inObject
{
	NSImage	*userImage;
	
	//User Icon
	if(userImage = [[inObject displayArrayForKey:@"UserIcon"] objectValue]){
		//MUST make a copy, since resizing and flipping the original image here breaks it everywhere else
		userImage = [[userImage copy] autorelease];		
		//Resize to a fixed size for consistency
		[userImage setScalesWhenResized:YES];
		[userImage setSize:NSMakeSize(48,48)];
	}else{
		userImage = [NSImage imageNamed:@"DefaultIcon" forClass:[self class]];
	}
	[imageView_userIcon setImage:userImage];
	
	//Account name
	[textField_accountName setStringValue:[inObject formattedUID]];	
}


@end

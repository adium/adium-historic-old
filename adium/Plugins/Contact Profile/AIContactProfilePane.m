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
    [[adium contactController] registerListObjectObserver:self];
}

//Preference view is closing
- (void)viewWillClose
{
    [[adium contactController] unregisterListObjectObserver:self];
	[listObject release]; listObject = nil;
}

//Configure the pane for a list object
- (void)configureForListObject:(AIListObject *)inObject
{
	//New list object
	[listObject release];
	listObject = [inObject retain];

	//Display what we have now
	[self updatePane];
	
	//Refresh the window's content (Contacts only)
	if([listObject isKindOfClass:[AIListContact class]]){
		[[adium contactController] updateListContactStatus:(AIListContact *)listObject];
	}
}

//Refresh if changes are made to the object we're displaying
- (NSArray *)updateListObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys silent:(BOOL)silent
{
    if(inObject == listObject){
        [self updatePane];
    }
    return(nil);
}

//Update our pane to reflect our contact
- (void)updatePane
{
	NSColor				*backgroundColor = nil;
	NSImage				*userImage;
	NSAttributedString	*infoString;
		
	//User Icon
	if(userImage = [[listObject displayArrayForKey:@"UserIcon"] objectValue]){
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
	[textField_accountName setStringValue:[listObject formattedUID]];	
	
	//Text Profile
	infoString = [listObject statusObjectForKey:@"TextProfile"];
	[[textView_profile textStorage] setAttributedString:infoString];	
	if(infoString && [infoString length]){
		backgroundColor = [infoString attribute:AIBodyColorAttributeName
										atIndex:0 
						  longestEffectiveRange:nil 
										inRange:NSMakeRange(0,[infoString length])];
	}
	[textView_profile setBackgroundColor:(backgroundColor ? backgroundColor : [NSColor whiteColor])];
	
	//Away & Status
	NSAttributedString 	*statusMessage;
	NSMutableString		*status = [NSMutableString string];
	
	if([[listObject numberStatusObjectForKey:@"Away"] boolValue]){
		[status appendString:@"(Away) "];
	}
	
	if(statusMessage = [listObject statusObjectForKey:@"StatusMessage"]){
		[status appendString:[statusMessage string]];
	}
	[textField_status setStringValue:status];	
}

@end

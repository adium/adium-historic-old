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
	NSAttributedString	*infoString;
	
	//Text Profile
	infoString = [[adium contentController] filterAttributedString:[listObject statusObjectForKey:@"TextProfile"]
												   usingFilterType:AIFilterDisplay
														 direction:AIFilterIncoming
														   context:listObject];
	[self setAttributedString:infoString intoTextView:textView_profile];

	//Away & Status
	infoString = [[adium contentController] filterAttributedString:[listObject statusObjectForKey:@"StatusMessage"]
												   usingFilterType:AIFilterDisplay
														 direction:AIFilterIncoming
														   context:listObject];
	[self setAttributedString:infoString intoTextView:textView_status];
}

//
- (void)setAttributedString:(NSAttributedString *)infoString intoTextView:(NSTextView *)textView
{
	NSColor		*backgroundColor = nil;

	if(infoString && [infoString length]){
		[[textView textStorage] setAttributedString:infoString];	
		backgroundColor = [infoString attribute:AIBodyColorAttributeName
										atIndex:0 
						  longestEffectiveRange:nil 
										inRange:NSMakeRange(0,[infoString length])];
	}else{
		[[textView textStorage] setAttributedString:[NSAttributedString stringWithString:@""]];	
	}
	[textView setBackgroundColor:(backgroundColor ? backgroundColor : [NSColor whiteColor])];
    [[NSNotificationCenter defaultCenter] postNotificationName:NSTextDidChangeNotification object:textView];
}


@end

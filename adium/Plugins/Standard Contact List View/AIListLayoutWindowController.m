//
//  AIListLayoutWindowController.m
//  Adium
//
//  Created by Adam Iser on Sun Aug 01 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "AIListLayoutWindowController.h"


@implementation AIListLayoutWindowController

+ (id)listLayoutOnWindow:(NSWindow *)parentWindow
{
	AIListLayoutWindowController	*listLayoutWindow = [[self alloc] initWithWindowNibName:@"ListLayoutSheet"];

	if(parentWindow){
		[NSApp beginSheet:[listLayoutWindow window]
		   modalForWindow:parentWindow
			modalDelegate:listLayoutWindow
		   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
			  contextInfo:nil];
	}else{
		[listLayoutWindow showWindow:nil];
	}
	
	return(listLayoutWindow);
}

- (id)initWithWindowNibName:(NSString *)windowNibName
{
    [super initWithWindowNibName:windowNibName];

	return(self);
}

- (void)dealloc
{
    [super dealloc];
}


//Window Methods -------------------------------------------------------------------------------------------------------
#pragma mark Window Methods
- (void)windowDidLoad
{
	[self configureControls];
}

//Window is closing
- (BOOL)windowShouldClose:(id)sender
{
	[self autorelease];
    return(YES);
}

//Close this window
- (IBAction)closeWindow:(id)sender
{
    if([self windowShouldClose:nil]){
		if([[self window] isSheet]) [NSApp endSheet:[self window]];
        [[self window] close];
    }
}

//Called as the sheet closes, dismisses the sheet
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:nil];
}

//Cancel
- (IBAction)cancel:(id)sender
{
    [self closeWindow:sender];
}


//
- (IBAction)okay:(id)sender
{
    [self closeWindow:sender];
}



//Window Methods -------------------------------------------------------------------------------------------------------
- (void)configureControls
{
	NSDictionary	*prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_LIST_LAYOUT];

	[popUp_contactTextAlignment compatibleSelectItemWithTag:[[prefDict objectForKey:KEY_LIST_LAYOUT_ALIGNMENT] intValue]];
	[popUp_groupTextAlignment compatibleSelectItemWithTag:[[prefDict objectForKey:KEY_LIST_LAYOUT_GROUP_ALIGNMENT] intValue]];
	
}

- (void)preferenceChanged:(id)sender
{
	if(sender == popUp_contactTextAlignment){
		[[adium preferenceController] setPreference:[NSNumber numberWithInt:[[sender selectedItem] tag]]
											 forKey:KEY_LIST_LAYOUT_ALIGNMENT
											  group:PREF_GROUP_LIST_LAYOUT];
	}else if(sender == popUp_groupTextAlignment){
		[[adium preferenceController] setPreference:[NSNumber numberWithInt:[[sender selectedItem] tag]]
											 forKey:KEY_LIST_LAYOUT_GROUP_ALIGNMENT
											  group:PREF_GROUP_LIST_LAYOUT];
	}
	
}


























@end

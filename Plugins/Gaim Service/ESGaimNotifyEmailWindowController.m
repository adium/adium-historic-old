//
//  ESGaimNotifyEmailWindowController.m
//  Adium
//
//  Created by Evan Schoenberg on Fri May 28 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

#import "ESGaimNotifyEmailWindowController.h"

@interface ESGaimNotifyEmailWindowController (PRIVATE)
- (void)showWindowWithMessage:(NSAttributedString *)msg;
@end

#define NOTIFY_EMAIL_WINDOW_NIB @"GaimNotifyEmailWindow"

@implementation ESGaimNotifyEmailWindowController

+ (void)showNotifyEmailWindowWithMessage:(NSAttributedString *)inMessage URL:(NSString *)inURL
{
	ESGaimNotifyEmailWindowController	*notifyWindowController;
	
	notifyWindowController = [[self alloc] initWithWindowNibName:NOTIFY_EMAIL_WINDOW_NIB
													 withMessage:inMessage
															 URL:inURL];
	
	[notifyWindowController showWindow:nil];
}

- (id)initWithWindowNibName:(NSString *)windowNibName withMessage:(NSAttributedString *)inMessage URL:(NSString *)inURL
{	
	urlString = [inURL retain];
	[super initWithWindowNibName:windowNibName];
	[self showWindowWithMessage:inMessage];
	
    return(self);
}

- (void)dealloc
{
	[urlString release];
	[super dealloc];
}

- (void)showWindowWithMessage:(NSAttributedString *)msg
{
	//Ensure the window is loaded
	[self window];
	
	if (!urlString){
		[button_showEmail setFrame:NSMakeRect(0,0,0,0)];
		[button_showEmail setNeedsDisplay:YES];
	}
	
	//Set the message, then change the window size accordingly
	{
		[textView_msg setVerticallyResizable:YES];
		[textView_msg setDrawsBackground:NO];
		[scrollView_msg setDrawsBackground:NO];
		
		NSRect  frame = [[self window] frame];
		int		heightChange;
		
		[[textView_msg textStorage] setAttributedString:msg];
		[textView_msg sizeToFit];
		heightChange = [textView_msg frame].size.height - [scrollView_msg documentVisibleRect].size.height;
		
		frame.size.height += heightChange;
		frame.origin.y -= heightChange;
		
		//Resize the window to fit the message
		[[self window] setFrame:frame display:YES animate:YES];
	}


//XXX - Hook this to the account for listobject
	[[adium contactAlertsController] generateEvent:ACCOUNT_RECEIVED_EMAIL
									 forListObject:nil
										  userInfo:nil
					  previouslyPerformedActionIDs:nil];
}

- (IBAction)pressedButton:(id)sender
{
	if ((sender == button_showEmail) && urlString){
		
		/*
		 The urlString could either be a web address or a path to a local HTML file we are supposed to load.
		 The local HTML file will be in the user's temp directory, which Gaim obtains with g_get_tmp_dir()... 
		 so we will, too.
		 */
		if ([urlString rangeOfString:[NSString stringWithUTF8String:g_get_tmp_dir()]].location != NSNotFound){
			//Local HTML file
			CFURLRef	appURL;
			OSStatus	err;
			
			//Obtain the default http:// handler
			err = LSGetApplicationForURL((CFURLRef)[NSURL URLWithString:@"http://www.google.com"],
										 kLSRolesAll,
										 NULL,
										 &appURL);
			
			//Use it to open the specified file (if we just told NSWorkspace to open it, it might be opened instead
			//by an HTML editor or other program
			[[NSWorkspace sharedWorkspace] openFile:[urlString stringByExpandingTildeInPath]
									withApplication:[(NSURL *)appURL path]];
			
			//LSGetApplicationForURL() requires us to release the appURL when we are done with it
			CFRelease(appURL);
			
		}else{
			NSURL		*emailURL;

			//Web address
			emailURL = [NSURL URLWithString:urlString];
			[[NSWorkspace sharedWorkspace] openURL:emailURL];
		}
	}
	
	[[self window] close];
}

- (BOOL)windowShouldClose:(id)sender
{	
	return YES;
}

@end

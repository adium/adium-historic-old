//
//  ESGaimNotifyEmailWindowController.m
//  Adium
//
//  Created by Evan Schoenberg on Fri May 28 2004.
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
	
	if (!urlString){
		[button_showEmail setFrame:NSMakeRect(0,0,0,0)];
	}
}

- (IBAction)pressedButton:(id)sender
{
	if ((sender == button_showEmail) && urlString){
		
		NSURL   *emailURL;
		
		//The urlString could either be a web address or a path to a local HTML file we are supposed to load.
		//The local HTML file will be in the user's temp directory, which Gaim obtains with g_get_tmp_dir()... so we will, too.
		if ([urlString rangeOfString:[NSString stringWithUTF8String:g_get_tmp_dir()]].location != NSNotFound){
			emailURL = [NSURL fileURLWithPath:[urlString stringByExpandingTildeInPath]];
		}else{
			emailURL = [NSURL URLWithString:urlString];
		}
		
		[[NSWorkspace sharedWorkspace] openURL:emailURL];
	}
	
	[[self window] close];
}

- (BOOL)windowShouldClose:(id)sender
{	
	return YES;
}

@end

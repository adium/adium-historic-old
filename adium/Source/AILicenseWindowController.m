//
//  AILicenseWindowController.m
//  Adium
//
//  Created by Adam Iser on Tue Mar 23 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "AILicenseWindowController.h"

#define LICENSE_WINDOW_NIB	@"LicenseWindow"

@implementation AILicenseWindowController

+ (BOOL)displayLicenseAgreement
{
	AILicenseWindowController *controller = [[[self alloc] initWithWindowNibName:LICENSE_WINDOW_NIB] autorelease];
	[controller showWindow:nil];
	int result = [NSApp runModalForWindow:[controller window]];
	[[controller window] close];
	
	return(result != NSRunAbortedResponse);
}

- (void)windowDidLoad
{
	NSString	*licensePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"License" ofType:@"txt"];
	[textView_license setString:[NSString stringWithContentsOfFile:licensePath]];
	
	[[self window] betterCenter];
}

- (BOOL)shouldCascadeWindows
{
	return(NO);
}

- (IBAction)agree:(id)sender
{
	[NSApp stopModal];
}

- (IBAction)quit:(id)sender
{
	[NSApp abortModal];
}

@end

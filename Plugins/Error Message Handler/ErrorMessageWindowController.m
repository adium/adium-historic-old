/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "ErrorMessageWindowController.h"
#import <AIUtilities/CBApplicationAdditions.h>

#define MAX_ERRORS			80				//The max # of errors to display
#define	ERROR_WINDOW_NIB	@"ErrorWindow"	//Filename of the error window nib

@interface ErrorMessageWindowController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName;
- (void)dealloc;
- (void)refreshErrorDialog;
- (BOOL)shouldCascadeWindows;
- (void)windowDidLoad;
- (BOOL)windowShouldClose:(id)sender;
@end

@implementation ErrorMessageWindowController

/* sharedInstance
*   returns the shared instance of AIErrorController
*/
static ErrorMessageWindowController *sharedErrorMessageInstance = nil;
//static NSDictionary					*boldErrorTitleAttributes = nil;

+ (id)errorMessageWindowController
{
    if(!sharedErrorMessageInstance){
        sharedErrorMessageInstance = [[self alloc] initWithWindowNibName:ERROR_WINDOW_NIB];
    }

    return(sharedErrorMessageInstance);
}

+ (void)closeSharedInstance
{
    if(sharedErrorMessageInstance){
        [sharedErrorMessageInstance closeWindow:nil];
    }
}

- (void)displayError:(NSString *)inTitle withDescription:(NSString *)inDesc withTitle:(NSString *)inWindowTitle;
{
	if(inTitle && inDesc && inWindowTitle){
		//force the window to load
		[sharedErrorMessageInstance window];
		
		//add the error
		if([errorTitleArray count] < MAX_ERRORS){ //Stop logging errors after too many
			[errorTitleArray addObject:inTitle];
			[errorDescArray addObject:inDesc];
			[errorWindowTitleArray addObject:inWindowTitle];
		}
		
		[self refreshErrorDialog];
	}
}

- (IBAction)okay:(id)sender
{
    if([errorTitleArray count] == 1){ //close the error dialog
        [self closeWindow:nil];

    }else{ //remove the first error and display the next one
        [errorTitleArray removeObjectAtIndex:0];
        [errorDescArray removeObjectAtIndex:0];
        [errorWindowTitleArray removeObjectAtIndex:0];

        [self refreshErrorDialog];
    }
}

- (IBAction)okayToAll:(id)sender
{
    //close the error dialog
    [self closeWindow:nil];
}


// Private --------------------------------------------------------------------------------
#pragma mark Private
- (id)initWithWindowNibName:(NSString *)windowNibName
{
    //init
    [super initWithWindowNibName:windowNibName];

	/*
	if(!boldErrorTitleAttributes){
		boldErrorTitleAttributes = [[NSDictionary dictionaryWithObject:[[NSFontManager defaultManager] convertFont:[NSFont systemFontOfSize:0] 
																									   toHaveTrait:NSBoldFontMask]
																forKey:NSFontAttributeName] retain];
	}
	*/
	
    errorTitleArray = [[NSMutableArray alloc] init];
    errorDescArray =  [[NSMutableArray alloc] init];
    errorWindowTitleArray = [[NSMutableArray alloc] init];

    return(self);
}

- (void)dealloc
{
    [errorTitleArray release]; errorTitleArray = nil;
    [errorDescArray release]; errorDescArray = nil;
    [errorWindowTitleArray release]; errorWindowTitleArray = nil;

    [super dealloc];
}

- (void)refreshErrorDialog
{
    NSRect	frame = [[self window] frame];
    int		heightChange;

    //Display the current error title
	NSString	*title = [errorTitleArray objectAtIndex:0];
    [textView_errorTitle setString:title];

	//Resize the window frame to fit the error title
	[textView_errorTitle sizeToFit];
	heightChange = [textView_errorTitle frame].size.height - [scrollView_errorTitle documentVisibleRect].size.height;
	frame.size.height += heightChange;
	frame.origin.y -= heightChange;

	//Display the message
	[textView_errorInfo setString:[errorDescArray objectAtIndex:0]];

	//Resize the window frame to fit the error message
	[textView_errorInfo sizeToFit];
	heightChange = [textView_errorInfo frame].size.height - [scrollView_errorInfo documentVisibleRect].size.height;
	frame.size.height += heightChange;
    frame.origin.y -= heightChange;
	
	//Perform the window resizing as needed
	if ([NSApp isOnPantherOrBetter]){
		[[self window] setFrame:frame display:YES animate:YES];
	}else{
		[[self window] setFrame:frame display:YES]; //animate:YES can crash in 10.2
	}

    //Display the current error count
    if([errorTitleArray count] == 1){
        [tabView_multipleErrors selectTabViewItemAtIndex:0]; //hide the 'okay all' button and error count
        [[self window] setTitle:[errorWindowTitleArray objectAtIndex:0]];
        [button_okay setTitle:@"OK"];

    }else{
        [tabView_multipleErrors selectTabViewItemAtIndex:1]; //show the 'okay all' button and error count
        [[self window] setTitle:[NSString stringWithFormat:@"%@ (x%i)",[errorWindowTitleArray objectAtIndex:0],[errorTitleArray count]]];
        [button_okay setTitle:@"Next"];

    }

    [[self window] makeKeyAndOrderFront:nil];
}

// prevents the system from moving our window around
- (BOOL)shouldCascadeWindows
{
    return(NO);
}

// called after the about window loads, so we can set up the window before it's displayed
- (void)windowDidLoad
{
    //Setup the textviews
    [textView_errorTitle setHorizontallyResizable:NO];
    [textView_errorTitle setVerticallyResizable:YES];
    [textView_errorTitle setDrawsBackground:NO];
    [scrollView_errorTitle setDrawsBackground:NO];
	
    [textView_errorInfo setHorizontallyResizable:NO];
    [textView_errorInfo setVerticallyResizable:YES];
    [textView_errorInfo setDrawsBackground:NO];
    [scrollView_errorInfo setDrawsBackground:NO];
}

// called as the window closes
- (BOOL)windowShouldClose:(id)sender
{    
    //release the window controller (ourself)
    sharedErrorMessageInstance = nil;
    [self autorelease];

    return(YES);
}

@end

/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2003, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
 | This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 | General Public License as published by the Free Software Foundation; either version 2 of the License,
 | or (at your option) any later version.
 |
 | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 | Public License for more details.
 |
 | You should have received a copy of the GNU General Public License along with this program; if not,
 | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 \------------------------------------------------------------------------------------------------------ */

#import "ErrorMessageWindowController.h"

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

// closes this window
- (IBAction)closeWindow:(id)sender
{
    if([self windowShouldClose:nil]){
        [[self window] close];
    }
}



// Private --------------------------------------------------------------------------------
#pragma mark Private
- (id)initWithWindowNibName:(NSString *)windowNibName
{
    //init
    [super initWithWindowNibName:windowNibName];

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
    
    //Display the current error message
    [textField_errorTitle setStringValue:[errorTitleArray objectAtIndex:0]];
    [textView_errorInfo setString:[errorDescArray objectAtIndex:0]];

    //Resize the window to fit the error message
    [textView_errorInfo sizeToFit];
    heightChange = [textView_errorInfo frame].size.height - [scrollView_errorInfo documentVisibleRect].size.height;

    frame.size.height += heightChange;
    frame.origin.y -= heightChange;
    [[self window] setFrame:frame display:YES animate:YES];

    
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
    //Setup the textview
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

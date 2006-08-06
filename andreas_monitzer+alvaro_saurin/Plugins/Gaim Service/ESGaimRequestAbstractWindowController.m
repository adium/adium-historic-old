//
//  ESGaimRequestAbstractWindowController.m
//  Adium
//
//  Created by Evan Schoenberg on 9/22/05.
//

#import "ESGaimRequestAbstractWindowController.h"
#import "adiumGaimRequest.h"

@implementation ESGaimRequestAbstractWindowController

- (id)initWithWindowNibName:(NSString *)windowNibName
{
	if ((self = [super initWithWindowNibName:windowNibName])) {
		windowIsClosing = NO;
	}
	
	return self;
}

/*
 * @brief This is where subclasses should generally perform actions they would normally do in windowWillClose:
 *
 * ESGaimRequestAbstractWindowController calls this method only when windowWillClose: is triggered by user action
 * as opposed to libgaim closing the window.
 */
- (void)doWindowWillClose {};

- (void)windowWillClose:(id)sender
{
	[super windowWillClose:sender];
	
	if (!windowIsClosing) {
		windowIsClosing = YES;
		[self doWindowWillClose];
		
		//Inform libgaim that the request window closed
		[ESGaimRequestAdapter requestCloseWithHandle:self];
	}
}	

/*
 * @brief libgaim has been made aware we closed or has informed us we should close
 *
 * Close our requestController's window if it's open; then release (we returned without autoreleasing initially).
 */
- (void)gaimRequestClose
{
	if (!windowIsClosing) {
		windowIsClosing = YES;
		[self closeWindow:nil];
	}
	
	[self release];
}

@end

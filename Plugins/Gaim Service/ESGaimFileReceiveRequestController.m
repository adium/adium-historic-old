//
//  ESGaimFileReceiveRequestController.m
//  Adium
//
//  Created by Evan Schoenberg on 9/22/05.
//

#import "ESGaimFileReceiveRequestController.h"
#import "adiumGaimRequest.h"
#import "CBGaimAccount.h"
#import <Adium/ESFileTransfer.h>

@interface ESGaimFileReceiveRequestController (PRIVATE)
- (id)initWithDict:(NSDictionary *)inDict;
@end

@implementation ESGaimFileReceiveRequestController

+ (ESGaimFileReceiveRequestController *)showFileReceiveWindowWithDict:(NSDictionary *)inDict
{
	return [[self alloc] initWithDict:inDict];
}

- (id)initWithDict:(NSDictionary *)inDict
{
	if ((self = [super init])) {
		CBGaimAccount		*account = [inDict objectForKey:@"CBGaimAccount"];
		ESFileTransfer		*fileTransfer = [inDict objectForKey:@"ESFileTransfer"];
		
		requestController = [[account requestReceiveOfFileTransfer:fileTransfer] retain];
		if (requestController) {
			NSWindow	*window = [requestController window];
			
			//Watch for the window to close
			[[NSNotificationCenter defaultCenter] addObserver:self
													 selector:@selector(windowWillClose:)
														 name:NSWindowWillCloseNotification
													   object:window];
			
		} else {
			//Didn't get a request control; no need for us here anymore.
			[self release];
			self = nil;
		}
	}
	
	return self;
}

- (void)dealloc
{
	[requestController release]; requestController = nil;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[super dealloc];
}

/*
 * @brief libgaim has been made aware we closed or has informed us we should close
 *
 * Close our requestController's window if it's open; then release (we returned without autoreleasing initially).
 */
- (void)gaimRequestClose
{
	AILog(@"%@: gaimRequestClose (%@)",self,requestController);

	if (requestController) {
		[[requestController window] close];
	}
	
	[self release];
}

/*
 * @brief Our requestController's window is closing
 */
- (void)windowWillClose:(NSNotification *)inNotification
{
	//We won't need to try to close it ourselves later
	[requestController release]; requestController = nil;

	//Inform libgaim that the request window closed
	[ESGaimRequestAdapter requestCloseWithHandle:self];
}

@end

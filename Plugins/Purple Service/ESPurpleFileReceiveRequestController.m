//
//  ESPurpleFileReceiveRequestController.m
//  Adium
//
//  Created by Evan Schoenberg on 9/22/05.
//

#import "ESPurpleFileReceiveRequestController.h"
#import "adiumPurpleRequest.h"
#import "CBPurpleAccount.h"
#import <Adium/AIWindowController.h>
#import <Adium/ESFileTransfer.h>

@interface ESPurpleFileReceiveRequestController (PRIVATE)
- (id)initWithDict:(NSDictionary *)inDict;
@end

@implementation ESPurpleFileReceiveRequestController

+ (ESPurpleFileReceiveRequestController *)showFileReceiveWindowWithDict:(NSDictionary *)inDict
{
	return [[self alloc] initWithDict:inDict];
}

- (id)initWithDict:(NSDictionary *)inDict
{
	if ((self = [super init])) {
		CBPurpleAccount		*account = [inDict objectForKey:@"CBPurpleAccount"];
		ESFileTransfer		*fileTransfer = [inDict objectForKey:@"ESFileTransfer"];
		
		[account requestReceiveOfFileTransfer:fileTransfer];

		[[[AIObject sharedAdiumInstance] notificationCenter] addObserver:self
																selector:@selector(cancel:)
																	name:FILE_TRANSFER_CANCELLED
																  object:nil];

	}
	
	return self;
}

- (void)dealloc
{
	[[[AIObject sharedAdiumInstance] notificationCenter] removeObserver:self];
	
	[super dealloc];
}

/*!
 * @brief libgaim has been made aware we closed or has informed us we should close
 *
 * release (we returned without autoreleasing initially).
 */
- (void)gaimRequestClose
{	
	[self release];
}

/*!
 * @brief Our file transfer was cancelled
 */
- (void)cancel:(NSNotification *)inNotification
{
	//Inform libgaim that the request was cancelled
	[ESPurpleRequestAdapter requestCloseWithHandle:self];
}

@end

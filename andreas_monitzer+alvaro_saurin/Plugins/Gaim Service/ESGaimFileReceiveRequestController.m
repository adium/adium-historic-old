//
//  ESGaimFileReceiveRequestController.m
//  Adium
//
//  Created by Evan Schoenberg on 9/22/05.
//

#import "ESGaimFileReceiveRequestController.h"
#import "adiumGaimRequest.h"
#import "CBGaimAccount.h"
#import <Adium/AIWindowController.h>
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

/*
 * @brief libgaim has been made aware we closed or has informed us we should close
 *
 * release (we returned without autoreleasing initially).
 */
- (void)gaimRequestClose
{	
	[self release];
}

/*
 * @brief Our file transfer was cancelled
 */
- (void)cancel:(NSNotification *)inNotification
{
	//Inform libgaim that the request was cancelled
	[ESGaimRequestAdapter requestCloseWithHandle:self];
}

@end

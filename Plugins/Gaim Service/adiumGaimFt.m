//
//  adiumGaimFt.m
//  Adium
//
//  Created by Evan Schoenberg on 1/22/05.
//  Copyright 2005 The Adium Team. All rights reserved.
//

#import "adiumGaimFt.h"


static void adiumGaimNewXfer(GaimXfer *xfer)
{
	
}

static void adiumGaimDestroy(GaimXfer *xfer)
{
	ESFileTransfer *fileTransfer = (ESFileTransfer *)xfer->ui_data;
	[accountLookup(xfer->account) mainPerformSelector:@selector(destroyFileTransfer:)
										   withObject:fileTransfer];
	
	xfer->ui_data = nil;
}

static void adiumGaimAddXfer(GaimXfer *xfer)
{
	
}

static void adiumGaimUpdateProgress(GaimXfer *xfer, double percent)
{
	//	GaimDebug (@"Transfer update: %s is now %f%% done",(xfer->filename ? xfer->filename : ""),(percent*100));
	
	ESFileTransfer *fileTransfer = (ESFileTransfer *)xfer->ui_data;
	
	if (fileTransfer){
		[accountLookup(xfer->account) mainPerformSelector:@selector(updateProgressForFileTransfer:percent:bytesSent:)
											   withObject:fileTransfer
											   withObject:[NSNumber numberWithFloat:percent]
											   withObject:[NSNumber numberWithUnsignedLong:xfer->bytes_sent]];
	}
}

static void adiumGaimCancelLocal(GaimXfer *xfer)
{
	GaimDebug (@"adiumGaimCancelLocal");
	ESFileTransfer *fileTransfer = (ESFileTransfer *)xfer->ui_data;
    [accountLookup(xfer->account) mainPerformSelector:@selector(fileTransferCanceledLocally:)
										   withObject:fileTransfer];	
}

static void adiumGaimCancelRemote(GaimXfer *xfer)
{
	GaimDebug (@"adiumGaimCancelRemote");
	ESFileTransfer *fileTransfer = (ESFileTransfer *)xfer->ui_data;
    [accountLookup(xfer->account) mainPerformSelector:@selector(fileTransferCanceledRemotely:)
										   withObject:fileTransfer];
}

static GaimXferUiOps adiumGaimFileTransferOps = {
    adiumGaimNewXfer,
    adiumGaimDestroy,
    adiumGaimAddXfer,
    adiumGaimUpdateProgress,
    adiumGaimCancelLocal,
    adiumGaimCancelRemote
};

GaimXferUiOps *adium_gaim_xfers_get_ui_ops()
{
	return &adiumGaimFileTransferOps;
}

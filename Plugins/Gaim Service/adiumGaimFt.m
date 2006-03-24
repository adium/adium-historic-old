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

#import "adiumGaimFt.h"
#import <AIUtilities/AIObjectAdditions.h>

static void adiumGaimNewXfer(GaimXfer *xfer)
{
	
}

static void adiumGaimDestroy(GaimXfer *xfer)
{
	ESFileTransfer *fileTransfer = (ESFileTransfer *)xfer->ui_data;
	[accountLookup(xfer->account) destroyFileTransfer:fileTransfer];
	
	xfer->ui_data = nil;
}

static void adiumGaimAddXfer(GaimXfer *xfer)
{
	
}

static void adiumGaimUpdateProgress(GaimXfer *xfer, double percent)
{	
	ESFileTransfer *fileTransfer = (ESFileTransfer *)xfer->ui_data;
	
	if (fileTransfer) {
		[accountLookup(xfer->account) updateProgressForFileTransfer:fileTransfer
															percent:[NSNumber numberWithFloat:percent]
														  bytesSent:[NSNumber numberWithUnsignedLong:xfer->bytes_sent]];
	}
}

static void adiumGaimCancelLocal(GaimXfer *xfer)
{
	GaimDebug (@"adiumGaimCancelLocal");
	ESFileTransfer *fileTransfer = (ESFileTransfer *)xfer->ui_data;
    [accountLookup(xfer->account) fileTransferCanceledLocally:fileTransfer];
}

static void adiumGaimCancelRemote(GaimXfer *xfer)
{
	GaimDebug (@"adiumGaimCancelRemote");
	ESFileTransfer *fileTransfer = (ESFileTransfer *)xfer->ui_data;
    [accountLookup(xfer->account) fileTransferCanceledRemotely:fileTransfer];
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

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

#import "adiumGaimEventloop.h"
#import <AIUtilities/AIApplicationAdditions.h>

static guint				sourceId = nil;		//The next source key; continuously incrementing
static NSMutableDictionary	*sourceInfoDict = nil;
static CFRunLoopRef			gaimRunLoop = nil;

static void socketCallback(CFSocketRef s,
                           CFSocketCallBackType callbackType,
                           CFDataRef address,
                           const void *data,
                           void *infoVoid);
/*
 * The sources, keyed by integer key id (wrapped in an NSValue), holding
 * struct sourceInfo* values (wrapped in an NSValue).
 */

// The structure of values of sourceInfoDict
struct SourceInfo {
    guint tag;
    CFRunLoopTimerRef timer;
    CFSocketRef socket;
    CFRunLoopSourceRef rls;
    union {
        GSourceFunc sourceFunction;
        GaimInputFunction ioFunction;
    };
    int fd;
    gpointer user_data;
};

#pragma mark Remove

guint adium_source_remove(guint tag) {
    struct SourceInfo *sourceInfo = (struct SourceInfo*)
	[[sourceInfoDict objectForKey:[NSNumber numberWithUnsignedInt:tag]] pointerValue];
	
	//	GaimDebug (@"***SOURCE REMOVE : %i",tag);
    if (sourceInfo) {
		if (sourceInfo->timer != NULL) { 
			//Got a timer; invalidate and release
			CFRunLoopTimerInvalidate(sourceInfo->timer);
			CFRelease(sourceInfo->timer);
			
		} else if (sourceInfo->rls != NULL) {
			//Got a file handle; invalidate and release the source and the socket
			CFRunLoopSourceInvalidate(sourceInfo->rls);
			CFRelease(sourceInfo->rls);
			CFSocketInvalidate(sourceInfo->socket);
			CFRelease(sourceInfo->socket);
		}
		
		[sourceInfoDict removeObjectForKey:[NSNumber numberWithUnsignedInt:tag]];
		free(sourceInfo);
		
		return TRUE;
	}
	
	return FALSE;
}

//Like g_source_remove, return TRUE if successful, FALSE if not
guint adium_timeout_remove(guint tag) {
    return (adium_source_remove(tag));
}

#pragma mark Add

void callTimerFunc(CFRunLoopTimerRef timer, void *info)
{
	struct SourceInfo *sourceInfo = info;
	
	//	GaimDebug (@"%x: Fired %f-ms timer (tag %u)",[NSRunLoop currentRunLoop],CFRunLoopTimerGetInterval(timer)*1000,sourceInfo->tag);
	if (!sourceInfo->sourceFunction ||
		!sourceInfo->sourceFunction(sourceInfo->user_data)) {
        adium_source_remove(sourceInfo->tag);
	}
}

guint adium_timeout_add(guint interval, GSourceFunc function, gpointer data)
{
	//    GaimDebug (@"%x: New %u-ms timer (tag %u)",[NSRunLoop currentRunLoop], interval, sourceId);
	
    struct SourceInfo *info = (struct SourceInfo*)malloc(sizeof(struct SourceInfo));
	
	sourceId++;
	NSTimeInterval intervalInSec = (NSTimeInterval)interval/1000;
	CFRunLoopTimerContext runLoopTimerContext = { 0, info, NULL, NULL, NULL };
	CFRunLoopTimerRef runLoopTimer = CFRunLoopTimerCreate(kCFAllocatorDefault, /* default allocator */
		(CFAbsoluteTimeGetCurrent() + intervalInSec), /* The time at which the timer should first fire */
		intervalInSec, /* firing interval */
		0, /* flags, currently ignored */
		0, /* order, currently ignored */
		callTimerFunc, /* CFRunLoopTimerCallBack callout */
		&runLoopTimerContext /* context */
		);

	info->sourceFunction = function;
	info->timer = runLoopTimer;
	info->socket = NULL;
	info->rls = NULL;
	info->user_data = data;

	CFRunLoopAddTimer(gaimRunLoop, runLoopTimer, kCFRunLoopCommonModes);

	NSNumber	*key = [NSNumber numberWithUnsignedInt:sourceId];
	//Make sure we end up with a valid source id
	while ([sourceInfoDict objectForKey:key]) {
		sourceId++;
		key = [NSNumber numberWithUnsignedInt:sourceId];
	}
	info->tag = sourceId;

	[sourceInfoDict setObject:[NSValue valueWithPointer:info]
					   forKey:key];

	return sourceId;
}

guint adium_input_add(int fd, GaimInputCondition condition,
					  GaimInputFunction func, gpointer user_data)
{
    struct SourceInfo *info = (struct SourceInfo*)malloc(sizeof(struct SourceInfo));
	
    // Build the CFSocket-style callback flags to use from the gaim ones
    CFOptionFlags callBackTypes = 0;
    if ((condition & GAIM_INPUT_READ ) != 0) callBackTypes |= kCFSocketReadCallBack;
    if ((condition & GAIM_INPUT_WRITE) != 0) callBackTypes |= kCFSocketWriteCallBack;	
	//	if ((condition & GAIM_INPUT_CONNECT) != 0) callBackTypes |= kCFSocketConnectCallBack;
	
    // And likewise the entire CFSocket
    CFSocketContext context = { 0, info, NULL, NULL, NULL };
    CFSocketRef socket = CFSocketCreateWithNative(NULL, fd, callBackTypes, socketCallback, &context);
    NSCAssert(socket != NULL, @"CFSocket creation failed");
    info->socket = socket;
	
    // Re-enable callbacks automatically and _don't_ close the socket on
    // invalidate
	CFSocketSetSocketFlags(socket, kCFSocketAutomaticallyReenableReadCallBack | 
						   kCFSocketAutomaticallyReenableDataCallBack |
						   kCFSocketAutomaticallyReenableWriteCallBack);
	
    // Add it to our run loop
    CFRunLoopSourceRef rls = CFSocketCreateRunLoopSource(NULL, socket, 0);
	
	if (rls) {
		CFRunLoopAddSource(gaimRunLoop, rls, kCFRunLoopCommonModes);
	}

	sourceId++;

	//	GaimDebug (@"Adding for %i",sourceId);

	info->rls = rls;
	info->timer = NULL;
    info->tag = sourceId;
    info->ioFunction = func;
    info->user_data = user_data;
    info->fd = fd;
    NSCAssert1([sourceInfoDict objectForKey:[NSNumber numberWithUnsignedInt:sourceId]] == nil, @"Key %u in use", sourceId);
    [sourceInfoDict setObject:[NSValue valueWithPointer:info]
					   forKey:[NSNumber numberWithUnsignedInt:sourceId]];
	
    return sourceId;
}

guint adium_context_iteration(void *context, guint may_block)
{
	return [[NSRunLoop currentRunLoop] runMode:(NSString *)kCFRunLoopCommonModes 
									beforeDate:(may_block ? [NSDate distantFuture] : [NSDate dateWithTimeIntervalSinceNow:1])];
}

#pragma mark Socket Callback
static void socketCallback(CFSocketRef s,
						   CFSocketCallBackType callbackType,
						   CFDataRef address,
						   const void *data,
						   void *infoVoid)
{
    struct SourceInfo *sourceInfo = (struct SourceInfo*) infoVoid;
	
    GaimInputCondition c = 0;
    if ((callbackType & kCFSocketReadCallBack) != 0)  c |= GAIM_INPUT_READ;
    if ((callbackType & kCFSocketWriteCallBack) != 0) c |= GAIM_INPUT_WRITE;
	//	if ((callbackType & kCFSocketConnectCallBack) != 0) c |= GAIM_INPUT_CONNECT;
	
	//	GaimDebug (@"***SOCKETCALLBACK : %i (%i)",info->fd,c);
	
	if ((callbackType & kCFSocketConnectCallBack) != 0) {
		//Got a file handle; invalidate and release the source and the socket
		CFRunLoopSourceInvalidate(sourceInfo->rls);
		CFRelease(sourceInfo->rls);
		CFSocketInvalidate(sourceInfo->socket);
		CFRelease(sourceInfo->socket);
		
		[sourceInfoDict removeObjectForKey:[NSNumber numberWithUnsignedInt:sourceInfo->tag]];
		sourceInfo->ioFunction(sourceInfo->user_data, sourceInfo->fd, c);
		free(sourceInfo);
		
	} else {
		//		GaimDebug (@"%x: Socket callback: %i",[NSRunLoop currentRunLoop],sourceInfo->tag);
		sourceInfo->ioFunction(sourceInfo->user_data, sourceInfo->fd, c);
	}	
}


static GaimEventLoopUiOps adiumEventLoopUiOps = {
    adium_timeout_add,
    adium_timeout_remove,
    adium_input_add,
    adium_source_remove,
	adium_context_iteration
};

GaimEventLoopUiOps *adium_gaim_eventloop_get_ui_ops(void)
{
	if (!sourceInfoDict) sourceInfoDict = [[NSMutableDictionary alloc] init];

	//Determine our run loop
	gaimRunLoop = CFRunLoopGetCurrent();
	CFRetain(gaimRunLoop);
	
	return &adiumEventLoopUiOps;
}

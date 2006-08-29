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

static guint				sourceId = 0;		//The next source key; continuously incrementing
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
    guint timer_tag;
    guint read_tag;
    guint write_tag;

    CFRunLoopTimerRef timer;
    CFSocketRef socket;

	GSourceFunc sourceFunction;
	GaimInputFunction read_ioFunction;
	GaimInputFunction write_ioFunction;

    int fd;

	gpointer timer_user_data;
    gpointer read_user_data;
    gpointer write_user_data;
};

struct SourceInfo *newSourceInfo(void)
{
	struct SourceInfo *info = (struct SourceInfo*)malloc(sizeof(struct SourceInfo));

	info->timer_tag = 0;
	info->read_tag = 0;
	info->write_tag = 0;

	info->timer = NULL;
	info->socket = NULL;

	info->sourceFunction = NULL;
	info->read_ioFunction = NULL;
	info->write_ioFunction = NULL;

	info->fd = 0;

	info->timer_user_data = NULL;
	info->read_user_data = NULL;
	info->write_user_data = NULL;
	
	return info;
}

#pragma mark Remove

guint adium_source_remove(guint tag) {
    struct SourceInfo *sourceInfo = (struct SourceInfo*)
	[[sourceInfoDict objectForKey:[NSNumber numberWithUnsignedInt:tag]] pointerValue];
	
    if (sourceInfo) {
		if (sourceInfo->timer_tag == tag) {
			sourceInfo->timer_tag = 0;

		} else if (sourceInfo->read_tag == tag) {
			sourceInfo->read_tag = 0;

		} else if (sourceInfo->write_tag == tag) {
			sourceInfo->write_tag = 0;

		}
		
		[sourceInfoDict removeObjectForKey:[NSNumber numberWithUnsignedInt:tag]];
		
		if (sourceInfo->timer_tag == 0 && sourceInfo->read_tag == 0 && sourceInfo->write_tag == 0) {
			//It's done
			if (sourceInfo->timer) { 
				CFRunLoopTimerInvalidate(sourceInfo->timer);
				CFRelease(sourceInfo->timer);
			}
			
			if (sourceInfo->socket) {
				CFSocketInvalidate(sourceInfo->socket);
				CFRelease(sourceInfo->socket);
			}
			
			free(sourceInfo);
		} else {
			if ((sourceInfo->timer_tag == 0) && (sourceInfo->timer)) {
				CFRunLoopTimerInvalidate(sourceInfo->timer);
				CFRelease(sourceInfo->timer);
				sourceInfo->timer = NULL;
			}
			
			//Disable the callback on the socket which is no longer active
			if ((sourceInfo->read_tag == 0) && (sourceInfo->socket)) {
				CFSocketDisableCallBacks(sourceInfo->socket, kCFSocketReadCallBack);
			}

			if ((sourceInfo->write_tag == 0) && (sourceInfo->socket)) {
				CFSocketDisableCallBacks(sourceInfo->socket, kCFSocketWriteCallBack);
			}
		}

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

	if (!sourceInfo->sourceFunction ||
		!sourceInfo->sourceFunction(sourceInfo->timer_user_data)) {
        adium_source_remove(sourceInfo->timer_tag);
	}
}

guint adium_timeout_add(guint interval, GSourceFunc function, gpointer data)
{
    struct SourceInfo *info = newSourceInfo();
	
	NSTimeInterval intervalInSec = (NSTimeInterval)interval/1000;
	CFRunLoopTimerContext runLoopTimerContext = { 0, info, NULL, NULL, NULL };
	CFRunLoopTimerRef runLoopTimer = CFRunLoopTimerCreate(
														  kCFAllocatorDefault, /* default allocator */
														  (CFAbsoluteTimeGetCurrent() + intervalInSec), /* The time at which the timer should first fire */
														  intervalInSec, /* firing interval */
														  0, /* flags, currently ignored */
														  0, /* order, currently ignored */
														  callTimerFunc, /* CFRunLoopTimerCallBack callout */
														  &runLoopTimerContext /* context */
														  );
	CFRunLoopAddTimer(gaimRunLoop, runLoopTimer, kCFRunLoopCommonModes);
	
	info->sourceFunction = function;
	info->timer = runLoopTimer;
	info->timer_user_data = data;	
	info->timer_tag = ++sourceId;

	[sourceInfoDict setObject:[NSValue valueWithPointer:info]
					   forKey:[NSNumber numberWithUnsignedInt:info->timer_tag]];

	return info->timer_tag;
}

guint adium_input_add(int fd, GaimInputCondition condition,
					  GaimInputFunction func, gpointer user_data)
{	
	if (fd < 0) {
		NSLog(@"fd was %i; returning %i",fd,sourceId+1);
		return ++sourceId;
	}

    struct SourceInfo *info = newSourceInfo();
	
    // And likewise the entire CFSocket
    CFSocketContext context = { 0, info, /* CFAllocatorRetainCallBack */ NULL, /* CFAllocatorReleaseCallBack */ NULL, /* CFAllocatorCopyDescriptionCallBack */ NULL };	

    // Build the CFSocket callback flags to use from the libgaim ones
    CFOptionFlags callBackTypes = 0;
    if ((condition & GAIM_INPUT_READ)) callBackTypes |= kCFSocketReadCallBack;
    if ((condition & GAIM_INPUT_WRITE)) callBackTypes |= kCFSocketWriteCallBack;	

	/*
	 * From CFSocketCreateWithNative:
	 * If a socket already exists on this fd, CFSocketCreateWithNative() will return that existing socket, and the other parameters
	 * will be ignored.
	 */
    CFSocketRef socket = CFSocketCreateWithNative(kCFAllocatorDefault,
												  fd,
												  callBackTypes,
												  socketCallback,
												  &context);
	NSCAssert(socket != NULL, @"CFSocket creation failed");

	/*
	 * If an existing socket was returned by CFSocketCreateWithNative(), its context will not have been changed to match the context
	 * we made above.  We should then invalidate and release that socket and its information, then create a new one.
	 */
	CFSocketContext actualSocketContext;
	CFSocketGetContext(socket, &actualSocketContext);
	if (actualSocketContext.info != info) {
		free(info);
		context.info = actualSocketContext.info;
		info = context.info;

		CFSocketInvalidate(socket);
		CFRelease(socket);
		
		if (info->read_tag) {
			callBackTypes |= kCFSocketReadCallBack;
		}
		if (info->write_tag) {
			callBackTypes |= kCFSocketWriteCallBack;			
		}

		socket = CFSocketCreateWithNative(kCFAllocatorDefault,
										  fd,
										  callBackTypes,
										  socketCallback,
										  &context);
	}
		
	//Re-enable callbacks automatically and _don't_ close the socket on invalidate
	CFSocketSetSocketFlags(socket, (kCFSocketAutomaticallyReenableReadCallBack | 
									kCFSocketAutomaticallyReenableDataCallBack |
									kCFSocketAutomaticallyReenableWriteCallBack));

	//Add it to our run loop
	CFRunLoopSourceRef rls = CFSocketCreateRunLoopSource(kCFAllocatorDefault, socket, 0);
	
	if (rls) {
		CFRunLoopAddSource(gaimRunLoop, rls, kCFRunLoopCommonModes);
		CFRelease(rls);
	}

	info->fd = fd;
	info->socket = socket;

    if ((condition & GAIM_INPUT_READ)) {
		info->read_tag = ++sourceId;
		info->read_ioFunction = func;
		info->read_user_data = user_data;
		
		[sourceInfoDict setObject:[NSValue valueWithPointer:info]
						   forKey:[NSNumber numberWithUnsignedInt:info->read_tag]];
		
	} else {
		info->write_tag = ++sourceId;
		info->write_ioFunction = func;
		info->write_user_data = user_data;
		
		[sourceInfoDict setObject:[NSValue valueWithPointer:info]
						   forKey:[NSNumber numberWithUnsignedInt:info->write_tag]];		
	}
	
    return sourceId;
}

#pragma mark Socket Callback
static void socketCallback(CFSocketRef s,
						   CFSocketCallBackType callbackType,
						   CFDataRef address,
						   const void *data,
						   void *infoVoid)
{
    struct SourceInfo *sourceInfo = (struct SourceInfo*) infoVoid;
	gpointer user_data;
    GaimInputCondition c;
	GaimInputFunction ioFunction;
	gint	 fd = sourceInfo->fd;

    if ((callbackType & kCFSocketReadCallBack)) {
		user_data = sourceInfo->read_user_data;
		c = GAIM_INPUT_READ;
		ioFunction = sourceInfo->read_ioFunction;

	} else /* if ((callbackType & kCFSocketWriteCallBack)) */ {
		user_data = sourceInfo->write_user_data;
		c = GAIM_INPUT_WRITE;	
		ioFunction = sourceInfo->write_ioFunction;
	}

	ioFunction(user_data, fd, c);
}


static GaimEventLoopUiOps adiumEventLoopUiOps = {
    adium_timeout_add,
    adium_timeout_remove,
    adium_input_add,
    adium_source_remove
};

GaimEventLoopUiOps *adium_gaim_eventloop_get_ui_ops(void)
{
	if (!sourceInfoDict) sourceInfoDict = [[NSMutableDictionary alloc] init];

	//Determine our run loop
	gaimRunLoop = CFRunLoopGetCurrent();
	CFRetain(gaimRunLoop);
	
	return &adiumEventLoopUiOps;
}

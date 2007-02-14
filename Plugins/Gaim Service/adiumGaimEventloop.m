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
#include <poll.h>

#define GAIM_SOCKET_DEBUG 1

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
    CFSocketRef socket;
    int fd;
	CFRunLoopSourceRef run_loop_source;

    guint timer_tag;
	GSourceFunc timer_function;
    CFRunLoopTimerRef timer;
	gpointer timer_user_data;

    guint read_tag;
	GaimInputFunction read_ioFunction;
    gpointer read_user_data;

	guint write_tag;
	GaimInputFunction write_ioFunction;
    gpointer write_user_data;
};

struct SourceInfo *newSourceInfo(void)
{
	struct SourceInfo *info = (struct SourceInfo*)malloc(sizeof(struct SourceInfo));

	info->socket = NULL;
	info->fd = 0;
	info->run_loop_source = NULL;

	info->timer_tag = 0;
	info->timer_function = NULL;
	info->timer = NULL;
	info->timer_user_data = NULL;

	info->write_tag = 0;
	info->write_ioFunction = NULL;
	info->write_user_data = NULL;

	info->read_tag = 0;
	info->read_ioFunction = NULL;
	info->read_user_data = NULL;	
	
	return info;
}

#pragma mark Remove

/*!
 * @brief Given a SourceInfo struct for a socket which was for reading *and* writing, recreate its socket to be for just one
 *
 * If the sourceInfo still has a read_tag, the resulting CFSocket will be just for reading.
 * If the sourceInfo still has a write_tag, the resulting CFSocket will be just for writing.
 *
 * This is necessary to prevent the now-unneeded condition from triggerring its callback.
 */
void updateSocketForSourceInfo(struct SourceInfo *sourceInfo)
{
	CFSocketRef socket = sourceInfo->socket;
	
	//Reading
	if (sourceInfo->read_tag)
		CFSocketEnableCallBacks(socket, kCFSocketReadCallBack);
	else
		CFSocketDisableCallBacks(socket, kCFSocketReadCallBack);

	//Writing
	if (sourceInfo->write_tag)
		CFSocketEnableCallBacks(socket, kCFSocketWriteCallBack);
	else
		CFSocketDisableCallBacks(socket, kCFSocketWriteCallBack);
	
	//Re-enable callbacks automatically and, by starting with 0, _don't_ close the socket on invalidate
	CFOptionFlags flags = 0;
	
	if (sourceInfo->read_tag) flags |= kCFSocketAutomaticallyReenableReadCallBack;
	if (sourceInfo->write_tag) flags |= kCFSocketAutomaticallyReenableWriteCallBack;
	
	CFSocketSetSocketFlags(socket, flags);
	
}

guint adium_source_remove(guint tag) {
    struct SourceInfo *sourceInfo = (struct SourceInfo*)
	[[sourceInfoDict objectForKey:[NSNumber numberWithUnsignedInt:tag]] pointerValue];

    if (sourceInfo) {
#ifdef GAIM_SOCKET_DEBUG
		AILog(@"adium_source_remove(): Removing for fd %i [sourceInfo %x]: tag is %i (timer %i, read %i, write %i)",sourceInfo->fd,
			  sourceInfo, tag, sourceInfo->timer_tag, sourceInfo->read_tag, sourceInfo->write_tag);
#endif
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
#ifdef GAIM_SOCKET_DEBUG
				AILog(@"adium_source_remove(): Done with a socket %x, so invalidating it",sourceInfo->socket);
#endif
				CFSocketInvalidate(sourceInfo->socket);
				CFRelease(sourceInfo->socket);
				sourceInfo->socket = NULL;
			}

			if (sourceInfo->run_loop_source) {
				CFRelease(sourceInfo->run_loop_source);
			}

			free(sourceInfo);
		} else {
			if ((sourceInfo->timer_tag == 0) && (sourceInfo->timer)) {
				CFRunLoopTimerInvalidate(sourceInfo->timer);
				CFRelease(sourceInfo->timer);
				sourceInfo->timer = NULL;
			}
			
			if (sourceInfo->socket && (sourceInfo->read_tag || sourceInfo->write_tag)) {
#ifdef GAIM_SOCKET_DEBUG
				AILog(@"adium_source_remove(): Calling updateSocketForSourceInfo(%x)",sourceInfo);
#endif				
				updateSocketForSourceInfo(sourceInfo);
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

	if (!sourceInfo->timer_function ||
		!sourceInfo->timer_function(sourceInfo->timer_user_data)) {
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
	
	info->timer_function = function;
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
		NSLog(@"INVALID: fd was %i; returning tag %i",fd,sourceId+1);
		return ++sourceId;
	}

    struct SourceInfo *info = newSourceInfo();
	
    // And likewise the entire CFSocket
    CFSocketContext context = { 0, info, /* CFAllocatorRetainCallBack */ NULL, /* CFAllocatorReleaseCallBack */ NULL, /* CFAllocatorCopyDescriptionCallBack */ NULL };

	/*
	 * From CFSocketCreateWithNative:
	 * If a socket already exists on this fd, CFSocketCreateWithNative() will return that existing socket, and the other parameters
	 * will be ignored.
	 */
#ifdef GAIM_SOCKET_DEBUG
	AILog(@"adium_input_add(): Adding input %i on fd %i", condition, fd);
#endif
	CFSocketRef socket = CFSocketCreateWithNative(kCFAllocatorDefault,
												  fd,
												  (kCFSocketReadCallBack | kCFSocketWriteCallBack),
												  socketCallback,
												  &context);

	/* If we did not create a *new* socket, it is because there is already one for this fd in the run loop.
	 * See the CFSocketCreateWithNative() documentation), add it to the run loop.
	 * In that case, the socket's info was not updated.
	 */
	CFSocketContext actualSocketContext = { 0, NULL, NULL, NULL, NULL };
	CFSocketGetContext(socket, &actualSocketContext);
	if (actualSocketContext.info != info) {
		AILog(@"*** Got a cached socket; switching to it ***");
		free(info);
		CFRelease(socket);
		info = actualSocketContext.info;
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
	
	updateSocketForSourceInfo(info);
	
	//Add it to our run loop
#if 0
	if (info->run_loop_source) {
		AILog(@"Removing run loop source for %p",socket);
		CFRunLoopRemoveSource(gaimRunLoop, info->run_loop_source, /*kCFRunLoopCommonModes*/kCFRunLoopDefaultMode);
		CFRelease(info->run_loop_source);
	}

	info->run_loop_source = CFSocketCreateRunLoopSource(kCFAllocatorDefault, socket, 0);
	if (info->run_loop_source) {
		CFRunLoopAddSource(gaimRunLoop, info->run_loop_source, kCFRunLoopCommonModes);
	} else {
		AILog(@"*** Unable to create run loop source for %p",socket);
	}
#endif
	if (!(info->run_loop_source)) {
		info->run_loop_source = CFSocketCreateRunLoopSource(kCFAllocatorDefault, socket, 0);
		if (info->run_loop_source) {
			CFRunLoopAddSource(gaimRunLoop, info->run_loop_source, kCFRunLoopCommonModes);
		} else {
			AILog(@"*** Unable to create run loop source for %p",socket);
		}		
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
	GaimInputFunction ioFunction = NULL;
	gint	 fd = sourceInfo->fd;

    if ((callbackType & kCFSocketReadCallBack)) {
		if (sourceInfo->read_tag) {
			user_data = sourceInfo->read_user_data;
			c = GAIM_INPUT_READ;
			ioFunction = sourceInfo->read_ioFunction;
		} else {
			AILog(@"Called read with no read_tag (read_tag %i write_tag %i) for %x",
				  sourceInfo->read_tag, sourceInfo->write_tag, sourceInfo->socket);
		}

	} else /* if ((callbackType & kCFSocketWriteCallBack)) */ {
		if (sourceInfo->write_tag) {
			user_data = sourceInfo->write_user_data;
			c = GAIM_INPUT_WRITE;	
			ioFunction = sourceInfo->write_ioFunction;
		} else {
			AILog(@"Called write with no write_tag (read_tag %i write_tag %i) for %x",
				  sourceInfo->read_tag, sourceInfo->write_tag, sourceInfo->socket);
		}
	}

	if (ioFunction) {
#ifdef GAIM_SOCKET_DEBUG
		AILog(@"socketCallback(): Calling the ioFunction for %x, callback type %i (%s: tag is %i)",s,callbackType,
			  ((callbackType & kCFSocketReadCallBack) ? "reading" : "writing"),
			  ((callbackType & kCFSocketReadCallBack) ? sourceInfo->read_tag : sourceInfo->write_tag));
#endif
		ioFunction(user_data, fd, c);
	}
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
	gaimRunLoop = [[NSRunLoop currentRunLoop] getCFRunLoop];
	CFRetain(gaimRunLoop);

	return &adiumEventLoopUiOps;
}

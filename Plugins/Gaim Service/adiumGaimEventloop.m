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

CFSocketRef socketInRunLoop(int fd, CFOptionFlags callBackTypes, CFSocketContext *context)
{
	CFSocketRef socket = CFSocketCreateWithNative(kCFAllocatorDefault,
												  fd,
												  callBackTypes,
												  socketCallback,
												  context);
	if (!socket) AILog(@"CFSocket creation failed for fd %i", fd);
	NSCAssert1(socket != NULL, @"CFSocket creation failed for fd %i", fd);

	AILog(@"Ccreating socket for callbacktypes %i gave %x",callBackTypes,socket);

	/* If we created a new socket (versus returning a cached one -- see the CFSocketCreateWithNative() documentation), have it
	 * reenable callbacks automatically, and add it to the run loop.
	 */
	CFSocketContext actualSocketContext;
	CFSocketGetContext(socket, &actualSocketContext);
	if (actualSocketContext.info == context->info) {		
		//Re-enable callbacks automatically and _don't_ close the socket on invalidate
		CFOptionFlags flags = 0;
		
		if (callBackTypes & kCFSocketReadCallBack) {
			flags |= kCFSocketAutomaticallyReenableReadCallBack;
		}

		if (callBackTypes & kCFSocketWriteCallBack) {
			flags |= kCFSocketAutomaticallyReenableWriteCallBack;
		}
		AILog(@"socket %x created with flags %i",socket,flags);
		CFSocketSetSocketFlags(socket, flags);

		//Add it to our run loop
		CFRunLoopSourceRef rls = CFSocketCreateRunLoopSource(kCFAllocatorDefault, socket, 0);
		
		if (rls) {
			CFRunLoopAddSource(gaimRunLoop, rls, kCFRunLoopCommonModes);
			CFRelease(rls);
		}
	}

	return socket;
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
	
	if (sourceInfo->read_tag) {
		CFSocketSetSocketFlags(socket, kCFSocketAutomaticallyReenableReadCallBack);
		CFSocketDisableCallBacks(socket, kCFSocketWriteCallBack);
	} else {
		CFSocketSetSocketFlags(socket, kCFSocketAutomaticallyReenableWriteCallBack);
		CFSocketDisableCallBacks(socket, kCFSocketReadCallBack);		
	}

#if 0
	//We have a socket, and we still have either a read_tag or a write_tag
	CFOptionFlags callBackTypes = 0;

	if (sourceInfo->read_tag) callBackTypes |= kCFSocketReadCallBack;
	if (sourceInfo->write_tag) callBackTypes |= kCFSocketWriteCallBack;	

	//Create a context using the same sourceInfo
	CFSocketContext context = { 0, sourceInfo, /* CFAllocatorRetainCallBack */ NULL, /* CFAllocatorReleaseCallBack */ NULL, /* CFAllocatorCopyDescriptionCallBack */ NULL };

	//Invalidate the old socket, which was for both reading and writing
	AILog(@"updateSocketForSourceInfo(): Invalidating %x",sourceInfo->socket);
		  
	AILog(@"Its socket flags are %i (retain: %i)",CFSocketGetSocketFlags(sourceInfo->socket),CFGetRetainCount(sourceInfo->socket));
	CFSocketInvalidate(sourceInfo->socket);
	CFRelease(sourceInfo->socket);
	sourceInfo->socket = NULL;

	//Create a new socket which will be for just reading or just writing; associate it with the info
	sourceInfo->socket = socketInRunLoop(sourceInfo->fd, callBackTypes, &context);
	AILog(@"updateSocketForSourceInfo(): Got %x (%i) after reassignment...", sourceInfo->socket, CFSocketGetSocketFlags(sourceInfo->socket));
#endif
	/* All other aspects of the sourceInfo are still right, so leave them as-is */
}

guint adium_source_remove(guint tag) {
    struct SourceInfo *sourceInfo = (struct SourceInfo*)
	[[sourceInfoDict objectForKey:[NSNumber numberWithUnsignedInt:tag]] pointerValue];

    if (sourceInfo) {
		AILog(@"adium_source_remove(): Removing for fd %i [sourceInfo %x]: tag is %i (timer %i, read %i, write %i)",sourceInfo->fd,
			  sourceInfo, tag, sourceInfo->timer_tag, sourceInfo->read_tag, sourceInfo->write_tag);
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
				AILog(@"adium_source_remove(): Done with a socket %x, so invalidating it",sourceInfo->socket);
				CFSocketInvalidate(sourceInfo->socket);
				CFRelease(sourceInfo->socket);
				sourceInfo->socket = NULL;
			}
			
			free(sourceInfo);
		} else {
			if ((sourceInfo->timer_tag == 0) && (sourceInfo->timer)) {
				CFRunLoopTimerInvalidate(sourceInfo->timer);
				CFRelease(sourceInfo->timer);
				sourceInfo->timer = NULL;
			}
			
			if (sourceInfo->socket && (sourceInfo->read_tag || sourceInfo->write_tag)) {
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
		NSLog(@"INVALID: fd was %i; returning tag %i",fd,sourceId+1);
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
	AILog(@"adium_input_add(): We want to add an input on fd %i for callbacktypes %i",fd,callBackTypes);
    CFSocketRef socket = socketInRunLoop(fd, callBackTypes, &context);

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
		AILog(@"adium_input_add(): We need to recreate the socket for fd %i. Invalidating and releasing %x",fd,socket);
		CFSocketInvalidate(socket);
		CFRelease(socket);
		
		if (info->read_tag) {
			if (callBackTypes & kCFSocketReadCallBack) {
				/* If we already have a socket looking for a read, clear it, since we've invalidated and are recreating it.
				 * Really, this double gaim_input_add() call libgaimside is a bug, but we shouldn't crash in the situation.
				 */
				[sourceInfoDict removeObjectForKey:[NSNumber numberWithUnsignedInt:info->read_tag]];
			}
			callBackTypes |= kCFSocketReadCallBack;
		}
		if (info->write_tag) {
			if (callBackTypes & kCFSocketWriteCallBack) {
				/* If we already have a socket looking for a write, clear it, since we've invalidated and are recreating it.
				* Really, this double gaim_input_add() call libgaimside is a bug, but we shouldn't crash in the situation.
				*/
				[sourceInfoDict removeObjectForKey:[NSNumber numberWithUnsignedInt:info->write_tag]];
			}			
			callBackTypes |= kCFSocketWriteCallBack;			
		}

		AILog(@"adium_input_add(): An input on fd %i already existed; we're reassigning it callbacktypes %i",fd,callBackTypes);
		socket = socketInRunLoop(fd, callBackTypes, &context);
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
		AILog(@"socketCallback(): Calling the ioFunction for %x, callback type %i (%s: tag is %i)",s,callbackType,
			  ((callbackType & kCFSocketReadCallBack) ? "reading" : "writing"),
			  ((callbackType & kCFSocketReadCallBack) ? sourceInfo->read_tag : sourceInfo->write_tag));
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

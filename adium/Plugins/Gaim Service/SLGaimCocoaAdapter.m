//
//  SLGaimCocoaAdapter.m
//  Adium
//  Adapts gaim to the Cocoa event loop.
//  Requires Mac OS X 10.2.
//
//  Created by Scott Lamb on Sun Nov 2 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <stdlib.h>
#include <glib.h>
#include <libgaim/eventloop.h>

#import "SLGaimCocoaAdapter.h"
#import <CoreFoundation/CFSocket.h>
#import <CoreFoundation/CFRunLoop.h>

static void socketCallback(CFSocketRef s,
                           CFSocketCallBackType callbackType,
                           CFDataRef address,
                           const void *data,
                           void *infoVoid);

@interface SLGaimCocoaAdapter (PRIVATE)
- (void)callTimerFunc:(NSTimer*)timer;
@end

@implementation SLGaimCocoaAdapter

/*
 * The sources, keyed by integer key id (wrapped in an NSValue), holding
 * struct sourceInfo* values (wrapped in an NSValue).
 */
static NSMutableDictionary *sourceInfoDict;

/*
 * A pointer to the single instance of this class active in the application.
 * The gaim callbacks need to be C functions with specific prototypes, so they
 * can't be ObjC methods. The ObjC callbacks do need to be ObjC methods. This
 * allows the C ones to call the ObjC ones.
 **/
static SLGaimCocoaAdapter *myself;

static guint adium_timeout_add_full(gint, guint, GSourceFunc, gpointer, GDestroyNotify);
static gint adium_input_add(int, GaimInputCondition, GaimInputFunction, gpointer);
static void adium_input_remove(gint);

static GaimEventLoopUiOps adiumEventLoopUiOps = {
    adium_timeout_add_full,
    adium_io_add_watch_full,
    adium_source_remove
};

// The next source key; continuously incrementing
static guint sourceId;

// The structure of values of sourceInfoDict
struct SourceInfo {
    guint tag;
    NSTimer *timer;
    CFSocketRef socket;
    CFRunLoopSourceRef rls;
    union {
        GSourceFunc sourceFunction;
        GIOFunc ioFunction;
    };
    int fd;
    gpointer user_data;
};

- (id)init
{
    sourceInfoDict = [[NSMutableDictionary alloc] init];
    NSAssert(myself == nil, @"SLGaimCocoaAdapter is a singleton");
    myself = self;
    gaim_eventloop_set_ui_ops(&adiumEventLoopUiOps);
    return self;
}

static guint adium_timeout_add_full(guint interval, GSourceFunc function, gpointer data)
{
    //NSLog(@"New %u-ms timer (tag %u)", interval, sourceId);

    struct SourceInfo *info = (struct SourceInfo*)malloc(sizeof(struct SourceInfo));

    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)interval/1e3
                                                      target:myself
                                                    selector:@selector(callTimerFunc:)
                                                    userInfo:[NSValue valueWithPointer:info]
                                                     repeats:YES];
    info->tag = sourceId;
    info->sourceFunction = function;
    info->timer = timer;
    info->socket = NULL;
    info->rls = NULL;
    info->channel = NULL;
    info->user_data = data;
    NSCAssert1([sourceInfoDict objectForKey:[NSNumber numberWithUnsignedInt:sourceId]] == nil, @"Key %u in use", sourceId);
    [sourceInfoDict setObject:[NSValue valueWithPointer:info] forKey:[NSNumber numberWithUnsignedInt:sourceId]];
    return sourceId++;
}

- (void) callTimerFunc:(NSTimer*)timer
{
    struct SourceInfo *info = [[timer userInfo] pointerValue];
    //NSLog(@"Timer callback (tag %u)", info->tag);
    if ([sourceInfoDict objectForKey:[NSNumber numberWithUnsignedInt:info->tag]] == nil) {
        NSLog(@"Timer %u notification arrived after source removed", info->tag);
        return;
    }
    if (! info->sourceFunction(info->user_data))
        adium_source_remove(info->tag);
}

static gint adium_input_add(int fd, GaimInputCondition condition,
                            GaimInputFunction func, gpointer user_data)
{
    struct SourceInfo *info = g_new(struct SourceInfo, 1);

    // NSRunLoop does not support priority; that argument is ignored

    // Build the CFSocket-style callback flags to use from the gaim ones
    CFOptionFlags callBackTypes = 0;
    if ((condition & GAIM_INPUT_READ ) != 0) callBackTypes |= kCFSocketReadCallBack;
    if ((condition & GAIM_INPUT_WRITE) != 0) callBackTypes |= kCFSocketWriteCallBack;

    // And likewise the entire CFSocket
    CFSocketContext context = { 0, info, NULL, NULL, NULL };
    CFSocketRef socket = CFSocketCreateWithNative(NULL, fd, callBackTypes, socketCallback, &context);
    NSCAssert(socket != NULL, @"CFSocket creation failed");
    info->socket = socket;

    // Re-enable callbacks automatically and _don't_ close the socket on
    // invalidate
    CFSocketSetSocketFlags(socket,   kCFSocketAutomaticallyReenableDataCallBack
                                   | kCFSocketAutomaticallyReenableWriteCallBack);

    // Add it to our run loop
    CFRunLoopSourceRef rls = CFSocketCreateRunLoopSource(NULL, socket, 0);
    CFRunLoopAddSource([[NSRunLoop currentRunLoop] getCFRunLoop], rls, kCFRunLoopCommonModes);
    info->rls = rls;

    info->timer = NULL;
    info->tag = sourceId;
    info->ioFunction = func;
    info->user_data = user_data;
    info->fd = fd;
    NSCAssert1([sourceInfoDict objectForKey:[NSNumber numberWithUnsignedInt:sourceId]] == nil, @"Key %u in use", sourceId);
    [sourceInfoDict setObject:[NSValue valueWithPointer:info] forKey:[NSNumber numberWithUnsignedInt:sourceId]];

    //NSLog(@"Watching for IO on descriptor %d (tag %u)", fd, sourceId);
    return sourceId++;
}

static void socketCallback(CFSocketRef s,
                           CFSocketCallBackType callbackType,
                           CFDataRef address,
                           const void *data,
                           void *infoVoid)
{
    struct SourceInfo *info = (struct SourceInfo*) infoVoid;

    GaimInputCondition c = 0;
    if ((callbackType & kCFSocketReadCallBack) != 0)  c |= GAIM_INPUT_READ;
    if ((callbackType & kCFSocketWriteCallBack) != 0) c |= GAIM_INPUT_WRITE;

    //NSLog(@"NSRunLoop reports IO on tag %u", info->tag);
    if (! info->ioFunction(c, info->user_data, info->fd, c))
        adium_input_remove(info->tag);
}

static void adium_input_remove(gint tag) {
    //NSLog(@"Removing source tag %u", tag);
    struct SourceInfo *sourceInfo = (struct SourceInfo*)
        [[sourceInfoDict objectForKey:[NSNumber numberWithUnsignedInt:tag]] pointerValue];

    if (sourceInfo == NULL)
        return FALSE;

    if (sourceInfo->channel == NULL) { // timer
        [sourceInfo->timer invalidate];
    } else { // file handle
        CFRunLoopSourceInvalidate(sourceInfo->rls);
        CFSocketInvalidate(sourceInfo->socket);
    }

    [sourceInfoDict removeObjectForKey:[NSNumber numberWithUnsignedInt:tag]];
    free(sourceInfo);
    return TRUE;
}

@end

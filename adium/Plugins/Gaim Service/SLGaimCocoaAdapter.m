//
//  SLGaimCocoaAdapter.m
//  Adium
//  Adapts gaim to the Cocoa event loop.
//
//  Created by Scott Lamb on Sun Nov 2 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <stdlib.h>
#include <glib.h>
#include <libgaim/eventloop.h>

#import "SLGaimCocoaAdapter.h"

@interface SLGaimCocoaAdapter (PRIVATE)
- (void)callTimerFunc:(id)obj;
- (void)callIOFunc:(id)obj;
@end

@implementation SLGaimCocoaAdapter

/*
 * The sources, keyed by integer key id (wrapped in an NSValue), holding
 * struct sourceInfo* values (wrapped in an NSValue).
 */
static NSMutableDictionary *sourceInfoDict;

/*
 * The sources, keyed by NSFileHandle, holding struct sourceInfo* values
 * (wrapped in an NSValue).
 */
static NSMutableDictionary *fhDict;

/*
 * A pointer to the single instance of this class active in the application.
 * The gaim callbacks need to be C functions with specific prototypes, so they
 * can't be ObjC methods. The ObjC callbacks do need to be ObjC methods. This
 * allows the C ones to call the ObjC ones.
 **/
static SLGaimCocoaAdapter *myself;

static guint adium_timeout_add_full(gint, guint, GSourceFunc, gpointer, GDestroyNotify);
static guint adium_io_add_watch_full(GIOChannel*, gint, GIOCondition, GIOFunc, gpointer, GDestroyNotify);
static gboolean adium_source_remove(guint);

static GaimEventLoopUiOps adiumEventLoopUiOps = {
    adium_timeout_add_full,
    adium_io_add_watch_full,
    adium_source_remove
};

// The next source key; continuously incrementing
static guint sourceId;

// The structure of values of sourceInfoDict and fhDict
struct SourceInfo {
    guint tag;
    id source;
    GDestroyNotify notify;
    union {
        GSourceFunc sourceFunction;
        GIOFunc ioFunction;
    };
    GIOChannel *channel;
    gpointer user_data;
};

- (id)init
{
    sourceInfoDict = [[NSMutableDictionary alloc] init];
    fhDict = [[NSMutableDictionary alloc] init];
    NSAssert(myself == nil, @"SLGaimCocoaAdapter is a singleton");
    myself = self;
    gaim_eventloop_set_ui_ops(&adiumEventLoopUiOps);
    return self;
}

static guint adium_timeout_add_full(gint priority, guint interval,
        GSourceFunc function, gpointer data, GDestroyNotify notify)
{
    // NSTimer doesn't do priority, so that argument is ignored.

    struct SourceInfo *info = (struct SourceInfo*)malloc(sizeof(struct SourceInfo));

    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)interval/1e3
                                                      target:myself
                                                    selector:@selector(callTimerFunc:)
                                                    userInfo:[NSValue valueWithPointer:info]
                                                     repeats:YES];
    info->tag = sourceId;
    info->notify = notify;
    info->sourceFunction = function;
    info->source = timer;
    info->channel = NULL;
    info->user_data = data;
    [sourceInfoDict setObject:[NSValue valueWithPointer:info] forKey:[NSNumber numberWithUnsignedInt:sourceId]];
    return sourceId++;
}

- (void) callTimerFunc:(id)timer
{
    struct SourceInfo *info = [[timer userInfo] pointerValue];
    if (! info->sourceFunction(info->user_data))
        adium_source_remove(info->tag);
}

static guint adium_io_add_watch_full(GIOChannel *channel, gint priority,
        GIOCondition condition, GIOFunc func, gpointer user_data,
        GDestroyNotify notify)
{
    // NSRunLoop does not support priority; that argument is ignored

    // XXX Condition is very restricted: we only support G_IO_IN
    // Should check on G_IO_ERR at least; this might be folded in with the
    // read stuff.
    NSFileHandle *fh = [[NSFileHandle alloc] initWithFileDescriptor:g_io_channel_unix_get_fd(channel)];
    struct SourceInfo *info = (struct SourceInfo*)malloc(sizeof(struct SourceInfo));
    info->tag = sourceId;
    info->notify = notify;
    info->ioFunction = func;
    info->channel = channel;
    info->user_data = user_data;
    [[NSNotificationCenter defaultCenter] addObserver:myself
                                             selector:@selector(callIOFunc:)
                                                 name:NSFileHandleDataAvailableNotification
                                               object:fh];
    [fh waitForDataInBackgroundAndNotify];
    NSCAssert(condition == G_IO_IN, @"Condition is something other than pure read");
    [sourceInfoDict setObject:[NSValue valueWithPointer:info] forKey:[NSNumber numberWithUnsignedInt:sourceId]];
    [fhDict setObject:[NSValue valueWithPointer:info] forKey:fh];
    return sourceId++;
}

- (void) callIOFunc:(id)object
{
    NSFileHandle *fh = (NSFileHandle*) object;
    NSAssert(fh != nil, @"IO on nil NSFileHandle");
    struct SourceInfo *info = (struct SourceInfo*) [[fhDict objectForKey:fh] pointerValue];
    NSAssert(info != NULL, @"NSFileHandle not found in dictionary");
    if (! info->ioFunction(info->channel, G_IO_IN, info->user_data))
        adium_source_remove(info->tag);
}

static gboolean adium_source_remove(guint tag) {
    struct SourceInfo *sourceInfo = (struct SourceInfo*)
        [[sourceInfoDict objectForKey:[NSNumber numberWithUnsignedInt:tag]] pointerValue];

    if (sourceInfo == NULL)
        return FALSE;

    if ([sourceInfo->source isKindOfClass:[NSTimer class]]) {
        NSTimer *timer = (NSTimer*) sourceInfo->source;
        [timer invalidate];
    } else { // file handle
        NSFileHandle *fh = (NSFileHandle*) sourceInfo->source;
        [fh release];
        [fhDict removeObjectForKey:fh];
    }

    if (sourceInfo->notify != NULL)
        sourceInfo->notify(sourceInfo->user_data);

    [sourceInfoDict removeObjectForKey:[NSNumber numberWithUnsignedInt:tag]];
    free(sourceInfo);
    return TRUE;
}

@end

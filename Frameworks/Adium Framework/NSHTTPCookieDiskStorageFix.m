//
//  NSHTTPCookieDiskStorageFix.m
//  Adium
//
//  Created by Evan Schoenberg on 3/25/05.
//  Copyright 2005 The Adium Team. All rights reserved.
//

#import "NSHTTPCookieDiskStorageFix.h"


@implementation NSHTTPCookieDiskStorageFix

+ (void)load
{
    //Anything you can do, I can do better...
    [self poseAsClass:[NSHTTPCookieDiskStorage class]];
}

/*!
 * @brief Override saving of cookies
 *
 * An attempt to fix this incredibly random crash, also seen intermittantly in Mail.app and other Apple apps.
 * 
 * Thread 0 Crashed:
 * 0   libobjc.A.dylib                     0x908311ec objc_msgSend + 0xc
 * 1   com.apple.CoreFoundation            0x90197f28 CFDictionaryRemoveAllValues + 0x200
 * 2   com.apple.Foundation                0x90a4e410 -[NSHTTPCookieDiskStorage(NSInternal) _saveCookies] + 0x1b4
 * 3   com.apple.Foundation                0x909f7184 _nsnote_callback + 0xb0
 * 4   com.apple.CoreFoundation            0x901e7b5c __CFXNotificationPostEntry + 0x94
 * 5   com.apple.CoreFoundation            0x901d560c __CFXNotificationHandleMessage + 0x1ac
 * 6   com.apple.CoreFoundation            0x901d03d4 __CFXNotificationReceiveFromServer + 0x150
 * 7   com.apple.CoreFoundation            0x901ad2a0 __CFMachPortPerform + 0xe0
 * 8   com.apple.CoreFoundation            0x901a9a24 __CFRunLoopDoSource1 + 0xc8
 * 9   com.apple.CoreFoundation            0x901918f0 __CFRunLoopRun + 0x540
 * 10  com.apple.CoreFoundation            0x90195e8c CFRunLoopRunSpecific + 0x148
 * 11  com.apple.HIToolbox                 0x927d5f60 RunCurrentEventLoopInMode + 0xac
 * 12  com.apple.HIToolbox                 0x927dc6c8 ReceiveNextEventCommon + 0x17c
 * 13  com.apple.HIToolbox                 0x927fe6a0 BlockUntilNextEventMatchingListInMode + 0x60
 * 14  com.apple.AppKit                    0x92dd2e44 _DPSNextEvent + 0x180
 * 15  com.apple.AppKit                    0x92de98c8 -[NSApplication nextEventMatchingMask:untilDate:inMode:dequeue:] + 0x74
 * 16  com.apple.AppKit                    0x92dfdc30 -[NSApplication run] + 0x21c
 * 17  com.apple.AppKit                    0x92eba2b8 NSApplicationMain + 0x1d0
 * 18  com.adiumX.adiumX                   0x0000a800 _start + 0x188 (crt.c:267)
 * 19  dyld                                0x8fe1a558 _dyld_start + 0x64
 */
- (void)_saveCookies { NSLog(@"Save them cookies!"); };
	

@end

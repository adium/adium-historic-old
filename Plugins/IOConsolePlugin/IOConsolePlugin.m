//
//  IOConsolePlugin.m
//  Adium
//
//  Created by David Smith on 12/24/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "IOConsolePlugin.h"
#import "AIAdium.h"
#include "IOState_eval.h"
#include "IONumber.h"

NSString *io_resultString = nil;

static void printCallback(void *state, size_t count, const char *s)
{
	[io_resultString release];
	io_resultString = [[NSString stringWithFormat:@"%s", s]retain];
}

@implementation IOConsolePlugin
- (void)installPlugin
{
	s = IoState_new();
#ifdef IOBINDINGS
    IoState_setBindingsInitCallback(s, (IoStateBindingsInitCallback *)IoAddonsInit);
#endif
    IoState_init(s);
	IoState_printCallback_(s, printCallback);
	//IoState_exceptionCallback_(s, exceptionCallback);
	[[adium contentController] registerContentFilter:self ofType:AIFilterContent direction:AIFilterOutgoing];
}

- (void)uninstallPlugin
{
	[[adium contentController] unregisterContentFilter:self];
	IoState_free(s);
}

- (NSAttributedString *)filterAttributedString:(NSAttributedString *)inAttributedString context:(id)context
{
	NSMutableAttributedString *message = [[inAttributedString mutableCopyWithZone:[inAttributedString zone]] autorelease];
	NSRange codeRange;
	NSString *messageString = [message string];
	codeRange.location = NSMaxRange([messageString rangeOfString:@"io{"]);
	if(codeRange.location != NSNotFound) {
		codeRange.length = [messageString rangeOfString:@"}io"].location - codeRange.location;
		NSRange replaceRange = codeRange;
		replaceRange.location -= 3;
		replaceRange.length += 6;
		[self runIOString:[messageString substringWithRange:codeRange]];
		[message replaceCharactersInRange:replaceRange withString:io_resultString];
		return message;
	}
	else
		return inAttributedString;
}



//static void exceptionCallback(void *state, IoException *e)
//{
//	IoException_printBackTrace(e);
//}

void IoAddonsInit(IoObject *context); 

//#define IOBINDINGS 

- (void) runIOString:(NSString *)string
{
	@synchronized(self) {
		IoObject *result = IoState_doCString_(s, [string cStringUsingEncoding:NSASCIIStringEncoding]);
		IoObject_print(result);
	}
}

- (float)filterPriority
{
	return DEFAULT_FILTER_PRIORITY;
}
@end

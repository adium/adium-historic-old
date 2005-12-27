//
//  AITextAttachmentAdditions.m
//  AIUtilities.framework
//
//  Created by Evan Schoenberg on 12/27/05.
//

#import "AITextAttachmentAdditions.h"

@implementation NSTextAttachment (AITextAttachmentAdditions)

- (BOOL)wrapsImage
{
	NSFileWrapper *wrapper = [self fileWrapper];
	NSArray *imageFileTypes = [NSImage imageFileTypes];

	OSType			HFSTypeCode;

	HFSTypeCode = [[wrapper fileAttributes] fileHFSTypeCode];
	if(HFSTypeCode) {
		return [imageFileTypes containsObject:NSFileTypeForHFSTypeCode(HFSTypeCode)];
	} else {
		//an NSFileWrapper may not necessarily wrap a file on disk. in this event, its filename is nil.
		//containsObject:nil is an exception, so we must simply return NO in this case.
		NSString *ext = [[wrapper filename] pathExtension];
		return ext ? [imageFileTypes containsObject:ext] : NO;
	}
}

@end

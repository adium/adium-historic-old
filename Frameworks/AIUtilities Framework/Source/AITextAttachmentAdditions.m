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
	OSType			HFSTypeCode;
				
	HFSTypeCode = [[[[self fileWrapper] fileAttributes] objectForKey:NSFileHFSTypeCode] unsignedLongValue];
	
	return [[NSImage imageFileTypes] containsObject:NSFileTypeForHFSTypeCode(HFSTypeCode)];
}

@end

//
//  MXImageTextAttachmentCell.h
//  ServiceTest
//
//  Created by Max Cantor on Thu Jun 19 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MXImageTextAttachmentCell : NSTextAttachmentCell {
    NSImage *image;
    NSTextAttachment *attachment;
 }
+ (MXImageTextAttachmentCell *) cellWithPasteboard:(NSPasteboard *)pb
                                        attachment:(NSTextAttachment *)a
                                              flip:(BOOL)f;
- (MXImageTextAttachmentCell *) initWithPasteboard:(NSPasteboard *)pb
                                        attachment:(NSTextAttachment *)a;
- (MXImageTextAttachmentCell *) initWithPasteboard:(NSPasteboard *)pb
                                        attachment:(NSTextAttachment *)a
                                              flip:(BOOL)f;
    
@end

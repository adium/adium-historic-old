//
//  ESImageAdditions.m
//  Adium XCode
//
//  Created by Evan Schoenberg on Tue Dec 02 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "ESImageAdditions.h"


@implementation NSImage (ESImageAdditions)

- (NSData *)JPEGRepresentation
{
    NSBitmapImageRep *imageRep = [[[NSBitmapImageRep alloc] initWithData:[self TIFFRepresentation]] autorelease];
    
    /*
     //This ends up looking terrible.  We're just going to use no compression (1.0 compression factor, despite what the documentation says) for now.
    //Figure out the compression
    NSTIFFCompression   tiffCompression;
    float               compressionFactor;

    [imageRep getCompression:&tiffCompression factor:&compressionFactor];
    if (tiffCompression == NSTIFFCompressionNone)
        compressionFactor = 0.0;
    */
    return ([imageRep representationUsingType:NSJPEGFileType 
                                   properties:/*[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1.0] forKey:NSImageCompressionFactor]*/nil]);
}

@end

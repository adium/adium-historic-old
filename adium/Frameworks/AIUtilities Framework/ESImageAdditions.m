//
//  ESImageAdditions.m
//  Adium XCode
//
//  Created by Evan Schoenberg on Tue Dec 02 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "ESImageAdditions.h"
#import "pxmLib.h"

#define RESOURCE_ID_CLOSE_BUTTON_AQUA       201
#define RESOURCE_ID_CLOSE_BUTTON_GRAPHITE   10191
#define RESOURCE_TYPE_CLOSE_BUTTON	    'pxm#'
#define RESOURCE_ID_CHECKMARK				260

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

//Draw this image in a rect, tiling if the rect is larger than the image
- (void)tileInRect:(NSRect)rect
{
    NSSize  size = [self size];
    NSRect  destRect = NSMakeRect(rect.origin.x, rect.origin.y, size.width, size.height);
    double  top = rect.origin.y + rect.size.height;
    double  right = rect.origin.x + rect.size.width;
    
    //Tile vertically
    while(destRect.origin.y < top){
	//Tile horizontally
	while(destRect.origin.x < right){
	    NSRect  sourceRect = NSMakeRect(0, 0, size.width, size.height);
	    
	    //Crop as necessary
	    if((destRect.origin.x + destRect.size.width) > right){
		sourceRect.size.width -= (destRect.origin.x + destRect.size.width) - right;
	    }
	    if((destRect.origin.y + destRect.size.height) > top){
		sourceRect.size.height -= (destRect.origin.y + destRect.size.height) - top;
	    }
	    
	    //Draw and shift
	    [self compositeToPoint:destRect.origin fromRect:sourceRect operation:NSCompositeSourceOver];
	    destRect.origin.x += destRect.size.width;
	}
	destRect.origin.y += destRect.size.height;
    }
}

// Originally from Apple's "CocoaVideoFrameToNSImage" Sample code
//
//	File:		MyQuickDrawView.m
//	Contains:	Implementation file for the MyQuickDrawView class.
//	Written by:	Apple Developer Technical Support
//	Copyright:	� 2002 by Apple Computer, Inc., all rights reserved.
//
// Convert contents of a gworld to an NSImage 
+ (NSImage *)imageFromGWorld:(GWorldPtr)gWorldPtr
{
    PixMapHandle 		pixMapHandle = NULL;
    Ptr 				pixBaseAddr = nil;
    NSBitmapImageRep 	*imageRep = nil;
    NSImage 			*image = nil;
    
    NSAssert(gWorldPtr != nil, @"nil gWorldPtr");
    
    // Lock the pixels
    pixMapHandle = GetGWorldPixMap(gWorldPtr);
    if (pixMapHandle)
    {
        Rect 		portRect;
        unsigned 	portWidth, portHeight;
        int 		bitsPerSample, samplesPerPixel;
        BOOL 		hasAlpha, isPlanar;
        int 		destRowBytes;
	
        NSAssert(LockPixels(pixMapHandle) != false, @"LockPixels returns false");
	
        GetPortBounds(gWorldPtr, &portRect);
        portWidth = (portRect.right - portRect.left);
        portHeight = (portRect.bottom - portRect.top);
	
        bitsPerSample 	= 8;
        samplesPerPixel = 4;
        hasAlpha	= YES;
        isPlanar	= NO;
        destRowBytes 	= portWidth * samplesPerPixel;
        imageRep	= [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:portWidth pixelsHigh:portHeight bitsPerSample:bitsPerSample samplesPerPixel:samplesPerPixel hasAlpha:hasAlpha isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:destRowBytes bitsPerPixel:0];
        if(imageRep)
        {
            char 	*theData;
            int 	pixmapRowBytes;
            int 	rowByte,rowIndex;
	    
            theData = [imageRep bitmapData];
	    
            pixBaseAddr = GetPixBaseAddr(pixMapHandle);
            if (pixBaseAddr)
            {
                pixmapRowBytes = GetPixRowBytes(pixMapHandle);
		
                for (rowIndex=0; rowIndex< portHeight; rowIndex++)
                {
                    unsigned char *dst = theData + rowIndex * destRowBytes;
                    unsigned char *src = pixBaseAddr + rowIndex * pixmapRowBytes;
                    unsigned char a,r,g,b;
                    
                    for (rowByte = 0; rowByte < portWidth; rowByte++)
                    {
			a = *src++;		// get source Alpha component
                        r = *src++;		// get source Red component
                        g = *src++;		// get source Green component
                        b = *src++;		// get source Blue component  
			
                        *dst++ = a;		// set dest. Alpha component
                        *dst++ = r;		// set dest. Red component
                        *dst++ = g;		// set dest. Green component
                        *dst++ = b;		// set dest. Blue component  
                    }
                }
		
                image = [[NSImage alloc] initWithSize:NSMakeSize(portWidth, portHeight)];
                if (image)
                {
                    [image addRepresentation:imageRep];
                    [imageRep release];
                }
            }
        }
    }
    
    NSAssert(pixMapHandle != NULL, @"null pixMapHandle");
    NSAssert(imageRep != nil, @"nil imageRep");
    NSAssert(pixBaseAddr != nil, @"nil pixBaseAddr");
    NSAssert(image != nil, @"nil image");
    
    if (pixMapHandle)
    {
        UnlockPixels(pixMapHandle);
    }
    
    return image;
}

//Returns the current theme's miniature panel close button
+ (NSImage *)systemCloseButtonImageForState:(AICloseButtonState)state controlTint:(NSControlTint)inTint
{
    NSString    *theFilePath = @"/System/Library/Frameworks/Carbon.framework/Versions/A/Frameworks/HIToolbox.framework/Versions/A/Resources/Extras.rsrc";
    FSRef       ref;
    NSImage     *closeImage = nil;
    
    if(FSPathMakeRef([theFilePath fileSystemRepresentation], &ref, NULL) == noErr){
		HFSUniStr255    forkName;
		SInt16		refNum;
		Handle		resource;
		pxmRef		pixmap;
		GWorldPtr       gWorld;
		int		resourceID;
		
		if(inTint == NSBlueControlTint){
			resourceID = RESOURCE_ID_CLOSE_BUTTON_AQUA;
		}else{ //inTint == NSGraphiteControlTint
			resourceID = RESOURCE_ID_CLOSE_BUTTON_GRAPHITE;
		}
		
		//Extract the close button's pxm# resource for the close button
		FSGetDataForkName(&forkName);
		FSOpenResourceFile(&ref, forkName.length, forkName.unicode, fsRdPerm, &refNum);
		resource = GetResource(RESOURCE_TYPE_CLOSE_BUTTON,resourceID);
		
		//Use the Sprocket pxm# code to extract the correct close button image
		HLock(resource);
		pixmap = pxmCreate(*resource, GetHandleSize(resource));
		HUnlock(resource);
		pxmMakeGWorld(pixmap, &gWorld);
		pxmRenderImage(pixmap, state, gWorld);
		
		//Place this image into an NSImage, and return
		closeImage = [NSImage imageFromGWorld:gWorld];
		
		//Close up
		pxmDispose(pixmap);
		CloseResFile(refNum);
    }
    
    return(closeImage);
}

//Returns the system check mark
+ (NSImage *)systemCheckmark
{
    NSString    *theFilePath = @"/System/Library/Frameworks/Carbon.framework/Versions/A/Frameworks/HIToolbox.framework/Versions/A/Resources/Extras.rsrc";
    FSRef       ref;
    NSImage     *closeImage = nil;
    
    if(FSPathMakeRef([theFilePath fileSystemRepresentation], &ref, NULL) == noErr){
		HFSUniStr255    forkName;
		SInt16		refNum;
		Handle		resource;
		pxmRef		pixmap;
		GWorldPtr       gWorld;
		int		resourceID = RESOURCE_ID_CHECKMARK;
		
		//Extract the close button's pxm# resource for the close button
		FSGetDataForkName(&forkName);
		FSOpenResourceFile(&ref, forkName.length, forkName.unicode, fsRdPerm, &refNum);
		resource = GetResource(RESOURCE_TYPE_CLOSE_BUTTON,resourceID);
		
		//Use the Sprocket pxm# code to extract the correct close button image
		HLock(resource);
		pixmap = pxmCreate(*resource, GetHandleSize(resource));
		HUnlock(resource);
		pxmMakeGWorld(pixmap, &gWorld);
		pxmRenderImage(pixmap, 0, gWorld);
		
		//Place this image into an NSImage, and return
		closeImage = [NSImage imageFromGWorld:gWorld];
		
		//Close up
		pxmDispose(pixmap);
		CloseResFile(refNum);
    }
    
    return(closeImage);
}

@end

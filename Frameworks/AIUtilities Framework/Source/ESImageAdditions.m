//
//  ESImageAdditions.m
//  Adium
//
//  Created by Evan Schoenberg on Tue Dec 02 2003.
//

#import "ESImageAdditions.h"
#import "pxmLib.h"

#define RESOURCE_ID_CLOSE_BUTTON_AQUA       201
#define RESOURCE_ID_CLOSE_BUTTON_GRAPHITE   10191
#define RESOURCE_TYPE_CLOSE_BUTTON			'pxm#'
#define RESOURCE_ID_CHECKMARK				260

@implementation NSImage (ESImageAdditions)

// Returns an image from the owners bundle with the specified name
+ (NSImage *)imageNamed:(NSString *)name forClass:(Class)inClass
{
    NSBundle	*ownerBundle;
    NSString	*imagePath;
    NSImage		*image;
	
    //Get the bundle
    ownerBundle = [NSBundle bundleForClass:inClass];
	
    //Open the image
    imagePath = [ownerBundle pathForImageResource:name];    
    image = [[NSImage alloc] initWithContentsOfFile:imagePath];
	
    return([image autorelease]);
}

- (NSData *)JPEGRepresentation
{
    NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:[self TIFFRepresentation]];
    
    return ([imageRep representationUsingType:NSJPEGFileType 
                                   properties:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1.0] 
																		  forKey:NSImageCompressionFactor]]);
}

- (NSData *)PNGRepresentation
{
	NSBitmapImageRep	*bitmapRep =  [NSBitmapImageRep imageRepWithData:[self TIFFRepresentation]];
	
	return ([bitmapRep representationUsingType:NSPNGFileType properties:nil]);
}

- (NSData *)BMPRepresentation
{
	NSBitmapImageRep	*bitmapRep = [NSBitmapImageRep imageRepWithData:[self TIFFRepresentation]];
	
	return ([bitmapRep representationUsingType:NSBMPFileType properties:nil]);
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

- (NSImage *)imageByScalingToSize:(NSSize)size
{
	return ([self imageByScalingToSize:size fraction:1.0 flipImage:NO proportionally:YES]);
}

- (NSImage *)imageByFadingToFraction:(float)delta
{
	return([self imageByScalingToSize:[self size] fraction:delta flipImage:NO proportionally:NO]);
}

- (NSImage *)imageByScalingToSize:(NSSize)size fraction:(float)delta
{
	return([self imageByScalingToSize:size fraction:delta flipImage:NO proportionally:YES]);
}

- (NSImage *)imageByScalingToSize:(NSSize)size fraction:(float)delta flipImage:(BOOL)flipImage proportionally:(BOOL)proportionally
{
	NSSize  originalSize = [self size];
	
	//Proceed only if size or delta are changing
	if((NSEqualSizes(originalSize, size)) && (delta == 1.0) && !flipImage){
		return([[self copy] autorelease]);
		
	}else{
		NSImage *newImage;
		NSRect	newRect;
		
		//Scale proportionally (rather than stretching to fit) if requested and needed
		if (proportionally && (originalSize.width != originalSize.height)){
			if (originalSize.width > originalSize.height){
				//Give width priority: Make the height change by the same proportion as the width will change
				size.height = originalSize.height * (size.width / originalSize.width);
			}else{
				//Give height priority: Make the width change by the same proportion as the height will change
				size.width = originalSize.width * (size.height / originalSize.height);
			}
		}
		
		newRect = NSMakeRect(0,0,size.width,size.height);
		newImage = [[NSImage alloc] initWithSize:size];

		if(flipImage) [newImage setFlipped:YES];		
		
		[newImage lockFocus];
		//Highest quality interpolation
		[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
		[self drawInRect:newRect
				fromRect:NSMakeRect(0,0,originalSize.width,originalSize.height)
			   operation:NSCompositeCopy
				fraction:delta];
		[newImage unlockFocus];
		
		return([newImage autorelease]);	
	}
}

+ (NSImage *)imageFromGWorld:(GWorldPtr)gworld
{
    NSParameterAssert(gworld != NULL);
	
    PixMapHandle pixMapHandle = GetGWorldPixMap( gworld );
    if(LockPixels(pixMapHandle)){
        Rect 	portRect;
        
		GetPortBounds( gworld, &portRect );
		
        int 	pixels_wide = (portRect.right - portRect.left);
        int 	pixels_high = (portRect.bottom - portRect.top);
        int 	bps = 8;
        int 	spp = 4;
        BOOL 	has_alpha = YES;
		
        NSBitmapImageRep *bitmap_rep = [[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
																				pixelsWide:pixels_wide
																				pixelsHigh:pixels_high
																			 bitsPerSample:bps
																		   samplesPerPixel:spp
																				  hasAlpha:has_alpha
																				  isPlanar:NO
																			colorSpaceName:NSDeviceRGBColorSpace
																			   bytesPerRow:0
																			  bitsPerPixel:0] autorelease];
        CGColorSpaceRef 	dst_colorspaceref = CGColorSpaceCreateDeviceRGB();
        CGImageAlphaInfo 	dst_alphainfo = has_alpha ? kCGImageAlphaPremultipliedLast : kCGImageAlphaNone;
        CGContextRef 		dst_contextref = CGBitmapContextCreate([bitmap_rep bitmapData],
																   pixels_wide,
																   pixels_high,
																   bps,
																   [bitmap_rep bytesPerRow],
																   dst_colorspaceref,
																   dst_alphainfo);
        void *pixBaseAddr = GetPixBaseAddr(pixMapHandle);
        long pixmapRowBytes = GetPixRowBytes(pixMapHandle);
		
        CGDataProviderRef dataproviderref = CGDataProviderCreateWithData(NULL, pixBaseAddr, pixmapRowBytes * pixels_high, NULL);
		
        int src_bps = 8;
        int src_spp = 4;
        BOOL src_has_alpha = YES;
		
        CGColorSpaceRef src_colorspaceref = CGColorSpaceCreateDeviceRGB();
		
        CGImageAlphaInfo src_alphainfo = src_has_alpha ? kCGImageAlphaPremultipliedFirst : kCGImageAlphaNone;
		
        CGImageRef src_imageref = CGImageCreate(pixels_wide,
												pixels_high,
												src_bps,
												src_bps * src_spp,
												pixmapRowBytes,
												src_colorspaceref,
												src_alphainfo,
												dataproviderref,
												NULL,
												NO, // shouldInterpolate
												kCGRenderingIntentDefault);
		
        CGRect rect = CGRectMake(0, 0, pixels_wide, pixels_high);
		
        CGContextDrawImage(dst_contextref, rect, src_imageref);
		
        CGImageRelease(src_imageref);
        CGColorSpaceRelease(src_colorspaceref);
        CGDataProviderRelease(dataproviderref);
        CGContextRelease(dst_contextref);
        CGColorSpaceRelease(dst_colorspaceref);
		
        UnlockPixels(pixMapHandle);
		
        NSImage *image = [[[NSImage alloc] initWithSize:NSMakeSize(pixels_wide, pixels_high)] autorelease];
        [image addRepresentation:bitmap_rep];
        return image;
    }
    return NULL;
}

//Returns the current theme's miniature panel close button
+ (NSImage *)systemCloseButtonImageForState:(AICloseButtonState)state controlTint:(NSControlTint)inTint
{
    NSString    *theFilePath = @"/System/Library/Frameworks/Carbon.framework/Versions/A/Frameworks/HIToolbox.framework/Versions/A/Resources/Extras.rsrc";
    FSRef       ref;
    NSImage     *closeImage = nil;
    
    if(FSPathMakeRef([theFilePath fileSystemRepresentation], &ref, NULL) == noErr){
		HFSUniStr255    forkName;
		SInt16			refNum;
		Handle			resource;
		pxmRef			pixmap;
		GWorldPtr       gWorld;
		int				resourceID;
		
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
		SInt16			refNum;
		Handle			resource;
		pxmRef			pixmap;
		GWorldPtr       gWorld;
		int				resourceID = RESOURCE_ID_CHECKMARK;
		
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

//Fun drawing toys
//Draw an image, altering and returning the available destination rect
- (NSRect)drawInRect:(NSRect)rect atSize:(NSSize)size position:(IMAGE_POSITION)position fraction:(float)fraction
{
	//We use our own size for drawing purposes no matter the passed size to avoid distorting the image via stretching
	NSSize	ownSize = [self size];

	//If we're passed a 0,0 size, use the image's size for the area taken up by the image 
	//(which may exceed the actual image dimensions)
	if(size.width == 0 || size.height == 0) size = ownSize;
	
	NSRect	drawRect = [self rectForDrawingInRect:rect atSize:size position:position];
	
	//If we are drawing in a rect wider than we are, center horizontally
	if (drawRect.size.width > ownSize.width){
		drawRect.origin.x += (drawRect.size.width - ownSize.width) / 2;
		drawRect.size.width -= (drawRect.size.width - ownSize.width);
	}

	//If we are drawing in a rect higher than we are, center vertically
	if (drawRect.size.height > ownSize.height){
		drawRect.origin.y += (drawRect.size.height - ownSize.height) / 2;
		drawRect.size.height -= (drawRect.size.height - ownSize.height);
	}

	//Draw
	[self drawInRect:drawRect
			fromRect:NSMakeRect(0, 0, ownSize.width, ownSize.height)
		   operation:NSCompositeSourceOver
			fraction:fraction];
	
	//Shift the origin if needed, and decrease the available destination rect width, by the passed size
	//(which may exceed the actual image dimensions)
	if(position == IMAGE_POSITION_LEFT) rect.origin.x += size.width;
	rect.size.width -= size.width;

	return(rect);
}

- (NSRect)rectForDrawingInRect:(NSRect)rect atSize:(NSSize)size position:(IMAGE_POSITION)position
{
	NSRect	drawRect;
	
	//If we're passed a 0,0 size, use the image's size
	if(size.width == 0 || size.height == 0) size = [self size];
	
	//Adjust
	switch(position){
		case IMAGE_POSITION_LEFT:
			drawRect = NSMakeRect(rect.origin.x,
								  rect.origin.y + (int)((rect.size.height - size.height) / 2.0),
								  size.width,
								  size.height);
		break;
		case IMAGE_POSITION_RIGHT:
			drawRect = NSMakeRect(rect.origin.x + rect.size.width - size.width,
								  rect.origin.y + (int)((rect.size.height - size.height) / 2.0),
								  size.width,
								  size.height);
		break;
		case IMAGE_POSITION_LOWER_LEFT:
			drawRect = NSMakeRect(rect.origin.x,
								  rect.origin.y + (rect.size.height - size.height),
								  size.width,
								  size.height);
		break;
		case IMAGE_POSITION_LOWER_RIGHT:
			drawRect = NSMakeRect(rect.origin.x + (rect.size.width - size.width),
								  rect.origin.y + (rect.size.height - size.height),
								  size.width,
								  size.height);
		break;
	}
	
	return(drawRect);
}

@end

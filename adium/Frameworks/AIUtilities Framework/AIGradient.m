/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2002, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
 | This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 | General Public License as published by the Free Software Foundation; either version 2 of the License,
 | or (at your option) any later version.
 |
 | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 | Public License for more details.
 |
 | You should have received a copy of the GNU General Public License along with this program; if not,
 | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 \------------------------------------------------------------------------------------------------------ */

#import "AIGradient.h"


@implementation AIGradient

//left to right gradient
+ (void)drawGradientInRect:(NSRect)rect from:(NSColor *)destColor to:(NSColor *)sourceColor
{ //(since we draw the gradient backwards, right to left, we swap the source and dest colors for the correct effect)
    int x,y;
    unsigned char *bitmap;
    NSBitmapImageRep	*myBitmapRep;

    int srcR, srcG, srcB, dstR, dstG, dstB;
    float redSkip, greenSkip, blueSkip;
    float red, green, blue;
    
    int	width;
    int	height;

    //Get color components
    sourceColor = [sourceColor colorUsingColorSpaceName:NSDeviceRGBColorSpace];
    destColor = [destColor colorUsingColorSpaceName:NSDeviceRGBColorSpace];
    srcR = [sourceColor redComponent]*255;
    srcG = [sourceColor greenComponent]*255;
    srcB = [sourceColor blueComponent]*255;
    dstR = [destColor redComponent]*255;
    dstG = [destColor greenComponent]*255;
    dstB = [destColor blueComponent]*255;
    

    myBitmapRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:nil
             pixelsWide:rect.size.width
             pixelsHigh:rect.size.height
             bitsPerSample:8
             samplesPerPixel:3
             hasAlpha:NO
             isPlanar:NO
             colorSpaceName:NSCalibratedRGBColorSpace
             bytesPerRow:0
             bitsPerPixel:24];

    bitmap = [myBitmapRep bitmapData];

    width = (int)rect.size.width;
    height = (int)rect.size.height;

    //Draw the first row
    redSkip = (float)(dstR - srcR) / (float)width;
    greenSkip = (float)(dstG - srcG) / (float)width;
    blueSkip = (float)(dstB - srcB) / (float)width;
    red = srcR;
    green = srcG;
    blue = srcB;
    
    x = (width * 3) - 1;
    while(x >= 0){
        bitmap[x--] = (int)blue;
        bitmap[x--] = (int)green;
        bitmap[x--] = (int)red;
        
        red += redSkip;
        green += greenSkip;
        blue += blueSkip;
    }
    
    //Copy the first row to all additional rows
    for(y = 1;y < height;y++){
        int offset = y * width * 3;
        
        x = (width * 3) - 1;
        while(x >= 0){
            bitmap[offset + x] = bitmap[x];
            x--;
        }
    }

    [myBitmapRep drawAtPoint:rect.origin];
    [myBitmapRep release];
}


/*
- (void)dealloc {
     [myBitmapRep release];
}

- (void)drawRect:(NSRect)rect {
     [myBitmapRep drawAtPoint:NSZeroPoint];
*/

@end

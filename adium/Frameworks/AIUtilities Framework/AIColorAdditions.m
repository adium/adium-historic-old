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

/*
    Utilities for creating a NSColor from a hex string representation, and storing colors as a string
*/

#import "AIColorAdditions.h"

int hexToInt(char hex);
char intToHex(int val);

@implementation NSString (AIColorAdditions)

- (NSColor *)hexColor
{
    const char	*hexString = [self cString];
    float 	red,green,blue;

    if(hexString[0] == '#'){
        red = ( hexToInt(hexString[1]) * 16 + hexToInt(hexString[2]) ) / 255.0;
        green = ( hexToInt(hexString[3]) * 16 + hexToInt(hexString[4]) ) / 255.0;
        blue = ( hexToInt(hexString[5]) * 16 + hexToInt(hexString[6]) ) / 255.0;
    }else{
        red = ( hexToInt(hexString[0]) * 16 + hexToInt(hexString[1]) ) / 255.0;
        green = ( hexToInt(hexString[2]) * 16 + hexToInt(hexString[3]) ) / 255.0;
        blue = ( hexToInt(hexString[4]) * 16 + hexToInt(hexString[5]) ) / 255.0;
    }
  
    return([NSColor colorWithCalibratedRed:red green:green blue:blue alpha:1.0]);
}

- (NSColor *)representedColor
{
    unsigned int	r, g, b;

    sscanf([self cString], "%d,%d,%d", &r,&g,&b);
    return([NSColor colorWithCalibratedRed:(r/255.0) green:(g/255.0) blue:(b/255.0) alpha:1.0]);
}

- (NSColor *)representedColorWithAlpha:(float)alpha
{
    unsigned int	r, g, b;

    sscanf([self cString], "%d,%d,%d", &r,&g,&b);
    return([NSColor colorWithCalibratedRed:(r/255.0) green:(g/255.0) blue:(b/255.0) alpha:alpha]);
}

@end

@implementation NSColor (AIColorAdditions)

//Returns YES if this color is dark
- (BOOL)colorIsDark
{
    return([[self colorUsingColorSpaceName:NSCalibratedRGBColorSpace] brightnessComponent] < 0.5);
}

//Percent should be -1.0 to 1.0 (negatives will make the color brighter)
- (NSColor *)darkenBy:(float)amount
{
    NSColor	*convertedColor = [self colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    
    return([NSColor colorWithCalibratedHue:[convertedColor hueComponent]
                                saturation:[convertedColor saturationComponent]
                                brightness:([convertedColor brightnessComponent] - amount)
                                     alpha:[convertedColor alphaComponent]]);
}

- (NSString *)hexString
{
    float 	red,green,blue;
    char	hexString[7];
    int		tempNum;
    NSColor	*convertedColor;

    convertedColor = [self colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    [convertedColor getRed:&red green:&green blue:&blue alpha:nil];
    
    tempNum = (red * 255) / 16;
    hexString[0] = intToHex(tempNum);
    hexString[1] = intToHex((red * 255) - (tempNum * 16));

    tempNum = (green * 255) / 16;
    hexString[2] = intToHex(tempNum);
    hexString[3] = intToHex((green * 255) - (tempNum * 16));

    tempNum = (blue * 255) / 16;
    hexString[4] = intToHex(tempNum);
    hexString[5] = intToHex((blue * 255) - (tempNum * 16));
    hexString[6] = '\0';
    
    return([NSString stringWithCString:hexString]);
}

- (NSString *)stringRepresentation
{
    NSColor	*tempColor = [self colorUsingColorSpaceName:@"NSCalibratedRGBColorSpace"];

    return(
	[NSString stringWithFormat:@"%d,%d,%d",
				    (int)([tempColor redComponent] * 255.0),
				    (int)([tempColor greenComponent] * 255.0),
				    (int)([tempColor blueComponent] * 255.0)
	]
    );
}

@end

int hexToInt(char hex){
    if(hex >= '0' && hex <= '9'){
        return (hex - '0');
    }else if(hex == 'A'){
        return 10;
    }else if(hex == 'B'){
        return 11;
    }else if(hex == 'C'){
        return 12;
    }else if(hex == 'D'){
        return 13;
    }else if(hex == 'E'){
        return 14;
    }else{
        return 15;
    }
}

char intToHex(int val){

    if(val < 10){
        return('0' + val);
    }else if(val == 10){
        return 'A';
    }else if(val == 11){
        return 'B';
    }else if(val == 12){
        return 'C';
    }else if(val == 13){
        return 'D';
    }else if(val == 14){
        return 'E';
    }else{
        return 'F';
    }
}


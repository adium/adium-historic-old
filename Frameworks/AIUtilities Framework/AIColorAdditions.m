/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2005, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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
#include <string.h>

float ONE_THIRD = 1.0/3.0;
float ONE_SIXTH = 1.0/6.0;
float TWO_THIRD = 2.0/3.0;

float min(float a, float b, float c);
float max(float a, float b, float c);
float _v(float m1, float m2, float hue);

@implementation NSString (AIColorAdditions)

- (NSColor *)hexColor
{
	const char	*hexString = [self UTF8String];
	float 	red,green,blue;
	float	alpha = 1.0;

	//skip # if present.
	if(*hexString == '#') ++hexString;
	size_t hexStringLength = strlen(hexString);

	NSAssert((hexStringLength == 3) || (hexStringLength == 4) || (hexStringLength == 6) || (hexStringLength == 8), @"-hexColor called on a string that cannot possibly be a hexadecimal color specification (e.g. #ff0000, #00b, #cc08)");

	//long specification:  #rrggbb[aa]
	//short specification: #rgb[a]
	//e.g. these all specify pure opaque blue: #0000ff #00f #0000ffff #00ff
	BOOL isLong = hexStringLength > 4;

	//for a long component c = 'xy':
	//	c = (x * 0x10 + y) / 0xff
	//for a short component c = 'x':
	//	c = x / 0xf

	red   = hexToInt(*(hexString++));
	if(isLong)   red = (  red * 16.0 + hexToInt(*(hexString++))) / 255.0;
	else   red /= 15.0;

	green = hexToInt(*(hexString++));
	if(isLong) green = (green * 16.0 + hexToInt(*(hexString++))) / 255.0;
	else green /= 15.0;

	blue  = hexToInt(*(hexString++));
	if(isLong)  blue = ( blue * 16.0 + hexToInt(*(hexString++))) / 255.0;
	else  blue /= 15.0;

	if(*hexString) {
		//we still have one more component to go: this is alpha.
		//without this component, alpha defaults to 1.0 (see initialiser above).
		alpha = hexToInt(*(hexString++));
		if(isLong) alpha = (alpha * 16.0 + hexToInt(*(hexString++))) / 255.0;
		else alpha /= 15.0;
	}

	return [NSColor colorWithCalibratedRed:red green:green blue:blue alpha:alpha];
}

- (NSColor *)representedColor
{
    unsigned int	r, g, b;
    unsigned int	a = 255;

	const char *selfUTF8 = [self UTF8String];
	
	//format: r,g,b[,a]
	//all components are decimal numbers 0..255.
	r = strtoul(selfUTF8, (char *)&selfUTF8, /*base*/ 10);
	++selfUTF8;
	g = strtoul(selfUTF8, (char *)&selfUTF8, /*base*/ 10);
	++selfUTF8;
	b = strtoul(selfUTF8, (char *)&selfUTF8, /*base*/ 10);
	if(*selfUTF8 == ',') {
		++selfUTF8;
		a = strtoul(selfUTF8, (char *)&selfUTF8, /*base*/ 10);
	}

    return [NSColor colorWithCalibratedRed:(r/255.0) green:(g/255.0) blue:(b/255.0) alpha:(a/255.0)] ;
}

- (NSColor *)representedColorWithAlpha:(float)alpha
{
	//this is the same as above, but the alpha component is overridden.

    unsigned int	r, g, b;

	const char *selfUTF8 = [self UTF8String];
	
	//format: r,g,b
	//all components are decimal numbers 0..255.
	r = strtoul(selfUTF8, (char *)&selfUTF8, /*base*/ 10);
	++selfUTF8;
	g = strtoul(selfUTF8, (char *)&selfUTF8, /*base*/ 10);
	++selfUTF8;
	b = strtoul(selfUTF8, (char *)&selfUTF8, /*base*/ 10);

    return [NSColor colorWithCalibratedRed:(r/255.0) green:(g/255.0) blue:(b/255.0) alpha:alpha];
}

@end

@implementation NSColor (AIColorAdditions)

//Returns the current system control tint, supporting 10.2
+ (NSControlTint)currentControlTintSupportingJag
{
    if([self respondsToSelector:@selector(currentControlTint)]){
		return [self currentControlTint];
    }else{
		NSNumber	*tintNum = [[NSUserDefaults standardUserDefaults] objectForKey:@"AppleAquaColorVariant"];
	
		if(!tintNum || [tintNum intValue] == 1){
			return NSBlueControlTint;
		}else{
			return NSGraphiteControlTint;
		}
    }
}

//Returns YES if the colors are equal
- (BOOL)equalToRGBColor:(NSColor *)inColor
{
    NSColor	*convertedA = [self colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    NSColor	*convertedB = [inColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    
    return(([convertedA redComponent]   == [convertedB redComponent])   &&
           ([convertedA blueComponent]  == [convertedB blueComponent])  &&
           ([convertedA greenComponent] == [convertedB greenComponent]));
}

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

- (NSColor *)darkenAndAdjustSaturationBy:(float)amount
{
    NSColor	*convertedColor = [self colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    
    return([NSColor colorWithCalibratedHue:[convertedColor hueComponent]
                                saturation:(([convertedColor saturationComponent] == 0.0) ? [convertedColor saturationComponent] : ([convertedColor saturationComponent] + amount))
                                brightness:([convertedColor brightnessComponent] - amount)
                                     alpha:[convertedColor alphaComponent]]);
}

//Linearly adjust a color
#define cap(x) { if(x < 0){x = 0;}else if(x > 1){x = 1;} }
- (NSColor *)adjustHue:(float)dHue saturation:(float)dSat brightness:(float)dBrit
{
    float hue, sat, brit, alpha;
    
    [self getHue:&hue saturation:&sat brightness:&brit alpha:&alpha];
    hue += dHue;
    cap(hue);
    sat += dSat;
    cap(sat);
    brit += dBrit;
    cap(brit);
    
    return([NSColor colorWithCalibratedHue:hue saturation:sat brightness:brit alpha:alpha]);
}


//Inverts the luminance of this color so it looks good on selected/dark backgrounds
- (NSColor *)colorWithInvertedLuminance
{
    float h,l,s;

    //Get our HLS
    [self getHue:&h luminance:&l saturation:&s];

    //Invert L
    l = 1.0 - l;

    //Return the new color
    return([NSColor colorWithCalibratedHue:h luminance:l saturation:s alpha:1.0]);
}

- (void)getHue:(float *)hue luminance:(float *)luminance saturation:(float *)saturation
{
    NSColor	*rgbColor;
    float	r, g, b;
    float	minValue, maxValue;
    
    //Get the current RGB values
    rgbColor = [self colorUsingColorSpaceName:NSDeviceRGBColorSpace];
	[rgbColor getRed:&r green:&g blue:&b alpha:NULL];

    //Determine the smallest and largest color component
    minValue = min(r, g, b);
    maxValue = max(r, g, b);

    //Calculate the luminance
	float lum = (minValue + maxValue) / 2.0f;

	if(luminance) *luminance = lum;

    //Special case for grays (They'll make us divide by zero below)
    if(minValue == maxValue)
	{
		if(hue)
			*hue = 0.0f;
		if(saturation)
			*saturation = 0.0f;
        return;
    }

    //Calculate Saturation
	if(saturation)
	{
		if(lum < 0.5f)
			*saturation = (maxValue - minValue) / (maxValue + minValue);
		else
			*saturation = (maxValue - minValue) / (2.0 - maxValue - minValue);
	}

	if(hue)
	{
		//Calculate hue
		r = (maxValue - r) / (maxValue - minValue);
		g = (maxValue - g) / (maxValue - minValue);
		b = (maxValue - b) / (maxValue - minValue);

		if(r == maxValue)
			*hue = b - g;
		else if(g == maxValue)
			*hue = 2.0f + r - b;
		else
			*hue = 4.0f + g - r;

		*hue = (*hue / 6.0f);// % 1.0f;

		//hue = hue % 1.0f
		while(*hue < 0.0f) *hue += 1.0f;
		while(*hue > 1.0f) *hue -= 1.0f;
	}
}

+ (NSColor *)colorWithCalibratedHue:(float)hue luminance:(float)luminance saturation:(float)saturation alpha:(float)alpha
{
    float r, g, b;
    float m1, m2;

    //Special case for grays
    if(saturation == 0){
        r = luminance;
        g = luminance;
        b = luminance;
        
    }else{
        //Generate some magic numbers
        if(luminance <= 0.5) m2 = luminance * (1.0 + saturation);
        else m2 = luminance + saturation - (luminance * saturation);
        m1 = 2.0 * luminance - m2;

        //Calculate the RGB
        r = _v(m1, m2, hue + ONE_THIRD);
        g = _v(m1, m2, hue);
        b = _v(m1, m2, hue - ONE_THIRD);
    }

    return([NSColor colorWithCalibratedRed:r green:g blue:b alpha:alpha]);
}

//??
float _v(float m1, float m2, float hue){

    //hue = hue % 1.0
    while(hue < 0.0) hue += 1.0;
    while(hue > 1.0) hue -= 1.0;
    
    if(hue < ONE_SIXTH) 	return( m1 + (m2 - m1) * hue * 6.0);
    else if(hue < 0.5) 		return( m2 );
    else if(hue < TWO_THIRD) 	return( m1 + (m2 - m1) * (TWO_THIRD - hue) * 6.0);
    else         		return( m1 );
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

//Returns the min of 3 values
float min(float a, float b, float c){
    if(a < b && a < c) return(a);
    if(b < a && b < c) return(b);
    return(c);
}

//Returns the max of 3 values
float max(float a, float b, float c){
    if(a > b && a > c) return(a);
    if(b > a && b > c) return(b);
    return(c);
}

//Convert hex to an int
int hexToInt(char hex)
{
    if(hex >= '0' && hex <= '9'){
        return(hex - '0');
    }else if(hex >= 'a' && hex <= 'f'){
        return(hex - 'a' + 10);
    }else if(hex >= 'A' && hex <= 'F'){
        return(hex - 'A' + 10);
    }else{
        return(0);
    }
}

//Convert int to a hex
char intToHex(int digit)
{
    if(digit > 9){
        return('a' + digit - 10);
    }else{
        return('0' + digit);
    }
}

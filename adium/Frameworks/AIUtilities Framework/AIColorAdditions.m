/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2003, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

float ONE_THIRD = 1.0/3.0;
float ONE_SIXTH = 1.0/6.0;
float TWO_THIRD = 2.0/3.0;

float min(float a, float b, float c);
float max(float a, float b, float c);
float _v(float m1, float m2, float hue);

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

//Returns the current system control tint, supporting 10.2
+ (NSControlTint)currentControlTintSupportingJag
{
    if([self respondsToSelector:@selector(currentControlTint)]){
	return([self currentControlTint]);

    }else{
	NSNumber	*tintNum = [[NSUserDefaults standardUserDefaults] objectForKey:@"AppleAquaColorVariant"];

	if(!tintNum || [tintNum intValue] == 1){
	    return(NSBlueControlTint);
	}else{
	    return(NSGraphiteControlTint);
	}
    }
}

//Returns YES if the colors are equal
- (BOOL)equalToRGBColor:(NSColor *)inColor
{
    NSColor	*convertedA = [self colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    NSColor	*convertedB = [inColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    
    return(([convertedA redComponent] == [convertedB redComponent]) &&
           ([convertedA blueComponent] == [convertedB blueComponent]) &&
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
    float	rc, gc, bc;
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

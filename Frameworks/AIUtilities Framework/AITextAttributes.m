/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2004, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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
    Holds attributes that can be applied to a block of text
*/

#import "AITextAttributes.h"
#define FONT_DEFAULT_NAME	@"Helvetica"

@interface AITextAttributes (PRIVATE)
- (id)initWithFontFamily:(NSString *)inFamilyName traits:(NSFontTraitMask)inTraits size:(int)inSize;
- (void)updateFont;
@end

@implementation AITextAttributes

//Creates a new instance of AITextAttributes
+ (id)textAttributesWithFontFamily:(NSString *)inFamilyName traits:(NSFontTraitMask)inTraits size:(int)inSize
{
    return([[[self alloc] initWithFontFamily:inFamilyName traits:inTraits size:inSize] autorelease]);
}

//init
- (id)initWithFontFamily:(NSString *)inFamilyName traits:(NSFontTraitMask)inTraits size:(int)inSize
{
    [self init];

    dictionary = [[NSMutableDictionary alloc] init];

    fontFamilyName = [inFamilyName retain];
    fontTraitsMask = inTraits;
    fontSize = inSize;

    [self updateFont];

    return(self);
}

- (id)init
{
	[super init];
	
	dictionary = nil;
	fontFamilyName = nil;
	fontTraitsMask = 0;
	fontSize = 0;
	
	return(self);
}

//dealloc
- (void)dealloc
{
    [dictionary release];
    [fontFamilyName release];

    [super dealloc];
}

- (id)copyWithZone:(NSZone *)zone
{
	AITextAttributes	*newTextAttributes = [[AITextAttributes alloc] init];

	newTextAttributes->dictionary = [dictionary mutableCopy];
	newTextAttributes->fontFamilyName = [fontFamilyName retain];
	newTextAttributes->fontTraitsMask = fontTraitsMask;
	newTextAttributes->fontSize = fontSize;

	return(newTextAttributes);
}

//Set the font family (name)
- (void)setFontFamily:(NSString *)inName
{
    if(fontFamilyName != inName){
        [fontFamilyName release];
        fontFamilyName = [inName retain];

		[self updateFont];
   }
}

//Set the font size
- (void)setFontSize:(int)inSize
{
	if(fontSize != inSize){
		fontSize = inSize;
		
		[self updateFont];
	}
}

//Set the text foreground color
- (void)setTextColor:(NSColor *)inColor
{
    [dictionary setObject:inColor forKey:NSForegroundColorAttributeName];
}

//Sub-backround color (drawn just behind the text)
- (void)setTextBackgroundColor:(NSColor *)inColor
{
    [dictionary setObject:inColor forKey:NSBackgroundColorAttributeName];
}

//Set the background color
- (void)setBackgroundColor:(NSColor *)inColor
{
    [dictionary setObject:inColor forKey:AIBodyColorAttributeName];
}

//Enable a masked trait (bold, italic)
- (void)enableTrait:(NSFontTraitMask)inTrait
{
    fontTraitsMask |= inTrait;

    [self updateFont];
}

//Disable a masked trait (bold, italic)
- (void)disableTrait:(NSFontTraitMask)inTrait
{
    if(fontTraitsMask && inTrait){
        fontTraitsMask ^= inTrait;
    }
    
    [self updateFont];
}

//Enable/Disable underlining
- (void)setUnderline:(BOOL)inUnderline
{
    if(inUnderline){
        [dictionary setObject:[NSNumber numberWithBool:inUnderline] forKey:NSUnderlineStyleAttributeName];
    }else{
        [dictionary removeObjectForKey:NSUnderlineStyleAttributeName];
    }
}

// Enable or disable strikethrough
- (void)setStrikethrough:(BOOL)inStrikethrough{
	if([NSApp isOnPantherOrBetter]){
		if(inStrikethrough){
			[dictionary setObject:[NSNumber numberWithBool:inStrikethrough] forKey:NSStrikethroughStyleAttributeName];
		}else{
			[dictionary removeObjectForKey:NSStrikethroughStyleAttributeName];
		}
	}
} 

// Enable or disable subscript
- (void)setSubscript:(BOOL)inSubscript{
	if(inSubscript){
		[dictionary setObject:[NSNumber numberWithFloat:(fontSize / -2.0f)] forKey:NSBaselineOffsetAttributeName];
		[self setFontSize:(fontSize - 2)];
		
		[self updateFont];
	}else{
		[dictionary removeObjectForKey:NSBaselineOffsetAttributeName];
		[self setFontSize:(fontSize + 2)];
	}
}

// Enable or disable superscript
- (void)setSuperscript:(BOOL)inSuperscript{
	if(inSuperscript){
		[dictionary setObject:[NSNumber numberWithFloat:(fontSize / 2.0f)] forKey:NSBaselineOffsetAttributeName];
		[self setFontSize:(fontSize - 2)];
		
		[self updateFont];
	}else {
		[dictionary removeObjectForKey:NSBaselineOffsetAttributeName];
		[self setFontSize:(fontSize + 2)];
	}
}

- (void)setLinkURL:(NSString *)inURL
{
    if(inURL){
        [dictionary setObject:inURL forKey:NSLinkAttributeName];
    }else{
        [dictionary removeObjectForKey:NSLinkAttributeName];
    }
}

//Returns a dictinary of attributes
- (NSDictionary *)dictionary
{
    return(dictionary);
}

//Updates the cached font
- (void)updateFont
{
    NSFont	*font = nil;

    //Ensure font size isn't 0
    if(!fontSize) fontSize = 12;

    //Create the font
    if(fontFamilyName){
		font = [[NSFontManager sharedFontManager] fontWithFamilyInsensitively:fontFamilyName traits:fontTraitsMask weight:5 size:fontSize];
    }
    
    //If no name was specified or the font is not available, use the default font
    if(!font){
        font = [[NSFontManager sharedFontManager] fontWithFamily:FONT_DEFAULT_NAME traits:fontTraitsMask weight:5 size:fontSize];
    }

    if(font){ //Just to be safe, incase the default font was unavailable for some reason
        [dictionary setObject:font forKey:NSFontAttributeName];
    }
}

@end

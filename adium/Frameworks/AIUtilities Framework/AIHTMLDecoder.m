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
    A quick and simple HTML to Attributed string converter
*/

#import "AIHTMLDecoder.h"
#import "AITextAttributes.h"
#import "AIAttributedStringAdditions.h"
#import "AIColorAdditions.h"

int HTMLEquivalentForFontSize(int fontSize);

@interface AIHTMLDecoder (PRIVATE)
+ (NSDictionary *)parseArguments:(NSString *)arguments;
+ (void)processFontTagArgs:(NSDictionary *)inArgs attributes:(AITextAttributes *)textAttributes;
+ (void)processBodyTagArgs:(NSDictionary *)inArgs attributes:(AITextAttributes *)textAttributes;
@end

@implementation AIHTMLDecoder

+ (NSString *)encodeHTML:(NSAttributedString *)inMessage
{
    NSMutableString	*string;
    NSFontManager	*fontManager = [NSFontManager sharedFontManager];
    NSString		*currentFamily;
    NSFont		*currentFont;
    BOOL		currentBold;
    BOOL		currentItalic;
    BOOL		currentUnderline;
    int			currentSize;
    NSString		*currentColor;
    NSString		*inMessageString;
    int			messageLength;
    NSRange		searchRange;
	short		loop;
    
    //Get the incoming message as a regular string, and it's length
    inMessageString = [inMessage string];
    messageLength = [inMessage length];
    
    //Setup the default attributes
    currentFont = nil;//[NSFont systemFontOfSize:12];
    currentFamily = [@"" retain];
    currentColor = [@"#000000" retain];
    currentSize = 0;
    currentBold = NO;
    currentItalic = NO;
    currentUnderline = NO;
    
    //Append the lead HTML tag
    string = [NSMutableString stringWithString:@"<HTML>"];

    //Loop through the entire string
    searchRange = NSMakeRange(0,0);
    while(searchRange.location < messageLength){
        NSDictionary	*attributes = [inMessage attributesAtIndex:searchRange.location effectiveRange:&searchRange];
        NSFont		*font = [attributes objectForKey:NSFontAttributeName];
        NSString	*color = [[attributes objectForKey:NSForegroundColorAttributeName] hexString];
        int		underline = [[attributes objectForKey:NSUnderlineStyleAttributeName] intValue];

        //font
        if(font && currentFont != font){ //Quick test to make sure it's not the same font
            NSString		*familyName = [font familyName];
            float		pointSize = [font pointSize];
            NSFontTraitMask	traits = [fontManager traitsOfFont:font];
            BOOL		bold = (traits & NSBoldFontMask);
            BOOL		italic = (traits & NSItalicFontMask);

            //Disable bold/italic/underline
            if(currentItalic && !italic){
                [string appendString:@"</I>"];
                currentItalic = bold;
            }
            if(currentBold && !bold){
                [string appendString:@"</B>"];
                currentBold = bold;
            }

            //Family
            if([familyName compare:currentFamily]){
                [string appendString:[NSString stringWithFormat:@"<FONT FACE=\"%@\" LANG=\"0\">",familyName]];
                [currentFamily release]; currentFamily = [familyName retain];
            }

            //Size
            if(pointSize != currentSize){
                [string appendString:[NSString stringWithFormat:@"<FONT ABSZ=%i SIZE=%i>",(int)pointSize,HTMLEquivalentForFontSize((int)pointSize)]];
                currentSize = pointSize;
            }
            
            //Bold
            if(bold && !currentBold){
                [string appendString:@"<B>"];
                currentBold = bold;
            }
            if(italic && !currentItalic){
                [string appendString:@"<I>"];
                currentItalic = italic;
            }
            
            
            [currentFont release]; currentFont = [font retain];
        }
            
        //color
        if(!color && currentColor){
            [string appendString:@"<FONT COLOR=\"#000000\">"];
            [currentColor release]; currentColor = nil;
        }else if([color compare:currentColor]){
            [string appendString:[NSString stringWithFormat:@"<FONT COLOR=\"#%@\">",color]];
            [currentColor release]; currentColor = [color retain];
        }

        //underline
        if(currentUnderline && !underline){
            [string appendString:@"</U>"];
        }else if(!currentUnderline && underline){
            [string appendString:@"<U>"];
        }
/*                
                currentUnderline = underline;
            
            }else if([key compare:NSParagraphStyleAttributeName] == 0){
            
            }else if([key compare:NSSuperscriptAttributeName] == 0){
            
            }else if([key compare:NSLinkAttributeName] == 0){
            
            }else if([key compare:NSBackgroundColorAttributeName] == 0){
            
            }else if([key compare:NSAttachmentAttributeName] == 0){
    
            }
        }
  */
        //Append the string, escaping additional characters for HTML.
        loop = searchRange.location;
        while (loop < (searchRange.location + searchRange.length))
        {
            long currentChar = [inMessageString characterAtIndex:loop];

            if(currentChar == 60){ //replace less-than's (<) with their HTML code (&lt;)
                [string appendString:@"&lt;"];
                
            }else if(currentChar == 62){ //replace greater-than's (>) with their HTML code (&gt;)
                [string appendString:@"&gt;"];
                
            }else if(currentChar == '&'){ //replace with (&amp;) (breaks links, but we'll deal with that later)
                [string appendString:@"&amp;"];

            }else{
                [string appendFormat:@"%c", currentChar];

            }
            loop++;
        }
		
        searchRange.location += searchRange.length;
    }

    [currentFamily release];
    [currentColor release];
    [currentFont release];

    [string appendString:@"</HTML>"];

    return(string);
}

int HTMLEquivalentForFontSize(int fontSize)
{
    if(fontSize <= 9){
        return(1);
    }else if(fontSize <= 10){
        return(2);
    }else if(fontSize <= 12){
        return(3);
    }else if(fontSize <= 14){
        return(4);
    }else if(fontSize <= 18){
        return(5);
    }else if(fontSize <= 24){
        return(6);
    }else{
        return(7);
    }
}



+ (NSAttributedString *)decodeHTML:(NSString *)inMessage
{
    NSScanner			*scanner;
    NSCharacterSet		*tagCharStart, *tagEnd, *charEnd, *absoluteTagEnd;
    NSString			*chunkString, *tagOpen;
    NSMutableAttributedString	*attrString;
    AITextAttributes		*textAttributes;
    int				asciiChar;
    
    //set up
    textAttributes = [AITextAttributes textAttributesWithFontFamily:@"Helvetica" traits:0 size:12];
    attrString = [[NSMutableAttributedString alloc] init];

    tagCharStart = [NSCharacterSet characterSetWithCharactersInString:@"<&"];
    tagEnd = [NSCharacterSet characterSetWithCharactersInString:@" >"];
    charEnd = [NSCharacterSet characterSetWithCharactersInString:@";"];
    absoluteTagEnd = [NSCharacterSet characterSetWithCharactersInString:@">"];

    scanner = [NSScanner scannerWithString:inMessage];
    [scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@""]];

    //Parse the HTML
    while(![scanner isAtEnd]){
        //Find an HTML tag or escaped character
        if([scanner scanUpToCharactersFromSet:tagCharStart intoString:&chunkString]){
            [attrString appendString:chunkString withAttributes:[textAttributes dictionary]];
        }

        //Process the tag
        if([scanner scanCharactersFromSet:tagCharStart intoString:&tagOpen]){ //If a tag wasn't found, we don't process.
            unsigned 	scanLocation = [scanner scanLocation]; //Remember our location (if this is an invalid tag we'll need to move back)

            if([tagOpen compare:@"<"] == 0){ // HTML <tag>
                BOOL validTag = [scanner scanUpToCharactersFromSet:tagEnd intoString:&chunkString]; //Get the tag
                if(validTag){ 
                    //HTML
                    if([chunkString caseInsensitiveCompare:@"HTML"] == 0){
                        //ignore
                    }else if([chunkString caseInsensitiveCompare:@"/HTML"] == 0){
                        //ignore

                    //LINK
                    }else if([chunkString caseInsensitiveCompare:@"A"] == 0){
                        [textAttributes setLinkURL:@"http://www.adiumx.com"];
                        [textAttributes setUnderline:YES];
                        [textAttributes setTextColor:[NSColor blueColor]];

                        //Ignore any arguments (for now)
                        [scanner scanUpToCharactersFromSet:absoluteTagEnd intoString:&chunkString];

                    }else if([chunkString caseInsensitiveCompare:@"/A"] == 0){
                        [textAttributes setLinkURL:nil];
                        [textAttributes setUnderline:NO];
                        [textAttributes setTextColor:[NSColor blackColor]];

                    //Body
                    }else if([chunkString caseInsensitiveCompare:@"BODY"] == 0){
                        if([scanner scanUpToCharactersFromSet:absoluteTagEnd intoString:&chunkString]){
                            [self processBodyTagArgs:[self parseArguments:chunkString] attributes:textAttributes]; //Process the font tag's contents
                        }

                    }else if([chunkString caseInsensitiveCompare:@"/BODY"] == 0){
                        //ignore

                    //Font
                    }else if([chunkString caseInsensitiveCompare:@"FONT"] == 0){
                        if([scanner scanUpToCharactersFromSet:absoluteTagEnd intoString:&chunkString]){
                            [self processFontTagArgs:[self parseArguments:chunkString] attributes:textAttributes]; //Process the font tag's contents
                        }
                        
                    }else if([chunkString caseInsensitiveCompare:@"/FONT"] == 0){
                        //ignore

                    //Line Break
                    }else if([chunkString caseInsensitiveCompare:@"BR"] == 0){
                        [attrString appendString:@"\r" withAttributes:nil];

                    //Bold
                    }else if([chunkString caseInsensitiveCompare:@"B"] == 0){
                        [textAttributes enableTrait:NSBoldFontMask];
                    }else if([chunkString caseInsensitiveCompare:@"/B"] == 0){
                        [textAttributes disableTrait:NSBoldFontMask];

                    //Italic
                    }else if([chunkString caseInsensitiveCompare:@"I"] == 0){
                        [textAttributes enableTrait:NSItalicFontMask];
                    }else if([chunkString caseInsensitiveCompare:@"/I"] == 0){
                        [textAttributes disableTrait:NSItalicFontMask];

                    //Underline
                    }else if([chunkString caseInsensitiveCompare:@"U"] == 0){
                        [textAttributes setUnderline:YES];
                    }else if([chunkString caseInsensitiveCompare:@"/U"] == 0){
                        [textAttributes setUnderline:NO];

                    //Invalid
                    }else{
                        validTag = NO;
                    }
                }

                if(validTag){ //Skip over the end tag character '>'
                    [scanner setScanLocation:[scanner scanLocation]+1];
                }else{
                    //When an invalid tag is encountered, we add the <, and then move our scanner back to continue processing
                    [attrString appendString:@"<" withAttributes:[textAttributes dictionary]];
                    [scanner setScanLocation:scanLocation];
                }

            }else if([tagOpen compare:@"&"] == 0){ // escape character, eg &gt;
                BOOL validTag = [scanner scanUpToCharactersFromSet:charEnd intoString:&chunkString];

                if(validTag){
                    // We could upgrade this to use an NSDictionary with lots of chars
                    // but for now, if-blocks will do
                    if ([chunkString caseInsensitiveCompare:@"GT"] == 0){
                        [attrString appendString:@">" withAttributes:[textAttributes dictionary]];
                        
                    }else if ([chunkString caseInsensitiveCompare:@"LT"] == 0){
                        [attrString appendString:@"<" withAttributes:[textAttributes dictionary]];

                    }else if ([chunkString caseInsensitiveCompare:@"AMP"] == 0){
                        [attrString appendString:@"&" withAttributes:[textAttributes dictionary]];

                    }else if ([chunkString caseInsensitiveCompare:@"QUOT"] == 0){
                        [attrString appendString:@"\"" withAttributes:[textAttributes dictionary]];

                    }else if ([chunkString caseInsensitiveCompare:@"NBSP"] == 0){
                        [attrString appendString:@"Ê" withAttributes:[textAttributes dictionary]];
                        
                    }else if ((sscanf([chunkString cString], "#%i", &asciiChar)) == 1){//Using scanf for now; I don't know a good Cocoa way to quickly do this
                        [attrString appendString:[NSString stringWithFormat:@"%c", asciiChar] withAttributes:[textAttributes dictionary]];
                        
                    }else{ //Invalid
                        validTag = NO;
                    }                    
                }

                
                if(validTag){ //Skip over the end tag character ';'
                    [scanner scanCharactersFromSet:charEnd intoString:nil];
                }else{
                    //When an invalid tag is encountered, we add the &, and then move our scanner back to continue processing
                    [attrString appendString:@"&" withAttributes:[textAttributes dictionary]];
                    [scanner setScanLocation:scanLocation];
                }
                
            }else{ //Invalid tag character (most likely a stray < or &)
                if([tagOpen length] > 1){
                    //If more than one character was scanned, add the first one, and move the scanner back to re-process the additional characters
                    [attrString appendString:[tagOpen substringToIndex:1] withAttributes:[textAttributes dictionary]];
                    [scanner setScanLocation:[scanner scanLocation] - ([tagOpen length]-1)]; 
                    
                }else{
                    [attrString appendString:tagOpen withAttributes:[textAttributes dictionary]];

                }
            }
        }
    }

    return([attrString autorelease]);
}

//Process the contents of a font tag
+ (void)processFontTagArgs:(NSDictionary *)inArgs attributes:(AITextAttributes *)textAttributes
{
    NSEnumerator 	*enumerator;
    NSString		*arg;

    enumerator = [[inArgs allKeys] objectEnumerator];
    while((arg = [enumerator nextObject])){
        if([arg caseInsensitiveCompare:@"FACE"] == 0){
            [textAttributes setFontFamily:[inArgs objectForKey:arg]];

        }else if([arg caseInsensitiveCompare:@"SIZE"] == 0){
            int	size;

            //Always prefer an ABSZ to a size
            if(![inArgs objectForKey:@"ABSZ"] && ![inArgs objectForKey:@"absz"]){
                switch([[inArgs objectForKey:arg] intValue]){
                    case 1: size = 9; break;
                    case 2: size = 10; break;
                    case 3: size = 12; break;
                    case 4: size = 14; break;
                    case 5: size = 18; break;
                    case 6: size = 24; break;
                    case 7: size = 48; break;
                    case 8: size = 72; break;
                    default: size = 12; break;
                }
                [textAttributes setFontSize:size];
            }

        }else if([arg caseInsensitiveCompare:@"ABSZ"] == 0){
            [textAttributes setFontSize:[[inArgs objectForKey:arg] intValue]];

        }else if([arg caseInsensitiveCompare:@"COLOR"] == 0){
            [textAttributes setTextColor:[[inArgs objectForKey:arg] hexColor]];
        }
    }
}

+ (void)processBodyTagArgs:(NSDictionary *)inArgs attributes:(AITextAttributes *)textAttributes
{
    NSEnumerator 	*enumerator;
    NSString		*arg;

    enumerator = [[inArgs allKeys] objectEnumerator];
    while((arg = [enumerator nextObject])){
        if([arg caseInsensitiveCompare:@"BGCOLOR"] == 0){
            [textAttributes setBackgroundColor:[[inArgs objectForKey:arg] hexColor]];
        }
    }

}


+ (NSDictionary *)parseArguments:(NSString *)arguments
{
    NSMutableDictionary	*argDict;
    NSScanner		*scanner;
    NSCharacterSet	*equalsSet, *quoteSet, *spaceSet;
    NSString		*key, *value;

    //Setup
    equalsSet = [NSCharacterSet characterSetWithCharactersInString:@"="];
    quoteSet = [NSCharacterSet characterSetWithCharactersInString:@"\""];
    spaceSet = [NSCharacterSet characterSetWithCharactersInString:@" "];
    scanner = [NSScanner scannerWithString:arguments];
    argDict = [[NSMutableDictionary alloc] init];
    
    while(![scanner isAtEnd]){
        //Find a tag
        [scanner scanUpToCharactersFromSet:equalsSet intoString:&key];
        [scanner scanCharactersFromSet:equalsSet intoString:nil];
        
        //check for quotes
        if([scanner scanCharactersFromSet:quoteSet intoString:nil]){
            [scanner scanUpToCharactersFromSet:quoteSet intoString:&value];
            [scanner scanCharactersFromSet:quoteSet intoString:nil];           
        }else{
            [scanner scanUpToCharactersFromSet:spaceSet intoString:&value];
        }

        //Store in dict
        [argDict setObject:value forKey:key];
    }
    
    return([argDict autorelease]);
}

@end

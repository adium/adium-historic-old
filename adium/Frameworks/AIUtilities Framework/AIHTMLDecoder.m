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
                [string appendCharacter:currentChar]; //!! Undocumented / Private method !!

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
    NSCharacterSet		*tagStart, *tagEnd, *absoluteTagEnd;
    NSString			*chunkString;
    NSMutableAttributedString	*attrString;
    AITextAttributes		*textAttributes;
    int				tagType;

    //set up
    textAttributes = [AITextAttributes textAttributesWithFontFamily:@"Helvetica" traits:0 size:12];
    attrString = [[NSMutableAttributedString alloc] init];

    tagStart = [NSCharacterSet characterSetWithCharactersInString:@"<"];
    tagEnd = [NSCharacterSet characterSetWithCharactersInString:@" >"];
    absoluteTagEnd = [NSCharacterSet characterSetWithCharactersInString:@">"];

    scanner = [NSScanner scannerWithString:inMessage];
    [scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@""]];

    //Parse the HTML
    while(![scanner isAtEnd]){
        //Find a tag
        if([scanner scanUpToCharactersFromSet:tagStart intoString:&chunkString]){        
            [attrString appendString:chunkString withAttributes:[textAttributes dictionary]];
        }
        [scanner scanCharactersFromSet:tagStart intoString:nil];
        
        //Get the tag type
        tagType = 0;
        if([scanner scanUpToCharactersFromSet:tagEnd intoString:&chunkString]){
            //HTML
            if([chunkString caseInsensitiveCompare:@"HTML"] == 0){
                //ignore
            }else if([chunkString caseInsensitiveCompare:@"/HTML"] == 0){
                //ignore

            //A LINK
            }else if([chunkString caseInsensitiveCompare:@"A"] == 0){
                [textAttributes setUnderline:YES];
                [textAttributes setTextColor:[NSColor blueColor]];
                
            }else if([chunkString caseInsensitiveCompare:@"/A"] == 0){
                [textAttributes setUnderline:NO];
                [textAttributes setTextColor:[NSColor blackColor]];

            //Body
            }else if([chunkString caseInsensitiveCompare:@"BODY"] == 0){
            }else if([chunkString caseInsensitiveCompare:@"/BODY"] == 0){
            
            //Font
            }else if([chunkString caseInsensitiveCompare:@"FONT"] == 0){
                tagType = 1;
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
                tagType = -1;
                [attrString appendString:@"<" withAttributes:[textAttributes dictionary]];
                [attrString appendString:chunkString withAttributes:[textAttributes dictionary]];
            }
        }

        //Get the tag contents
        if(tagType != -1){
            if(![scanner scanCharactersFromSet:absoluteTagEnd intoString:nil]){
                if([scanner scanUpToCharactersFromSet:absoluteTagEnd intoString:&chunkString]){
                    NSDictionary	*argDict;
                    NSArray		*keys;
                    int			loop;
                
                    //Get the args
                    argDict = [self parseArguments:chunkString];
                    keys = [argDict allKeys];

                    //Parse the args                  
                    switch(tagType){
                        case 1: //Font
                            for(loop = 0;loop < [keys count];loop++){
                                NSString *arg = [keys objectAtIndex:loop];
                                
                                if([arg caseInsensitiveCompare:@"FACE"] == 0){
                                    [textAttributes setFontFamily:[argDict objectForKey:arg]];

                                }else if([arg caseInsensitiveCompare:@"SIZE"] == 0){
                                    int	size;
                                
                                    //Always prefer an ABSZ to a size
                                    if(![keys containsObject:@"ABSZ"] && ![keys containsObject:@"absz"]){
                                        switch([[argDict objectForKey:arg] intValue]){
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
                                    [textAttributes setFontSize:[[argDict objectForKey:arg] intValue]];
                                    
                                }else if([arg caseInsensitiveCompare:@"COLOR"] == 0){
                                    [textAttributes setTextColor:[[argDict objectForKey:arg] hexColor]];
                                }
                            }
                        break;
                        default:
                        break;
                    }
                }
                [scanner scanCharactersFromSet:absoluteTagEnd intoString:nil];
            }
        }
    }
    
    return([attrString autorelease]);
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

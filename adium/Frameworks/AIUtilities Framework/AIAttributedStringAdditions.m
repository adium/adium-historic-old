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
 Some useful additions for attributed strings
 */

#import "AIAttributedStringAdditions.h"

NSAttributedString *_safeString(NSAttributedString *inString);

@implementation NSMutableAttributedString (AIAttributedStringAdditions)

//Append a plain string, adding the specified attributes
- (void)appendString:(NSString *)aString withAttributes:(NSDictionary *)attrs
{
    NSAttributedString	*tempString;

    if(attrs){
        tempString = [[NSAttributedString alloc] initWithString:aString attributes:attrs];
    }else{
        tempString = [[NSAttributedString alloc] initWithString:aString];
    }

    [self appendAttributedString:tempString];
    [tempString release];
}

- (NSData *)dataRepresentation
{
    return([self RTFFromRange:NSMakeRange(0,[self length]) documentAttributes:nil]);
}

- (NSAttributedString *)safeString
{
    return(_safeString((NSAttributedString *)self));
}

- (unsigned int)replaceOccurrencesOfString:(NSString *)target withString:(NSString*)replacement options:(unsigned)opts range:(NSRange)searchRange
{
    NSRange theRange;
    int numberOfReplacements = 0;
    
    while ( (theRange = [[self string] rangeOfString:target options:opts range:searchRange]).location != NSNotFound ) {
        NSLog(@"begin: %@ %i %i ; %i %i",[self string],searchRange.location,searchRange.length,theRange.location);
        [self replaceCharactersInRange:theRange withString:replacement];
        numberOfReplacements++;
        searchRange.length = searchRange.length - ((theRange.location + theRange.length) - searchRange.location);
        
        searchRange.location = theRange.location + theRange.length;
        if (searchRange.length - searchRange.location < 1)
            break;
        NSLog(@"end: %@ %i %i",[self string],searchRange.location,searchRange.length);
    }
    NSLog(@"%i replacements",numberOfReplacements);
    return numberOfReplacements;
}

@end

@implementation NSAttributedString (AIAttributedStringAdditions)

- (float)heightWithWidth:(float)width
{
    NSTextStorage 	*textStorage;
    NSTextContainer 	*textContainer;
    NSLayoutManager 	*layoutManager;

    //Setup the layout manager and text container
    textStorage = [[[NSTextStorage alloc] initWithAttributedString:self] autorelease];
    textContainer = [[[NSTextContainer alloc] initWithContainerSize:NSMakeSize(width, 1e7)] autorelease];
    layoutManager = [[[NSLayoutManager alloc] init] autorelease];

    //Configure
    [textContainer setLineFragmentPadding:0.0];
    [layoutManager addTextContainer:textContainer];
    [textStorage addLayoutManager:layoutManager];

    //Force the layout manager to layout its text
    (void)[layoutManager glyphRangeForTextContainer:textContainer];

    return([layoutManager usedRectForTextContainer:textContainer].size.height);
}

- (NSData *)dataRepresentation
{
    return([self RTFFromRange:NSMakeRange(0,[self length]) documentAttributes:nil]);
}

+ (NSAttributedString *)stringWithData:(NSData *)inData
{
    return([[[NSAttributedString alloc] initWithRTF:inData documentAttributes:nil] autorelease]);
}

- (NSAttributedString *)safeString
{
    return(_safeString(self));
}

@end

//Separated out to avoid code duplication
NSAttributedString *_safeString(NSAttributedString *inString)
{
    if([inString containsAttachments]){
        NSMutableAttributedString *safeString = [inString mutableCopy];
        int currentLocation = 0;
        NSRange attachmentRange;

        //find attachment
        attachmentRange = [[safeString string] rangeOfString:[NSString stringWithFormat:@"%C",NSAttachmentCharacter] options:0 range:NSMakeRange(currentLocation,[safeString length] - currentLocation)];

        while(attachmentRange.length != 0){ //if we found an attachment

            NSString *replacement = [[safeString attribute:NSAttachmentAttributeName atIndex:attachmentRange.location effectiveRange:nil] string];

            if(replacement == nil){
                replacement = [NSString stringWithString:@"<<NSAttachment>>"];
            }

            //remove the attachment, replacing it with the original text
            [safeString replaceCharactersInRange:attachmentRange withString:replacement];

            attachmentRange.length = [replacement length];

            currentLocation = attachmentRange.location + attachmentRange.length;

            //find the next attachment
            attachmentRange = [[safeString string] rangeOfString:[NSString stringWithFormat:@"%C",NSAttachmentCharacter] options:0 range:NSMakeRange(currentLocation,[safeString length] - currentLocation)];
        }

        return safeString;

    }else{
        return inString;

    }
}

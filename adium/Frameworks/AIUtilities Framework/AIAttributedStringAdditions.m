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
    Some useful additions for attributed strings
*/

#import "AIAttributedStringAdditions.h"


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

@end




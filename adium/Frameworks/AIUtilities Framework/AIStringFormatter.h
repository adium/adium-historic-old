//
//  AIStringFormatter.h
//  Adium
//
//  Created by Adam Iser on Sun Feb 09 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AIStringFormatter : NSFormatter {
    NSCharacterSet	*characters;
    int			length;
    BOOL		caseSensitive;

    NSString		*errorMessage;
    int			errorCount;
}

+ (id)stringFormatterAllowingCharacters:(NSCharacterSet *)inCharacters length:(int)inLength caseSensitive:(BOOL)inCaseSensitive errorMessage:(NSString *)errorMessage;

@end

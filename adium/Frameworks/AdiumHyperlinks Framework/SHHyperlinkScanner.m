//
//  SHHyperlinkScanner.m
//  Adium


#import "SHLinkLexer.h"
#import "SHMarkedHyperlink.h"
#import "SHHyperlinkScanner.h"

@implementation SHHyperlinkScanner

#pragma mark Init
-(id)init
{
    useStrictChecking = YES;
    SHStringOffset = 0;
    [super init];
    
    return self;
}

-(id)initWithStrictChecking:(BOOL)flag
{
    useStrictChecking = flag;
    SHStringOffset = 0;
    [super init];
    
    return self;
}

#pragma mark utility
-(void)setStrictChecking:(BOOL)flag
{
    useStrictChecking = flag;
}

-(BOOL)isStrictCheckingEnabled
{
    return useStrictChecking;
}

-(URI_VERIFICATION_STATUS)validationStatus
{
    return validStatus;
}
#pragma mark primative methods

// method to determine the validity of a given string, only place where flex is called
-(BOOL)isStringValidURL:(NSString *)inString
{
    validStatus = SH_URL_INVALID;
    SH_BUFFER_STATE buf;
    
    buf = SH_scan_string([inString UTF8String]);
        
    validStatus = SHlex();
    if(validStatus == SH_URL_VALID || validStatus == SH_MAILTO_VALID || validStatus == SH_FILE_VALID){
        SH_delete_buffer(buf);
        buf = NULL;
        return YES;
    }else if((validStatus == SH_URL_DEGENERATE || validStatus == SH_MAILTO_DEGENERATE) && !useStrictChecking){
        SH_delete_buffer(buf);
        buf = NULL;
        return YES;
    }else{
        SH_delete_buffer(buf);
        buf = NULL;
        return NO;
    }
}

-(SHMarkedHyperlink *)nextURLFromString:(NSString *)inString
{
    NSString    *scanString = [[NSString alloc] init];
    int location = SHStringOffset;
    
    //scan upto the next whitespace char so that we don't unnecessarity confuse flex
    // otherwise we end up validating urls that look like this "http://www.adiumx.com/ <--cool"
    NSScanner *preScanner = [[[NSScanner alloc] initWithString:inString] autorelease];
    [preScanner setScanLocation:location];
    while([preScanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:&scanString]){
        SHStringOffset = [preScanner scanLocation] - [scanString length];
        
        if([self isStringValidURL:scanString]){
            NSRange urlRange = NSMakeRange([preScanner scanLocation] - [scanString length],[scanString length]);
            
            NSMutableString    *newURL = [NSMutableString stringWithString:scanString];
            
            //insert typical specifiers if the URL is degenerate
            switch(validStatus){
                case SH_URL_DEGENERATE:
                    [newURL insertString:@"http://" atIndex:0];
                    break;
                case SH_MAILTO_DEGENERATE:
                    [newURL insertString:@"mailto:" atIndex:0];
                    break;
                default:
                    break;
            }
            
            //make a marked link
            SHMarkedHyperlink *markedLink = [[[SHMarkedHyperlink alloc] initWithString:newURL
                                                                 withValidationStatus:validStatus
                                                                         parentString:inString
                                                                             andRange:urlRange] autorelease];
            return markedLink;
        }
        
        location = SHStringOffset;
    }
    //if we're here, then NSScanner hit the end of the string
    //- set it to the string length here so we avoid potentail infinite looping with many trailing spaces.
    SHStringOffset = [inString length];
    return nil;
}

#pragma mark string and textview handleing

//fetch all the URL's from a string
-(NSArray *)allURLsFromString:(NSString *)inString
{
    SHStringOffset = 0;
    NSMutableArray *rangeArray = [[[NSMutableArray alloc] init] autorelease];
    SHMarkedHyperlink *markedLink = nil;
    
    //build an array of marked links.
    while([inString length] > SHStringOffset){
        if(markedLink = [self nextURLFromString:inString]){
            [rangeArray addObject:markedLink];
        }
    }
    
    if([rangeArray count] > 0){
        return (NSArray *)rangeArray;
    }else{
        return nil;
    }
}

-(NSArray *)allURLsFromTextView:(NSTextView *)inView
{
    return [self allURLsFromString:[inView string]];
}

//scan an attributed string for URL's, then give them the proper link attribs.
-(NSAttributedString *)linkifyString:(NSAttributedString *)inString
{
    NSArray *rangeArray = [self allURLsFromString:[inString string]];
    NSEnumerator *enumerator = [rangeArray objectEnumerator];
    SHMarkedHyperlink *markedLink;
    
    
    NSMutableAttributedString *newString = [[[NSMutableAttributedString alloc] initWithAttributedString:inString] autorelease];
    
    while(markedLink = [enumerator nextObject]){
        NSRange linkRange = [markedLink range];
        if([markedLink URL]){
            [newString addAttribute:NSLinkAttributeName value:[[markedLink URL] retain] range:linkRange];
        }
    }
    
    return newString;
}

// scan a textView for URL's, as above
-(void)linkifyTextView:(NSTextView *)inView
{
    NSMutableAttributedString *newView;
    
    newView = [[[NSMutableAttributedString alloc] initWithAttributedString:
                                                [self linkifyString:
                                                [inView attributedSubstringFromRange:
                                                NSMakeRange(0,[[inView string] length])]]] autorelease];
                                                
    [[inView textStorage] setAttributedString:newView];
}
@end

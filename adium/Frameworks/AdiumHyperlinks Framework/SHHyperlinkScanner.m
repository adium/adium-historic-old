//
//  SHHyperlinkScanner.m
//  Adium


#import "SHLinkLexer.h"
#import "SHMarkedHyperlink.h"
#import "SHHyperlinkScanner.h"

@implementation SHHyperlinkScanner

#pragma mark Init
//default initializer - use strict checking by default
-(id)init
{
    useStrictChecking = YES;
    SHStringOffset = 0;
    [super init];
    
    return self;
}

//init with a user specified value for strict checking
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
    validStatus = SH_URL_INVALID; // assume the URL is invalid
    SH_BUFFER_STATE buf;  // buffer for flex to scan from

    // initialize the buffer (flex automatically switches to the buffer in this function)
    buf = SH_scan_string([inString UTF8String]);

    // call flex to parse the input
    validStatus = SHlex();
    
    // condition for valid URI's
    if(validStatus == SH_URL_VALID || validStatus == SH_MAILTO_VALID || validStatus == SH_FILE_VALID){
        SH_delete_buffer(buf); //remove the buffer from flex.
        buf = NULL; //null the buffer pointer for safty's sake.
        
        // check that the whole string was matched by flex.
        // this prevents silly things like "blah...com" from being seen as links
        if(SHleng == [inString length]){
            return YES;
        }
    // condition for degenerate URL's (A.K.A. URI's sans specifiers), requres strict checking to be NO.
    }else if((validStatus == SH_URL_DEGENERATE || validStatus == SH_MAILTO_DEGENERATE) && !useStrictChecking){
        SH_delete_buffer(buf);
        buf = NULL;
        if(SHleng == [inString length]){
            return YES;
        }
    // if it ain't vaild, and it ain't degenerate, then it's invalid.
    }else{
        SH_delete_buffer(buf);
        buf = NULL;
        return NO;
    }
    // default case, if the range checking above fails.
    return NO;
}

-(SHMarkedHyperlink *)nextURLFromString:(NSString *)inString
{
    NSString    *scanString = [[NSString alloc] init];
    int location = SHStringOffset; //get our location from SHStringOffset, so we can pick up where we left off.
    NSMutableCharacterSet *skipSet = [[NSMutableCharacterSet alloc] init];
    [skipSet formUnionWithCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [skipSet formUnionWithCharacterSet:[NSCharacterSet illegalCharacterSet]];
    [skipSet formUnionWithCharacterSet:[NSCharacterSet controlCharacterSet]];
    [skipSet formUnionWithCharacterSet:[NSCharacterSet characterSetWithCharactersInString:@",\"'"]];
    
    // scan upto the next whitespace char so that we don't unnecessarity confuse flex
    // otherwise we end up validating urls that look like this "http://www.adiumx.com/ <--cool"
    NSScanner *preScanner = [[[NSScanner alloc] initWithString:inString] autorelease];
    [preScanner setCharactersToBeSkipped:skipSet];
    [preScanner setScanLocation:location];
    while([preScanner scanUpToCharactersFromSet:skipSet intoString:&scanString]){
        SHStringOffset = [preScanner scanLocation] - [scanString length];
        
        // if we have a valid URL then save the scanned string, and make a SHMarkedHyperlink out of it.
        // this way, we can preserve things like the matched string (to be converted to a NSURL),
        // parent string, it's validation status (valid, file, degenerate, etc), and it's range in the parent string
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
        //step location after scanning a string
        location = SHStringOffset;
    }
    // if we're here, then NSScanner hit the end of the string
    // set SHStringOffset to the string length here so we avoid potential infinite looping with many trailing spaces.
    SHStringOffset = [inString length];
    return nil;
}

#pragma mark string and textview handleing

//fetch all the URL's from a string
-(NSArray *)allURLsFromString:(NSString *)inString
{
    SHStringOffset = 0; //set the offset to 0.
    NSMutableArray *rangeArray = [[[NSMutableArray alloc] init] autorelease];
    SHMarkedHyperlink *markedLink = nil;
    
    //build an array of marked links.
    while([inString length] > SHStringOffset){
        if(markedLink = [self nextURLFromString:inString]){
            [rangeArray addObject:markedLink];
        }
    }
    
    //return the array if it has elements, otherwise nil.
    if([rangeArray count] > 0){
        return rangeArray;
    }else{
        return nil;
    }
}

// fetch all the URL's form a text view
-(NSArray *)allURLsFromTextView:(NSTextView *)inView
{
    // since a NSTextView is really just a glorified NSMutableAttributedString,
    // we can take the string and send it out to allURLsFromString:
    return [self allURLsFromString:[inView string]];
}

//scan an attributed string for URL's, then give them the proper link attribs.
-(NSAttributedString *)linkifyString:(NSAttributedString *)inString
{
    //build an array from the input string and get its obj. enumerator
    NSArray *rangeArray = [self allURLsFromString:[inString string]];
    NSEnumerator *enumerator = [rangeArray objectEnumerator];
    SHMarkedHyperlink *markedLink;
    
    //create a new mutable string
    NSMutableAttributedString *newString = [[[NSMutableAttributedString alloc] initWithAttributedString:inString] autorelease];
    
    //for each SHMarkedHyperlink, add the proper URL to the proper range in the string.
    while(markedLink = [enumerator nextObject]){
        NSRange linkRange = [markedLink range];
        if([markedLink URL]){
            [newString addAttribute:NSLinkAttributeName value:[markedLink URL] range:linkRange];
        }
    }
    
    return newString;
}

// scan a textView for URL's, as above
-(void)linkifyTextView:(NSTextView *)inView
{
    NSMutableAttributedString *newView;

    // like allURLsFromTextView before it, we can just call the linkifyString: method here
    // then replace the NSTextView's contents with it.
    newView = [[[NSMutableAttributedString alloc] initWithAttributedString:
                                                [self linkifyString:
                                                [inView attributedSubstringFromRange:
                                                NSMakeRange(0,[[inView string] length])]]] autorelease];
                                                
    [[inView textStorage] setAttributedString:newView];
}
@end

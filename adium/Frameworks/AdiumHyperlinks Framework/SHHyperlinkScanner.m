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

#pragma mark primative methods
-(BOOL)isStringValidURL:(NSString *)inString
{
    URI_VERIFICATION_STATUS validStatus = SH_URL_INVALID;
    SH_BUFFER_STATE buf;
    
    buf = SH_scan_string([inString UTF8String]);
    
    NSLog(@"-(BOOL)isStringValidURL:@\"%@\"",inString);
    
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
        //SHStringOffset += [inString length];
        return NO;
    }
}

-(SHMarkedHyperlink *)nextURLFromString:(NSString *)inString
{
    NSLog(@"fetching next URL from String: %@",inString);
    NSString    *scanString = [[[NSString alloc] init] autorelease];
    int location = SHStringOffset;
    
    NSScanner *preScanner = [[NSScanner alloc] initWithString:inString];
    [preScanner setScanLocation:location];
    while([preScanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:&scanString]){
        SHStringOffset = [preScanner scanLocation] - [scanString length];
        //NSRange sRange = [inString rangeOfString:scanString options:nil range:NSMakeRange(location,[inString length]-location)];
        
        if([self isStringValidURL:scanString]){
            NSRange urlRange = NSMakeRange([preScanner scanLocation] - [scanString length],[scanString length]);
            
            SHMarkedHyperlink *markedLink = [[SHMarkedHyperlink alloc] initWithString:scanString
                                                                         parentString:inString
                                                                             andRange:urlRange];
            return markedLink;
        }
        
        location = SHStringOffset;
    }
    SHStringOffset = [inString length];
    return nil;
}

#pragma mark blah
-(NSArray *)allURLsFromString:(NSString *)inString
{
    NSLog(@"fetching all urls");
    SHStringOffset = 0;
    NSMutableArray *rangeArray = [[[NSMutableArray alloc] init] autorelease];
    SHMarkedHyperlink *markedLink = nil;
    
    while([inString length] > SHStringOffset){
        if(markedLink = [self nextURLFromString:inString]){
            [rangeArray addObject:markedLink];
        }
        NSLog(@"SHStringOffset = %u",SHStringOffset);
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

-(NSAttributedString *)linkifyString:(NSAttributedString *)inString
{
    NSLog(@"linkifying string");
    NSArray *rangeArray = [self allURLsFromString:[inString string]];
    NSEnumerator *enumerator = [rangeArray objectEnumerator];
    SHMarkedHyperlink *markedLink;
    
    
    NSMutableAttributedString *newString = [[[NSMutableAttributedString alloc] initWithAttributedString:inString] autorelease];
    
    while(markedLink = [enumerator nextObject]){
        NSRange linkRange = [markedLink range];
        [newString addAttribute:NSLinkAttributeName value:[[markedLink URL] retain] range:linkRange];
    }
    
    NSLog(@"finished linkifying");
    return newString;
}

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

//
//  SHHyperlinkScanner.m
//  Adium


#import "SHLinkLexer.h"
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
    URI_VERIFICATION_STATUS validStatus = 0;
    SH_BUFFER_STATE buf;
    
    buf = SH_scan_string([inString UTF8String]);
    
    validStatus = SHlex();
    if(validStatus == SH_URL_VALID || validStatus == SH_MAILTO_VALID || validStatus == SH_FILE_VALID){
        SH_delete_buffer(buf);
        return YES;
    }else if((validStatus == SH_URL_DEGENERATE || validStatus == SH_MAILTO_DEGENERATE) && !useStrictChecking){
        SH_delete_buffer(buf);
        return YES;
    }else{
        SH_delete_buffer(buf);
        return NO;
    }
}

-(NSRange)nextURLFromString:(NSString *)inString
{
    NSString *scanString = [inString substringFromIndex:SHStringOffset];
    URI_VERIFICATION_STATUS validStatus = 0;
    SH_BUFFER_STATE buf;
    
    while(SHStringOffset < [scanString length]){
        buf = SH_scan_string([[scanString substringFromIndex:SHStringOffset] UTF8String]);
    
        validStatus = SHlex();
        if(validStatus == SH_URL_VALID || validStatus == SH_MAILTO_VALID || validStatus == SH_FILE_VALID){
            SH_delete_buffer(buf);
             return NSMakeRange(SHStringOffset,SHleng);
        }
        else if((validStatus == SH_URL_DEGENERATE || validStatus == SH_MAILTO_DEGENERATE) && !useStrictChecking){
            SH_delete_buffer(buf);
            return NSMakeRange(SHStringOffset,SHleng);
        }
    }
    return NSMakeRange(0,0);
}

#pragma mark blah
-(NSArray *)allURLsFromString:(NSString *)inString
{
    SHStringOffset = 0;
    NSMutableArray *rangeArray = [[NSMutableArray arrayWithCapacity:1] autorelease];
    NSRange strRange = NSMakeRange(0,0);
    while([inString length] > SHStringOffset){
        strRange = [self nextURLFromString:inString];
        [rangeArray addObject:NSStringFromRange(strRange)];
    }
    return (NSArray *)rangeArray;
}

-(NSArray *)allURLsFromTextView:(NSTextView *)inView
{
    return [self allURLsFromString:[inView string]];
}

-(NSAttributedString *)linkifyString:(NSAttributedString *)inString
{
    NSArray *rangeArray = [self allURLsFromString:[inString string]];
    NSEnumerator *enumerator = [rangeArray objectEnumerator];
    NSString *linkRangeString = nil;
    NSRange linkRange;
    
    
    NSMutableAttributedString *newString = [[NSMutableAttributedString alloc] initWithAttributedString:inString];
    
    while(linkRangeString = [enumerator nextObject]){
        linkRange = NSRangeFromString(linkRangeString);
        [newString addAttribute:NSLinkAttributeName value:[[inString string] substringWithRange:linkRange] range:linkRange];
    }
    return (NSAttributedString *)newString;
}

-(void)linkifyTextView:(NSTextView *)inView
{
    inView = [[NSMutableAttributedString alloc] initWithAttributedString:
                                                [self linkifyString:
                                                [inView attributedSubstringFromRange:
                                                NSMakeRange(0,[[inView string] length])]]];
}
@end

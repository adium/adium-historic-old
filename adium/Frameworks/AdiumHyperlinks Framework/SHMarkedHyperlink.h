//
//  SHMarkedHyperlink.h
//  Adium
//
//  Created by Stephen Holt on Tue May 11 2004.


#import "SHLinkLexer.h"


@interface SHMarkedHyperlink : NSObject {
    NSRange                      linkRange;
    NSURL                       *linkURL;
    NSString                    *pString;
    URI_VERIFICATION_STATUS      urlStatus;
}

-(id)initWithString:(NSString *)inString withValidationStatus:(URI_VERIFICATION_STATUS)status parentString:(NSString *)pInString andRange:(NSRange)inRange;
-(NSString *)parentString;
-(NSRange)range;
-(NSURL *)URL;
-(URI_VERIFICATION_STATUS)validationStatus;
-(BOOL)parentStringMatchesString:(NSString *)inString;

-(void)setRange:(NSRange)inRange;
-(void)setURL:(NSURL *)inURL;
-(void)setURLFromString:(NSString *)inString;
-(void)setValidationStatus:(URI_VERIFICATION_STATUS)status;
-(void)setParentString:(NSString *)pInString;


@end

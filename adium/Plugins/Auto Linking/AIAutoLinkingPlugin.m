//
//  AIAutoLinkingPlugin.m
//  Adium
//
//  Created by Adam Iser on Thu Jun 12 2003.
//

#import "AIAutoLinkingPlugin.h"

//Recognized URL types
static int 	linkSubStringCount = 8;
static NSString *linkSubString[] = { //If any of these are found, the string is scanned in detail using the keys below
				     // You can find a current list of gTLD's at http://www.icann.org/tlds/
    // You can find a full listing of TLD's at http://www.norid.no/domenenavnbaser/domreg.html
    // This list only includes the gTLD's and some of the more popular TLD's
    @"://", @"www.", @"@", 
    @".com", @".edu", @".gov", @".net", @".org", @".us", @".co.uk", @".org.uk", @".museum", @".aero", @".biz", @".coop", @".info", @".mil", @".com.ar", @".pro", @".com.jp"};
static int 	linkDetailStringCount = 13;
static NSString *linkDetailString[] = { //Anything matching these keys is linked
    @"*://*", @"www.*.*", @"*@*.*",
     @"*.com", @"*.edu", @"*.gov", @"*.net", @"*.org", @"*.us", @"*.co.uk", @"*.org.uk", @"*.museum", @"*.aero", @"*.biz", @"*.coop", @"*.info", @"*.int", @"*.mil", @"*.pro", @"*.com.jp", @"*.com.ar",
     @"*.com/*", @"*.edu/*", @"*.gov/*", @"*.net/*", @"*.org/*", @"*.us/*", @"*.co.uk/*", @"*.org.uk/*", @"*.museum/*", @"*.aero/*", @"*.biz/*", @"*.coop/*", @"*.info/*", @"*.int/*", @"*.mil/*", @"*.pro/*", @"*.com.jp/*", @"*.com.ar/*"};
 
@implementation AIAutoLinkingPlugin

- (void)installPlugin
{
    //Register our content filter
	[[adium contentController] registerDisplayingContentFilter:self];
}

- (void)uninstallPlugin
{
	[[adium contentController] unregisterDisplayingContentFilter:self];
}

- (NSAttributedString *)filterAttributedString:(NSAttributedString *)inAttributedString forContentObject:(AIContentObject *)inObject listObjectContext:(AIListObject *)inListObject
{
    NSMutableAttributedString   *replacementMessage = nil;
    if (inAttributedString) {
        int				loop;
        BOOL				mayContainLinks = NO;
        NSString			*messageString = [inAttributedString string];

        //First, we do a quick scan of the message for any substrings that might end up being links
        //This avoids having to do the slower, more complicated scan for the majority of messages.
        for(loop = 0; loop < linkSubStringCount; loop++){
            if([messageString rangeOfString:linkSubString[loop]].location != NSNotFound){
                mayContainLinks = YES;
                break;
            }
        }

        //If this string might contain links, we do a more thorough scan
        if(mayContainLinks){
            NSMutableCharacterSet	*whitespaceSet;
            NSScanner			*messageScanner;

            //Prepare our scanner
            whitespaceSet = [[[NSMutableCharacterSet whitespaceAndNewlineCharacterSet] mutableCopy] autorelease];
            [whitespaceSet addCharactersInString:@"()"];
            messageScanner = [NSScanner scannerWithString:messageString];

            //Here we process the message in chunks separated by whitespace or a newline.
            while(![messageScanner isAtEnd]){
                NSString	*urlString = nil;

                // Pull out a token delimited by whitespace or new line
                if([messageScanner scanUpToCharactersFromSet:whitespaceSet intoString:&urlString]){

                    //Check for each link variation within this url string
                    for(loop = 0;loop < linkDetailStringCount; loop++){
                        BOOL		URLIsValid = YES;
                        NSString 	*template;
                        NSString	*templateSegment;
                        NSScanner	*urlScanner;
                        NSRange		wildRange;
                        int		templateIndex = 0;

                        //Prepare our scanner
                        template = linkDetailString[loop];
                        urlScanner = [NSScanner scannerWithString:urlString];                    
                        
                        //If the template does not start with a *, we scan for the first required chunk
                        if([template characterAtIndex:0] != '*'){

                            //Get template up to the next *
                            wildRange = [template rangeOfString:@"*"];
                            if(wildRange.location != NSNotFound){
                                templateSegment = [template substringToIndex:wildRange.location];
                                templateIndex = wildRange.location;
                                
                                //Scan that string from the suspected URL.  If not found, this URL is invalid.
                                if(![urlScanner scanString:templateSegment intoString:nil]){
                                    URLIsValid = NO; //Didn't find first segment
                                }
                            }
                            
                        }

                        //Now we scan for each remaining chunk
                        while(templateIndex < ([template length] - 1)){
                            BOOL	charactersScanned;
                            
                            //Scan the template string after *, up to next * or end
                            templateIndex += 1;
                            wildRange = [template rangeOfString:@"*" 
                                                        options:0 
                                                          range:NSMakeRange(templateIndex, [template length] - templateIndex)];
                            
                            if(wildRange.location != NSNotFound){
                                templateSegment = [template substringWithRange:NSMakeRange(templateIndex, wildRange.location - templateIndex)];
                                templateIndex = wildRange.location;
                            }else{
                                templateSegment = [template substringFromIndex:templateIndex];
                                templateIndex = [template length];
                            }

                            //Scan up to that string in our URL.  If not found, this URL is invalid.
                            charactersScanned = [urlScanner scanUpToString:templateSegment intoString:nil];
                            if(!charactersScanned || ![urlScanner scanString:templateSegment intoString:nil]){
                                URLIsValid = NO; //Template chunk not found
                            }
                        }

                        //One final check.  Our URL must be complete at the right location (If the template doesn't end with a *)
                        if([template characterAtIndex:[template length]-1] != '*' 
                           && [urlScanner scanLocation] != [urlString length]){
                            URLIsValid = NO; //Didn't end
                        }

                        //If the URL was valid, turn it into a link
                        if(URLIsValid){
                            NSRange	urlRange = NSMakeRange([messageScanner scanLocation] - [urlString length], [urlString length]);

			    //Make sure this text doesn't already have a link attribute
                            if(![inAttributedString attribute:NSLinkAttributeName
                                                            atIndex:urlRange.location
                                                     effectiveRange:nil]){
				
				//Make sure we've got a replacement message string made
				if(!replacementMessage){
				    replacementMessage = [[inAttributedString mutableCopy] autorelease];
				}
    
				//Set this segment as a link, appending http:// if necessary
				if([urlString rangeOfString:@"://"].location != NSNotFound){ //prefix already appended
				    [replacementMessage addAttribute:NSLinkAttributeName
							    value:urlString
							    range:urlRange];
    
				}else if([urlString rangeOfString:@"@"].location != NSNotFound){ //mail
				    [replacementMessage addAttribute:NSLinkAttributeName
							    value:[NSString stringWithFormat:@"mailto:%@",urlString]
							    range:urlRange];
    
				}else{ //http
				    [replacementMessage addAttribute:NSLinkAttributeName
							    value:[NSString stringWithFormat:@"http://%@",urlString]
							    range:urlRange];
				    
				}
    
/*				//Color it blue and underline for good measure
				[replacementMessage addAttribute:NSForegroundColorAttributeName 
                                                           value:[NSColor blueColor]
                                                           range:urlRange];
				[replacementMessage addAttribute:NSUnderlineStyleAttributeName 
                                                           value:[NSNumber numberWithInt:1] 
                                                           range:urlRange];*/
                            }
			    
                        }
                    }
                }
                [messageScanner scanCharactersFromSet:whitespaceSet intoString:nil];
            }
        }
    }
    return (replacementMessage ? replacementMessage : inAttributedString);
}


@end




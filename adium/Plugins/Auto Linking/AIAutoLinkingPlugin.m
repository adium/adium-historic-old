//
//  AIAutoLinkingPlugin.m
//  Adium
//
//  Created by Adam Iser on Thu Jun 12 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIAutoLinkingPlugin.h"
#import "AIAdium.h"
#import <AIUtilities/AIUtilities.h>

//Recognized URL types
static int 	linkSubStringCount = 8;
static NSString *linkSubString[] = {@"http://", @"ftp://", @"www.", @".com", @".edu", @".gov", @".net", @".org"};
static NSString *linkDetailString[] = {@"http://*", @"ftp://*", @"www.*.*", @"*.com", @"*.edu", @"*.gov", @"*.net", @"*.org"};
 
@implementation AIAutoLinkingPlugin

- (void)installPlugin
{
    //Register our content filter
    [[owner contentController] registerOutgoingContentFilter:self];
}

- (void)filterContentObject:(id <AIContentObject>)inObject
{

    if([[inObject type] compare:CONTENT_MESSAGE_TYPE] == 0){
        int				loop;
        BOOL				mayContainLinks = NO;
        AIContentMessage		*contentMessage = (AIContentMessage *)inObject;
        NSString			*messageString = [[contentMessage message] string];
        NSMutableAttributedString	*replacementMessage = nil;

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
                    for(loop = 0;loop < linkSubStringCount; loop++){
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
                            wildRange = [template rangeOfString:@"*" options:0 range:NSMakeRange(templateIndex, [template length] - templateIndex)];
                            
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

                        //One final check.  Our URL must be complete at the right location
                        if([urlScanner scanLocation] != [urlString length]){
                            URLIsValid = NO; //Didn't end
                        }

                        //If the URL was valid, turn it into a link
                        if(URLIsValid){
                            NSRange	urlRange;
                            
                            //Make sure we've got a replacement message string made
                            if(!replacementMessage){
                                replacementMessage = [[[contentMessage message] mutableCopy] autorelease];
                            }

                            //Set this segment as a link, appending http:// if necessary
                            urlRange = NSMakeRange([messageScanner scanLocation] - [urlString length], [urlString length]);

                            if([urlString rangeOfString:@"://"].location != NSNotFound){
                                [replacementMessage addAttribute:NSLinkAttributeName
                                                           value:urlString
                                                           range:urlRange];
                            }else{
                                [replacementMessage addAttribute:NSLinkAttributeName
                                                           value:[NSString stringWithFormat:@"http://%@",urlString]
                                                           range:urlRange];
                            }

                            //Color it blue and underline for good measure
                            [replacementMessage addAttribute:NSForegroundColorAttributeName value:[NSColor blueColor] range:urlRange];
                            [replacementMessage addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:1] range:urlRange];
                            
                        }
                    }
                }
            }
        }

        //If any links were created, apply the new message
        if(replacementMessage){
            [contentMessage setMessage:replacementMessage];
        }
    }
}


@end




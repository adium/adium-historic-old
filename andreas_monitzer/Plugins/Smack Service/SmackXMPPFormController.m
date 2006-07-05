//
//  SmackXMPPFormController.m
//  Adium
//
//  Created by Andreas Monitzer on 2006-07-04.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import "SmackXMPPFormController.h"
#import "SmackInterfaceDefinitions.h"
#import "SmackXMPPFormConverter.h"
#import "SmackCocoaAdapter.h"

#import <WebKit/WebKit.h>

@implementation SmackXMPPFormController

- (id)initWithForm:(SmackXForm*)form target:(id)t selector:(SEL)s {
    if(![[form getType] isEqualToString:@"form"]) { // we only accept forms
        [self dealloc];
        return nil;
    }
    if((self = [super init])) {
        target = [t retain];
        selector = s;
        [NSBundle loadNibNamed:@"SmackXMPPForm" owner:self];
        [webview setHostWindow:window];
        
        SmackXMPPFormConverter *conv = [[SmackXMPPFormConverter alloc] initWithForm:form];
        resultForm = [[form createAnswerForm] retain];
        
        [self performSelector:@selector(loadForm:) withObject:conv afterDelay:0.0];
        
    }
    return self;
}

- (void)dealloc {
    [resultForm release];
    [super dealloc];
}

- (void)loadForm:(SmackXMPPFormConverter*)conv
{
    NSData *formdata = [conv toXHTML];
    [[webview mainFrame] loadData:formdata MIMEType:@"application/xhtml+xml" textEncodingName:@"UTF-8" baseURL:nil];
    [window makeKeyAndOrderFront:nil];
}

- (void)webView:(WebView *)webView decidePolicyForNavigationAction:(NSDictionary *)actionInformation
        request:(NSURLRequest *)request
          frame:(WebFrame *)frame
                                                  decisionListener:(id<WebPolicyDecisionListener>)listener
{
    if([[[request URL] scheme] isEqualToString:@"applewebdata"] || [[[request URL] scheme] isEqualToString:@"about"])
        [listener use];
    else {
        if([[[request URL] absoluteString] isEqualToString:@"http://www.adiumx.com/XMPP/form"]) {
            NSString *info = [[NSString alloc] initWithData:[request HTTPBody] encoding:NSUTF8StringEncoding];
            NSArray *fields = [info componentsSeparatedByString:@"&"];
            [info release];
            
            NSEnumerator *e = [fields objectEnumerator];
            NSString *field;
            while((field = [e nextObject]))
            {
                NSArray *keyvalue = [field componentsSeparatedByString:@"="];
                if([keyvalue count] != 2)
                    continue;

                NSString *key = [[[keyvalue objectAtIndex:0] mutableCopy] autorelease];
                [(NSMutableString*)key replaceOccurrencesOfString:@"+" withString:@" " options:NSLiteralSearch range:NSMakeRange(0,[key length])];

                key = (NSString*)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault,
                                                                                         (CFStringRef)key,
                                                                                         (CFStringRef)@"", kCFStringEncodingUTF8);

                NSString *value = [[[keyvalue objectAtIndex:1] mutableCopy] autorelease];
                [(NSMutableString*)value replaceOccurrencesOfString:@"+" withString:@" " options:NSLiteralSearch range:NSMakeRange(0,[value length])];
                
                value = (NSString*)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault,
                                                                                           (CFStringRef)value,
                                                                                           (CFStringRef)@"", kCFStringEncodingUTF8);
                
                
                
                [SmackCocoaAdapter invokeObject:resultForm methodWithParamTypeAndParam:@"setAnswer",@"java.lang.String",value,nil];
                
                [key release];
                [value release];
            }
            
            NSLog(@"result form = %@",[[resultForm getDataFormToSend] toXML]);

            [window performClose:nil];
            [target performSelector:selector withObject:self];
            [target release];
        }
        [listener ignore];
    }
}

- (void)windowWillClose:(NSNotification *)notification {
    [resultForm release];
    resultForm = [[SmackCocoaAdapter formWithType:@"cancel"] retain];
    
    [target performSelector:selector withObject:self];
    [target release];
}

- (SmackXForm*)resultForm {
    return resultForm;
}

@end

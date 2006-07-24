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

- (id)initWithForm:(SmackXForm*)form target:(id)t selector:(SEL)s webView:(WebView*)wv registered:(BOOL)reg {
    if(![[form getType] isEqualToString:@"form"]) { // we only accept forms
        [self dealloc];
        return nil;
    }
    if((self = [super init])) {
        target = [t retain];
        selector = [NSStringFromSelector(s) retain];
        if(!wv) {
            [NSBundle loadNibNamed:@"SmackXMPPForm" owner:self];
            [webview setHostWindow:window];
        } else {
            webview = wv;
            [webview setPolicyDelegate:self];
        }
        
        SmackXMPPFormConverter *conv = [[SmackXMPPFormConverter alloc] initWithForm:form registered:reg];
        resultForm = [[form createAnswerForm] retain];
        
        [self performSelector:@selector(loadForm:) withObject:conv afterDelay:0.0];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(webviewWindowWillClose:)
                                                     name:NSWindowWillCloseNotification
                                                   object:[webview window]];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [resultForm release];
    [selector release];
    [super dealloc];
}

- (void)loadForm:(SmackXMPPFormConverter*)conv
{
    NSData *formdata = [conv toXHTML];
    [[webview mainFrame] loadData:formdata MIMEType:@"application/xhtml+xml" textEncodingName:@"UTF-8" baseURL:nil];
    [window makeKeyAndOrderFront:nil];
}

- (void)webviewWindowWillClose:(NSNotification *)notification {
    if(!wasSubmitted) {
        [resultForm release];
        resultForm = [[SmackCocoaAdapter formWithType:@"cancel"] retain];
    }
    
    [webview setPolicyDelegate:nil];
    
    id t = target; // the target variable might be gone when we return!
    
    [t performSelector:NSSelectorFromString(selector) withObject:self];
    [t release];
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
                
                NSString *type;
                if([key isEqualToString:@"http://adiumx.com/smack/remove"])
                {
                    // add our own remove field here
                    SmackXFormField *field = [SmackCocoaAdapter formFieldWithVariable:@"http://adiumx.com/smack/remove"];
                    [field setType:type = @"boolean"];
                    [resultForm addField:field];
                } else
                    type = [[resultForm getField:key] getType];
                
                if([type isEqualToString:@"boolean"])
                    [SmackCocoaAdapter invokeObject:resultForm methodWithParamTypeAndParam:@"setAnswer",@"java.lang.String",key,@"boolean",YES,nil];
                else if([type isEqualToString:@"jid-multi"])
                {
                    NSEnumerator *e_jids = [[value componentsSeparatedByString:@"\r\n"] objectEnumerator];
                    NSString *jid;
                    SmackXFormField *field = [resultForm getField:key];
                    
                    [field resetValues];
                    while((jid = [e_jids nextObject]))
                        [field addValue:jid];
                } else if([type isEqualToString:@"list-multi"] || [type isEqualToString:@"list-single"])
                    [[resultForm getField:key] addValue:value];
                else
                    [SmackCocoaAdapter invokeObject:resultForm methodWithParamTypeAndParam:@"setAnswer",@"java.lang.String",key,@"java.lang.String",value,nil];
                
                [key release];
                [value release];
            }
            
            wasSubmitted = YES;

            if(window)
                [window close];
            else {
                [[NSNotificationCenter defaultCenter] removeObserver:self]; // avoid double-calling our window close method
                [self webviewWindowWillClose:nil];
            }
        }
        [listener ignore];
    }
}

- (SmackXForm*)resultForm {
    return resultForm;
}

@end

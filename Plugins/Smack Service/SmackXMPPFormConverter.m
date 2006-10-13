//
//  SmackXMPPFormConverter.m
//  Adium
//
//  Created by Andreas Monitzer on 2006-07-04.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import "SmackXMPPFormConverter.h"
#import "SmackInterfaceDefinitions.h"
#import <AIUtilities/AIStringUtilities.h>

@implementation SmackXMPPFormConverter

- (id)initWithForm:(SmackXForm*)f {
    return [self initWithForm:f registered:NO];
}

- (id)initWithForm:(SmackXForm*)f registered:(BOOL)reg {
    if ((self = [super init])) {
        form = [f retain];
        registered = reg;
    }
    return self;
}

static NSString *expandValues(JavaIterator *iter)
{
    NSMutableArray *result = [[NSMutableArray alloc] init];
    while([iter hasNext])
        [result addObject:[iter next]];
    return [result componentsJoinedByString:@"\r\n"];
}

// converts the Smack Form type to XHTML for easy usage in a WebView
- (NSData*)toXHTML {
    NSXMLElement *root = [NSXMLNode elementWithName:@"html"];
    [root addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:@"http://www.w3.org/1999/xhtml"]];
    
    NSXMLElement *head = [NSXMLNode elementWithName:@"head"];
    [root addChild:head];

    [head addChild:[NSXMLNode elementWithName:@"style" children:[NSArray arrayWithObject:
        [NSXMLNode textWithStringValue:
            @"body { font-family:'Lucida Grande'; border: 0px; padding: 0px; }"
            @"table { width: 100%; table-layout: fixed; }"
            @"h1 { font-size: 1.5em; }"
            @"th { text-align: right; width: 180px; vertical-align: top; font-weight: normal; }"
            @"td { vertical-align: top; }"
            @"#submit { font-size: 14pt; }"
            @"#submitbutton { position: fixed; text-align: right; bottom: 0px; right: 0px; }"
            ]] attributes:[NSArray arrayWithObject:
                [NSXMLNode attributeWithName:@"type" stringValue:@"text/css"]]]];
    
    NSXMLElement *title = [NSXMLNode elementWithName:@"title" stringValue:[form getTitle]];
    [head addChild:title];
    
    NSXMLElement *body = [NSXMLNode elementWithName:@"body"];
    [root addChild:body];
    
    NSXMLElement *heading = [NSXMLNode elementWithName:@"h1" stringValue:[form getTitle]];
    [body addChild:heading];
    
    [body addChild:[NSXMLNode elementWithName:@"p" stringValue:[form getInstructions]]];
    
    NSXMLElement *formnode = [NSXMLNode elementWithName:@"form" children:nil attributes:[NSArray arrayWithObjects:
        [NSXMLNode attributeWithName:@"action" stringValue:@"http://www.adiumx.com/XMPP/form"],
        [NSXMLNode attributeWithName:@"method" stringValue:@"POST"],nil]];
    [body addChild:formnode];
    
    NSXMLElement *table = [NSXMLNode elementWithName:@"table"];
    [formnode addChild:table];
    
    JavaIterator *iter = [form getFields];
    
    while([iter hasNext]) {
        SmackXFormField *field = [iter next];
        NSString *type = [field getType];
        NSXMLElement *fieldnode = nil;
        
        NSXMLElement *row = [NSXMLNode elementWithName:@"tr"];
        [table addChild:row];
        if ([field isRequired])
            [row addAttribute:[NSXMLNode attributeWithName:@"class" stringValue:@"required"]];
        
        [row addChild:[NSXMLNode elementWithName:@"th" stringValue:[field getLabel]]];
        
        if ([type isEqualToString:@"text-single"])
            fieldnode = [NSXMLNode elementWithName:@"input" children:nil attributes:[NSArray arrayWithObjects:
                [NSXMLNode attributeWithName:@"name" stringValue:[field getVariable]],
                [NSXMLNode attributeWithName:@"title" stringValue:[field getDescription]],
                [NSXMLNode attributeWithName:@"value" stringValue:expandValues([field getValues])],
                [NSXMLNode attributeWithName:@"type" stringValue:@"text"],nil]];
        else if ([type isEqualToString:@"text-private"])
            fieldnode = [NSXMLNode elementWithName:@"input" children:nil attributes:[NSArray arrayWithObjects:
                [NSXMLNode attributeWithName:@"name" stringValue:[field getVariable]],
                [NSXMLNode attributeWithName:@"title" stringValue:[field getDescription]],
                [NSXMLNode attributeWithName:@"value" stringValue:expandValues([field getValues])],
                [NSXMLNode attributeWithName:@"type" stringValue:@"password"],nil]];
        else if ([type isEqualToString:@"text-multi"])
            fieldnode = [NSXMLNode elementWithName:@"textarea" children:[NSArray arrayWithObject:[NSXMLNode textWithStringValue:expandValues([field getValues])]] attributes:[NSArray arrayWithObjects:
                [NSXMLNode attributeWithName:@"name" stringValue:[field getVariable]],
                [NSXMLNode attributeWithName:@"cols" stringValue:@"80"],
                [NSXMLNode attributeWithName:@"rows" stringValue:@"4"],
                [NSXMLNode attributeWithName:@"title" stringValue:[field getDescription]],
                nil]];
        else if ([type isEqualToString:@"list-single"])
        {
            fieldnode = [NSXMLNode elementWithName:@"select" children:nil attributes:[NSArray arrayWithObjects:
                [NSXMLNode attributeWithName:@"name" stringValue:[field getVariable]],
                [NSXMLNode attributeWithName:@"size" stringValue:@"1"],
                [NSXMLNode attributeWithName:@"title" stringValue:[field getDescription]],
                nil]];
            JavaIterator *iter = [field getOptions];
            JavaIterator *valiter = [field getValues];
            NSString *selected = nil;
            if ([valiter hasNext])
                selected = [valiter next];
            
            while([iter hasNext]) {
                SmackXFormFieldOption *ffo = [iter next];
                NSXMLElement *option = [NSXMLNode elementWithName:@"option" stringValue:[ffo getLabel]];
                [option addAttribute:[NSXMLNode attributeWithName:@"value" stringValue:[ffo getValue]]];
                if ([selected isEqualToString:[ffo getValue]])
                    [option addAttribute:[NSXMLNode attributeWithName:@"selected" stringValue:@"selected"]];
                [fieldnode addChild:option];
            }
        }
        else if ([type isEqualToString:@"list-multi"])
        {
            fieldnode = [NSXMLNode elementWithName:@"select" children:nil attributes:[NSArray arrayWithObjects:
                [NSXMLNode attributeWithName:@"name" stringValue:[field getVariable]],
                [NSXMLNode attributeWithName:@"multiple" stringValue:@"multiple"],
                [NSXMLNode attributeWithName:@"title" stringValue:[field getDescription]],
                nil]];
            JavaIterator *iter = [field getOptions];
            int counter = 0;

            JavaIterator *valiter = [field getValues];
            NSMutableSet *selected = [[NSMutableSet alloc] init];
            while([valiter hasNext])
                [selected addObject:[valiter next]];
            
            while([iter hasNext]) {
                SmackXFormFieldOption *ffo = [iter next];
                NSXMLElement *option = [NSXMLNode elementWithName:@"option" stringValue:[ffo getLabel]];
                [option addAttribute:[NSXMLNode attributeWithName:@"value" stringValue:[ffo getValue]]];
                if ([selected containsObject:[ffo getValue]])
                    [option addAttribute:[NSXMLNode attributeWithName:@"selected" stringValue:@"selected"]];
                [fieldnode addChild:option];
                counter++;
            }
            
            // we only allow a maximum of 10 visible items at the same time
            if (counter > 10)
                [fieldnode addAttribute:[NSXMLNode attributeWithName:@"size" stringValue:@"10"]];
            else
                [fieldnode addAttribute:[NSXMLNode attributeWithName:@"size" stringValue:[[NSNumber numberWithInt:counter] stringValue]]];
        }
        else if ([type isEqualToString:@"boolean"])
        {
            fieldnode = [NSXMLNode elementWithName:@"input" children:nil attributes:[NSArray arrayWithObjects:
                [NSXMLNode attributeWithName:@"name" stringValue:[field getVariable]],
                [NSXMLNode attributeWithName:@"title" stringValue:[field getDescription]],
                [NSXMLNode attributeWithName:@"type" stringValue:@"checkbox"],nil]];
            JavaIterator *valiter = [field getValues];
            BOOL selected = NO;
            if ([valiter hasNext])
                selected = [[valiter next] intValue]?YES:NO;
            if (selected)
                [fieldnode addAttribute:[NSXMLNode attributeWithName:@"checked" stringValue:@"checked"]];
        }
        else if ([type isEqualToString:@"fixed"])
            fieldnode = [NSXMLNode elementWithName:@"span" stringValue:expandValues([field getValues])];
        else if ([type isEqualToString:@"hidden"])
            fieldnode = [NSXMLNode elementWithName:@"input" children:nil attributes:[NSArray arrayWithObjects:
                [NSXMLNode attributeWithName:@"name" stringValue:[field getVariable]],
                [NSXMLNode attributeWithName:@"value" stringValue:expandValues([field getValues])],
                [NSXMLNode attributeWithName:@"type" stringValue:@"hidden"],nil]];
        else if ([type isEqualToString:@"jid-single"]) // ### should be some kind of combobox, allowing entering of jabber ids from the local contact list
            fieldnode = [NSXMLNode elementWithName:@"input" children:nil attributes:[NSArray arrayWithObjects:
                [NSXMLNode attributeWithName:@"name" stringValue:[field getVariable]],
                [NSXMLNode attributeWithName:@"title" stringValue:[field getDescription]],
                [NSXMLNode attributeWithName:@"value" stringValue:expandValues([field getValues])],
                [NSXMLNode attributeWithName:@"type" stringValue:@"text"],nil]];
        else if ([type isEqualToString:@"jid-multi"]) // ### should be some kind of multi-line combobox, allowing entering of jabber ids from the local contact list
            fieldnode = [NSXMLNode elementWithName:@"textarea" children:[NSArray arrayWithObject:[NSXMLNode textWithStringValue:expandValues([field getValues])]] attributes:[NSArray arrayWithObjects:
                [NSXMLNode attributeWithName:@"name" stringValue:[field getVariable]],
                [NSXMLNode attributeWithName:@"type" stringValue:@"password"],
                [NSXMLNode attributeWithName:@"cols" stringValue:@"80"],
                [NSXMLNode attributeWithName:@"rows" stringValue:@"4"],
                [NSXMLNode attributeWithName:@"title" stringValue:[field getDescription]],
                nil]];

        if (fieldnode)
            [row addChild:[NSXMLNode elementWithName:@"td" children:[NSArray arrayWithObject:fieldnode] attributes:nil]];
    }
    
    NSXMLElement *row;
    if (registered) {
        row = [NSXMLNode elementWithName:@"tr"];
        [row addChild:[NSXMLNode elementWithName:@"td" stringValue:AILocalizedString(@"Remove registration","Remove registration")]];
        [row addChild:[NSXMLNode elementWithName:@"td" children:[NSArray arrayWithObject:
            [NSXMLNode elementWithName:@"input" children:nil attributes:[NSArray arrayWithObjects:
            [NSXMLNode attributeWithName:@"name" stringValue:@"http://adiumx.com/smack/remove"],
                [NSXMLNode attributeWithName:@"type" stringValue:@"checkbox"],nil]]] attributes:nil]];
        [table addChild:row];
        row = [NSXMLNode elementWithName:@"tr"];
        [row addChild:[NSXMLNode elementWithName:@"td" stringValue:@""]];
        [row addChild:[NSXMLNode elementWithName:@"td" stringValue:AILocalizedString(@"NOTE: Removing the registration cannot be undone!","NOTE: Removing the registration cannot be undone!")]];
        [table addChild:row];
    }
    
/*    row = [NSXMLNode elementWithName:@"tr"];
    [row addChild:[NSXMLNode elementWithName:@"td" stringValue:@""]];
    [row addChild:[NSXMLNode elementWithName:@"td" children:[NSArray arrayWithObjects:
        [NSXMLNode elementWithName:@"input" children:nil attributes:[NSArray arrayWithObjects:
            [NSXMLNode attributeWithName:@"type" stringValue:@"reset"],
            [NSXMLNode attributeWithName:@"value" stringValue:AILocalizedString(@"Reset","Reset")],nil]],
        [NSXMLNode elementWithName:@"input" children:nil attributes:[NSArray arrayWithObjects:
            [NSXMLNode attributeWithName:@"type" stringValue:@"submit"],
            [NSXMLNode attributeWithName:@"value" stringValue:AILocalizedString(@"Submit","Submit")],nil]],
        nil] attributes:nil]];
    [table addChild:row];*/
    
    [formnode addChild:[NSXMLNode elementWithName:@"div" children:[NSArray arrayWithObject:
        [NSXMLNode elementWithName:@"input" children:nil attributes:[NSArray arrayWithObjects:
            [NSXMLNode attributeWithName:@"type" stringValue:@"submit"],
            [NSXMLNode attributeWithName:@"id" stringValue:@"submit"],
            [NSXMLNode attributeWithName:@"value" stringValue:AILocalizedString(@"  Submit  ","Submit")],nil]]
             ] attributes:[NSArray arrayWithObject:[NSXMLElement attributeWithName:@"id" stringValue:@"submitbutton"]]]];
    
    NSXMLDocument *doc = [NSXMLNode documentWithRootElement:root];
    [doc setCharacterEncoding:@"UTF-8"];
    [doc setDocumentContentKind:NSXMLDocumentXHTMLKind];
    return [doc XMLDataWithOptions:NSXMLDocumentTidyHTML | NSXMLDocumentIncludeContentTypeDeclaration];
}

@end

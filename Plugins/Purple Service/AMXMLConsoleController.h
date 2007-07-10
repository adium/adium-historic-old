//
//  AMXMLConsoleController.h
//  Adium
//
//  Created by Andreas Monitzer on 2007-06-06.
//  Copyright 2007 Andreas Monitzer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AdiumLibpurple/PurpleCommon.h>

@interface AMXMLConsoleController : NSObject {
    IBOutlet NSWindow *xmlConsoleWindow;
    IBOutlet NSTextView *xmlLogView;
    IBOutlet NSTextView *xmlInjectView;
    IBOutlet NSButton *sendButton;
    IBOutlet NSButton *enabledButton;
    
    PurpleConnection *gc;
}

- (id)initWithPurpleConnection:(PurpleConnection*)_gc;

- (IBAction)sendXML:(id)sender;
- (IBAction)clearLog:(id)sender;

- (IBAction)showWindow:(id)sender;

- (void)appendToLog:(NSAttributedString*)astr;

- (PurpleConnection*)gc;

@end

//
//  RAFjoscarDebugWindowController.h
//  Adium
//
//  Created by Augie Fackler on 12/28/05.
//

#import <Adium/AIWindowController.h>

@class AIAutoScrollView;

@interface RAFjoscarDebugWindowController : AIWindowController {
	IBOutlet	NSTextView			*textView_debug;
	IBOutlet	AIAutoScrollView	*scrollView_debug;
	NSMutableString					*mutableDebugString;
	NSMutableParagraphStyle			*debugParagraphStyle;
	NSString						*currentFilterString;

	IBOutlet	NSButton			*checkBox_logWriting;
	IBOutlet	NSTextField			*textView_version;
	IBOutlet	NSTextField			*textView_filter;
}

#ifdef DEBUG_BUILD
+ (id)showDebugWindow;
+ (void)closeDebugWindow;
+ (BOOL)debugWindowIsOpen;
+ (void)addedDebugMessage:(NSString *)message;
- (IBAction)toggleLogWriting:(id)sender;
- (IBAction)clearLog:(id)sender;
#endif

@end

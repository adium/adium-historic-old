//
//  ESDebugWindowController.h
//  Adium
//
//  Created by Evan Schoenberg on 9/29/04.

@interface ESDebugWindowController : AIWindowController {
	IBOutlet	NSTextView			*textView_debug;
	IBOutlet	AIAutoScrollView	*scrollView_debug;
	NSMutableString			*mutableDebugString;
}

#ifdef DEBUG_BUILD
+ (id)showDebugWindow;
+ (void)closeDebugWindow;
+ (BOOL)debugWindowIsOpen;
+ (void)addedDebugMessage:(NSString *)message;
#endif

@end

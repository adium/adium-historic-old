//
//  AIWindowController.h
//  Adium
//
//  Created by Adam Iser on Sun Dec 14 2003.
//

#import "AIObject.h"

@interface AIWindowController : NSWindowController {
    AIAdium		*adium;
}

- (void)windowDidLoad;
- (BOOL)windowShouldClose:(id)sender;
- (NSString *)adiumFrameAutosaveName;

@end

//
//  SHLinkEditorWindowController.h
//  Adium
//
//  Created by Stephen Holt on Sat Apr 17 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

#define LINK_MANAGEMENT_DEFAULTS        @"LinkManagementDefaults"
#define PREF_GROUP_LINK_FAVORITES       @"URL Favorites"
#define KEY_LINK_FAVORITES				@"Favorite Links"
#define KEY_LINK_URL					@"URL"
#define KEY_LINK_TITLE					@"Title"

@class SHAutoValidatingTextView, AIAutoScrollView;

@interface SHLinkEditorWindowController : AIWindowController {
    
    IBOutlet    NSButton                    *button_insert;
    IBOutlet    NSButton                    *button_cancel;
	IBOutlet	NSButton					*button_removeLink;
	
    IBOutlet    NSTextField                 *textField_linkText;
    IBOutlet	AIAutoScrollView            *scrollView_URL;
    IBOutlet    SHAutoValidatingTextView    *textView_URL;
    IBOutlet    NSImageView                 *imageView_invalidURLAlert;
    
	IBOutlet	NSTextField					*label_linkText;
	IBOutlet	NSTextField					*label_URL;
	
    NSTextView                              *textView;
    id                                       target;
}

+ (void)showLinkEditorForTextView:(NSTextView *)inTextView onWindow:(NSWindow *)parentWindow showFavorites:(BOOL)showFavorites notifyingTarget:(id)inTarget;

- (IBAction)cancel:(id)sender;

- (IBAction)acceptURL:(id)sender;
- (IBAction)removeURL:(id)sender;

@end

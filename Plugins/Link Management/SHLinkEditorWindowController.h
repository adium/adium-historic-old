//
//  SHLinkEditorWindowController.h
//  Adium
//
//  Created by Stephen Holt on Sat Apr 17 2004.

#define LINK_MANAGEMENT_DEFAULTS        @"LinkManagementDefaults"
#define PREF_GROUP_LINK_FAVORITES       @"URL Favorites"
#define KEY_LINK_FAVORITES				@"Favorite Links"
#define KEY_LINK_URL					@"URL"
#define KEY_LINK_TITLE					@"Title"

@class SHAutoValidatingTextView, AIAutoScrollView;

@interface SHLinkEditorWindowController : AIWindowController {
    
    IBOutlet    NSButton                    *button_OK;
    IBOutlet    NSButton                    *button_Cancel;
    
    IBOutlet    NSTextField                 *textField_linkText;
	IBOutlet	AIAutoScrollView			*scrollView_URL;
    IBOutlet    SHAutoValidatingTextView    *textView_URL;
    IBOutlet    NSImageView                 *imageView_invalidURLAlert;
    
	NSTextView					*textView;
	id							target;
}

+ (void)showLinkEditorForTextView:(NSTextView *)inTextView onWindow:(NSWindow *)parentWindow showFavorites:(BOOL)showFavorites notifyingTarget:(id)inTarget;

- (IBAction)closeWindow:(id)sender;
- (IBAction)cancel:(id)sender;

- (IBAction)acceptURL:(id)sender;

@end

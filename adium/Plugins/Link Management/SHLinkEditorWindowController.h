//
//  SHLinkEditorWindowController.h
//  Adium
//
//  Created by Stephen Holt on Sat Apr 17 2004.

#define PREF_GROUP_LINK_FAVORITES       @"URL Favorites"
#define LINK_MANAGEMENT_DEFAULTS        @"LinkManagementDefaults"

@class SHAutoValidatingTextView;

@interface SHLinkEditorWindowController : AIWindowController {
    
    IBOutlet    NSButton                    *button_OK;
    IBOutlet    NSButton                    *button_Cancel;
    IBOutlet    NSButton                    *button_AddFavorites;
    
    IBOutlet    NSPopUpButton               *popUp_Favorites;
    
    IBOutlet    NSTextField                 *textField_linkText;
    IBOutlet    SHAutoValidatingTextView    *textView_URL;
    IBOutlet    NSImageView                 *imageView_invalidURLAlert;
    
                BOOL                         editLink;
                BOOL                         favoriteWindow;

                NSRange                      selectionRange;
                NSResponder                 *editableView;

                NSDictionary                *favoritesDict;
}

- (void)initAddLinkWindowControllerWithResponder:(NSResponder *)responder;
- (void)initEditLinkWindowControllerWithResponder:(NSResponder *)responder;
- (void)initAddLinkFavoritesWindowControllerWithView:(NSView *)view;

- (void)windowWillBeginSheet:(NSNotification *)aNotification;
- (IBAction)closeWindow:(id)sender;
- (IBAction)cancel:(id)sender;

- (IBAction)acceptURL:(id)sender;
- (IBAction)selectFavoriteURL:(id)sender;
- (IBAction)addURLToFavorites:(id)sender;

- (void)favoritesChanged:(NSNotification *)notification;
@end

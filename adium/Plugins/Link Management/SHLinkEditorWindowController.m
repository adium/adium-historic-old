//
//  SHLinkEditorWindowController.m
//  Adium
//
//  Created by Stephen Holt on Sat Apr 17 2004.

#import "SHLinkEditorWindowController.h"
#import "SHAutoValidatingTextView.h"
#import "SHLinkLexer.h"

#define LINK_EDITOR_NIB_NAME        @"LinkEditor"
#define CHOOSE_URL                  AILocalizedString(@"Select...",nil)

@interface SHLinkEditorWindowController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName;
- (void)_buildPopUpMenu;
- (void)insertLinkTo:(NSString *)urlString withText:(NSString *)linkString inView:(NSResponder *)inView withRange:(NSRange)linkRange;
@end

@implementation SHLinkEditorWindowController

#pragma mark various init methods
- (void)initAddLinkWindowControllerWithResponder:(NSResponder *)responder
{
    if(nil != (editableView = responder)) {
        SHLinkEditorWindowController  *newLinkEditor;
        newLinkEditor = [self initWithWindowNibName:LINK_EDITOR_NIB_NAME];
        editLink = NO; //this is for a new link to be inserted
        favoriteWindow = NO;
        [newLinkEditor showWindow:nil];
    }
}

- (void)initEditLinkWindowControllerWithResponder:(NSResponder *)responder
{
    if(nil != (editableView = responder)) {
        SHLinkEditorWindowController    *linkEditor;
        linkEditor = [self initWithWindowNibName:LINK_EDITOR_NIB_NAME];
        editLink = YES; //this is to edit an existing link
        favoriteWindow = NO;
        [linkEditor showWindow:nil];
    }
}

- (void)initAddLinkFavoritesWindowController
{
    SHLinkEditorWindowController    *favsEditor;
    favsEditor = [self initWithWindowNibName:LINK_EDITOR_NIB_NAME];
    editLink = NO;
    favoriteWindow = YES;
    [favsEditor showWindow:nil];
}

- (id)initWithWindowNibName:(NSString *)windowNibName
{
    [super initWithWindowNibName:windowNibName];
    return(self);
}

- (void)dealloc
{
    [super dealloc];
}


#pragma mark Window Methods
- (void)windowDidLoad
{
    NSRange      localSelectionRange = NSMakeRange(0,0);
                 selectionRange = NSMakeRange(0,0);
    NSString    *linkText = nil;
    NSString    *linkURL = nil;
    
        //fetch the range of the selection
        localSelectionRange = [(NSTextView *)editableView selectedRange];
        
        selectionRange = localSelectionRange;
        
        //pop stuff into their proper fields for editing
        if(editLink) {
            linkText = [[(NSTextView *)editableView attributedSubstringFromRange:localSelectionRange] string];
            
            linkURL = [[(NSTextView *)editableView textStorage] attribute:NSLinkAttributeName
                                                  atIndex:localSelectionRange.location
                                           effectiveRange:&localSelectionRange];
            
            if(linkURL) {
                [[textView_URL textStorage] setAttributedString:[[NSAttributedString alloc]
                                                 initWithString:[linkURL string]]];
            }
            if(linkText) {
                [textField_linkText setStringValue:linkText];
            }
        }
    
    //retrive our favorites
    favoritesDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_LINK_FAVORITES];
    
    //notice changes
    [[adium notificationCenter] addObserver:self selector:@selector(favoritesChanged:) name:Preference_GroupChanged object:nil];
    
    //build the popUp menu for favorites
    [self _buildPopUpMenu];
        
    //turn on URL validation for our textView
    [textView_URL setContiniousURLValidationEnabled:YES];
    
    if(![NSApp isOnPantherOrBetter]){
        [imageView_invalidURLAlert setImage:[NSImage imageNamed:@"space" forClass:[self class]]];
    }
    [[self window] center];
}

- (void)_buildPopUpMenu
{
    NSString            *key;
    NSEnumerator        *enumerator;
    NSMenu              *menu = [popUp_Favorites menu];
    NSMenuItem          *menuItem;
    
    [popUp_Favorites removeAllItems];
    enumerator = [favoritesDict keyEnumerator];
    menuItem = [[[NSMenuItem alloc] init] autorelease];
    [menu addItem:menuItem];
    while(key = [enumerator nextObject]) {
        menuItem = [[[NSMenuItem alloc] initWithTitle:key
                                               target:nil
                                               action:nil
                                        keyEquivalent:@""] autorelease];
        [menuItem setRepresentedObject:[[adium preferenceController] preferenceForKey:key group:PREF_GROUP_LINK_FAVORITES]];
        [menu addItem:menuItem];
    }
    [popUp_Favorites setTitle:CHOOSE_URL];
}

- (BOOL)windowShouldClose:(id)sender
{
    selectionRange = NSMakeRange(0,0);
    return(YES);
}

- (IBAction)closeWindow:(id)sender;
{
    if([self windowShouldClose:nil]) {
        [[self window] close];
    }
}

- (IBAction)cancel:(id)sender;
{
    [self closeWindow:sender];
}

#pragma mark AttributedString Wrangleing Methods
- (IBAction)acceptURL:(id)sender;
{
    NSMutableString *urlString = nil;
    NSString        *linkString = nil;
    NSRange          linkRange = NSMakeRange(0,0);
    
    if(!favoriteWindow){
        //get our infos out from the text's
        urlString   = [[NSMutableString alloc] initWithString:[[textView_URL textStorage] string]];
        linkString  = [textField_linkText stringValue];
        linkRange   = selectionRange;
    
        switch([textView_URL validationStatus]){
            case SH_URL_DEGENERATE:
                [urlString insertString:@"http://" atIndex:0];
                break;
            case SH_MAILTO_DEGENERATE:
                [urlString insertString:@"mailto:" atIndex:0];
                break;
        }
    
        //call the insertion method
        [self insertLinkTo:[urlString string]
                  withText:linkString
                    inView:editableView
                 withRange:linkRange];
    }else{
        [self addURLToFavorites:nil];
    }
             
    [self closeWindow:nil];
}

- (void)insertLinkTo:(NSString *)urlString withText:(NSString *)linkString inView:(NSResponder *)inView withRange:(NSRange)linkRange
{
    NSMutableAttributedString   *tempURLString = nil;
    NSDictionary                *stringAttributes = nil;
    NSRange                      subStringRange = NSMakeRange(0,0);
    
    //get our typing attribs if they exist
    if([inView respondsToSelector:@selector(typingAttributes)]){
        stringAttributes = [(NSTextView *)inView typingAttributes];
    }
    
    //init a temporary string
    if(nil != stringAttributes) {
        tempURLString = [[[NSMutableAttributedString alloc] initWithString:linkString
                                                                attributes:stringAttributes] autorelease];
    }else{
        tempURLString = [[[NSMutableAttributedString alloc] initWithString:linkString] autorelease];
    }
    
    
    //make it a link
    subStringRange = NSMakeRange(0,[tempURLString length]);
    [tempURLString addAttribute:NSLinkAttributeName value:urlString range:subStringRange];
    //make it look like a link
    [tempURLString addAttribute:NSForegroundColorAttributeName
                          value:[NSColor blueColor]
                          range:subStringRange];
    [tempURLString addAttribute:NSUnderlineStyleAttributeName
                          value:[NSNumber numberWithInt:1]
                          range:subStringRange];

    if(editLink){ //replace selected text if editing
        [[(NSTextView *)inView textStorage] replaceCharactersInRange:linkRange withAttributedString:tempURLString];
    }else{ 
        if(nil != stringAttributes) { //make sure link attrib doesn't bleed into newly entered text
            [tempURLString appendAttributedString:[[[NSAttributedString alloc] initWithString:@" "
                                                                                   attributes:stringAttributes] autorelease]];
        }else{
            [tempURLString appendAttributedString:[[[NSAttributedString alloc] initWithString:@" "] autorelease]];
        }
        //insert link at insertion point
        [[(NSTextView *)inView textStorage] insertAttributedString:tempURLString atIndex:linkRange.location];
    }
}

#pragma mark Favorite URL Management
- (IBAction)selectFavoriteURL:(id)sender
{
    NSString        *linkText = nil;
    NSString        *linkURL = nil;
    
    //get our favorite and fill the text fields with it
    if([sender isKindOfClass:[NSPopUpButton class]]){
        linkText = [[(NSPopUpButton *)sender selectedItem] title];

        linkURL = [[adium preferenceController] preferenceForKey:linkText group:PREF_GROUP_LINK_FAVORITES];
                          
        [[textView_URL textStorage] setAttributedString:[[NSAttributedString alloc]
                                         initWithString:linkURL]];
        [textField_linkText setStringValue:linkText];
    }
}

- (IBAction)addURLToFavorites:(id)sender
{
    NSString                    *linkString = [textField_linkText stringValue];
    NSString                    *urlString  = [[textView_URL textStorage] string];
    
    //get our info form text fields and set a new pref/key for it
    [[adium preferenceController] setPreference:urlString forKey:linkString group:PREF_GROUP_LINK_FAVORITES];
    
    [self favoritesChanged:nil];
}

- (void)favoritesChanged:(NSNotification *)notification
{
    //refresh our favorites
    favoritesDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_LINK_FAVORITES];
    
    [self _buildPopUpMenu];
}

#pragma mark URL Validation and other Delegate Oddities
- (void)textDidChange:(NSNotification *)aNotification
{
    //validate our URL's
    [textView_URL textDidChange:aNotification];
    if([NSApp isOnPantherOrBetter]) {
        [imageView_invalidURLAlert setHidden:[textView_URL isURLValid]];
    }else{ //for those stuck in jag, we can't use setHidden
        if([textView_URL isURLValid]) {
            [imageView_invalidURLAlert setImage:[NSImage imageNamed:@"space" forClass:[self class]]];
        }else{
            [imageView_invalidURLAlert setImage:[NSImage imageNamed:@"ErrorAlert" forClass:[self class]]];
        }
    }
}

- (BOOL)textView:(NSTextView *)aTextView doCommandBySelector:(SEL)aSelector
{
    NSEvent *event = [NSApp currentEvent];
    unsigned short keyCode = [event keyCode];
    if(aSelector == @selector(insertNewline:))
    {
        if(keyCode == 36 || keyCode == 76 || keyCode == 52){
            [self acceptURL:nil];
            return YES;
        }
    }
    return NO;
}
@end

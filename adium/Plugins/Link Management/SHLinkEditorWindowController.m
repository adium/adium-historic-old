//
//  SHLinkEditorWindowController.m
//  Adium
//
//  Created by Stephen Holt on Sat Apr 17 2004.

#import "SHLinkEditorWindowController.h"
#import "SHAutoValidatingTextView.h"
#import "SHLinkLexer.h"

#define LINK_EDITOR_NIB_NAME        @"LinkEditor"
#define FAVS_EDITOR_NIB_NAME        @"FavsEditor"
#define CHOOSE_URL                  AILocalizedString(@"Select...",nil)

@interface SHLinkEditorWindowController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName forTextView:(NSTextView *)inTextView notifyingTarget:(id)inTarget;
- (void)_buildPopUpMenu;
- (void)insertLinkTo:(NSString *)urlString withText:(NSString *)linkString inView:(NSTextView *)inView;
- (void)informTargetOfLink;
@end

@implementation SHLinkEditorWindowController


//Init methods ---------------------------------------------------------------------------------------------------------
#pragma mark Init methods
+ (void)showLinkEditorForTextView:(NSTextView *)inTextView onWindow:(NSWindow *)parentWindow showFavorites:(BOOL)showFavorites notifyingTarget:(id)inTarget
{
	SHLinkEditorWindowController	*editorWindow = [[self alloc] initWithWindowNibName:(showFavorites ? LINK_EDITOR_NIB_NAME : FAVS_EDITOR_NIB_NAME)
																			forTextView:inTextView
																		notifyingTarget:inTarget];
	
	if(parentWindow){
		[NSApp beginSheet:[editorWindow window]
		   modalForWindow:parentWindow
			modalDelegate:editorWindow
		   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
			  contextInfo:nil];
	}else{
		[editorWindow showWindow:nil];
	}
}

- (id)initWithWindowNibName:(NSString *)windowNibName forTextView:(NSTextView *)inTextView notifyingTarget:(id)inTarget

{
    [super initWithWindowNibName:windowNibName];

	textView = [inTextView retain];
	target = [inTarget retain];
	
	return(self);
}

- (void)dealloc
{
	[textView release];
	[target release];
    [super dealloc];
}


//Window Methods -------------------------------------------------------------------------------------------------------
#pragma mark Window Methods
- (void)windowDidLoad
{
	if(textView){
		NSRange 	selectedRange = [textView selectedRange];
		NSRange		rangeOfLinkAttribute;
		NSString    *linkText;
		id   	 	linkURL = nil;
		
		//Get the selected link (We have to be careful when the selection is at the very end of our text view)
		if(selectedRange.location >= 0 && NSMaxRange(selectedRange) < [[textView textStorage] length]){
			linkURL = [[textView textStorage] attribute:NSLinkAttributeName
												atIndex:selectedRange.location
										 effectiveRange:&rangeOfLinkAttribute];
		}
		
		//If a link exists at our selection, expand the selection to encompass that entire link
		if(linkURL){
			[textView setSelectedRange:rangeOfLinkAttribute];
			selectedRange = rangeOfLinkAttribute;
		}
		
		//Get the selected text
		linkText = [[textView attributedSubstringFromRange:selectedRange] string];
		
		//Place the link title and URL in our panel
		if(linkURL){
			BOOL		isString = [linkURL isKindOfClass:[NSString class]];
			NSString	*tmpString = (isString ? [(NSString *)linkURL string] : [(NSURL *)linkURL absoluteString]);
			
			[[textView_URL textStorage] setAttributedString:[[[NSAttributedString alloc] initWithString:tmpString] autorelease]];                
		}
		if(linkText){
			[textField_linkText setStringValue:linkText];
		}
	}
    
    //Retrive our favorites
	favoritesDict = [[[adium preferenceController] preferenceForKey:KEY_LINK_FAVORITES group:PREF_GROUP_LINK_FAVORITES] mutableCopy];
	if(!favoritesDict) favoritesDict = [[NSMutableArray alloc] init];
		
    //notice changes
    [[adium notificationCenter] addObserver:self selector:@selector(favoritesChanged:) name:Preference_GroupChanged object:nil];
    
    //build the popUp menu for favorites
    [self _buildPopUpMenu];
        
    //turn on URL validation for our textView
    [textView_URL setContiniousURLValidationEnabled:YES];
    
    if(![NSApp isOnPantherOrBetter]){
        [imageView_invalidURLAlert setImage:[NSImage imageNamed:@"space" forClass:[self class]]];
    }
}

- (void)_buildPopUpMenu
{
    NSDictionary		*favorite;
    NSEnumerator        *enumerator;
    
	//Empty the menu and insert an empty menu item to serve as the pop-up button's selected item
    [[popUp_Favorites menu] removeAllItemsButFirst];

	//Add items for each link
    enumerator = [favoritesDict objectEnumerator];
    while(favorite = [enumerator nextObject]){
		[[popUp_Favorites menu] addItemWithTitle:[favorite objectForKey:KEY_LINK_TITLE]
										  target:self
										  action:nil
								   keyEquivalent:@""
							   representedObject:favorite];
    }
	
    [popUp_Favorites setTitle:CHOOSE_URL];
}

//Window is closing
- (BOOL)windowShouldClose:(id)sender
{
	[self autorelease];
    return(YES);
}

//Close this window
- (IBAction)closeWindow:(id)sender
{
    if([self windowShouldClose:nil]){
		if([[self window] isSheet]) [NSApp endSheet:[self window]];
        [[self window] close];
    }
}

//Called as the sheet closes, dismisses the sheet
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:nil];
}

//Cancel
- (IBAction)cancel:(id)sender
{
    [self closeWindow:sender];
}


//AttributedString Wrangleing Methods ----------------------------------------------------------------------------------
#pragma mark AttributedString Wrangleing Methods
- (IBAction)acceptURL:(id)sender
{
	if(textView){
		NSMutableString *urlString = [NSMutableString stringWithString:[[textView_URL textStorage] string]];
        NSString		*linkString  = [textField_linkText stringValue];
		
		//Pre-fix the url if necessary
        switch([textView_URL validationStatus]){
            case SH_URL_DEGENERATE:
                [urlString insertString:@"http://" atIndex:0];
			break;
            case SH_MAILTO_DEGENERATE:
                [urlString insertString:@"mailto:" atIndex:0];
			break;
            default:
			break;
        }
		
        //Insert it into the text view
        [self insertLinkTo:[urlString string] withText:linkString inView:textView];
	}

	//Inform our target of the new link and close up
	[self informTargetOfLink];
    [self closeWindow:nil];
}

//Inform our target of the link currently in our panel
- (void)informTargetOfLink
{
	//We need to make sure we're getting copies of these, otherwise the fields will change them later, changing the
	//copy in our dictionary
	NSDictionary	*linkDict = [NSDictionary dictionaryWithObjectsAndKeys:
		[[[textField_linkText stringValue] copy] autorelease], KEY_LINK_TITLE,
		[[[[textView_URL textStorage] string] copy] autorelease], KEY_LINK_URL,
		nil];
	
	if([target respondsToSelector:@selector(linkEditorLinkDidChange:)]){
		[target performSelector:@selector(linkEditorLinkDidChange:) withObject:linkDict];
	}
}

//Insert a link into a text view
- (void)insertLinkTo:(NSString *)linkURL withText:(NSString *)linkTitle inView:(NSTextView *)inView
{
    NSDictionary				*typingAttributes = [inView typingAttributes];
	NSMutableAttributedString	*linkString;

	//Create the link string
	linkString = [[[NSMutableAttributedString alloc] initWithString:linkTitle
															attributes:typingAttributes] autorelease];
    [linkString addAttribute:NSLinkAttributeName value:linkURL range:NSMakeRange(0,[linkString length])];
    
	//Insert it into the text view, replacing the current selection
	[[inView textStorage] replaceCharactersInRange:[inView selectedRange] withAttributedString:linkString];
		
	//If this link was inserted at the end of our text view, add a space and set the formatting back to normal
	//This preferents the link attribute from bleeding into newly entered text
	if(NSMaxRange([(NSTextView *)inView selectedRange]) == [[(NSTextView *)inView textStorage] length]){
		NSAttributedString	*tmpString = [[[NSAttributedString alloc] initWithString:@" "
																		  attributes:typingAttributes] autorelease];
		[[inView textStorage] appendAttributedString:tmpString];
	}
}


//Favorite URL Management ----------------------------------------------------------------------------------------------
#pragma mark Favorite URL Management
//User selected a link, display it in the text fields (Called by menu item)
- (IBAction)selectFavoriteURL:(NSPopUpButton *)sender
{
    if([sender isKindOfClass:[NSPopUpButton class]]){
		NSDictionary		*favorite = [[sender selectedItem] representedObject];
		NSAttributedString	*attrTitle = [[[NSAttributedString alloc] initWithString:[favorite objectForKey:KEY_LINK_URL]] autorelease];
		
        [[textView_URL textStorage] setAttributedString:attrTitle];
        [textField_linkText setStringValue:[favorite objectForKey:KEY_LINK_TITLE]];
    }
}

//- (IBAction)addURLToFavorites:(id)sender
//{
//    //get our info form text fields and set a new pref/key for it (We need to make sure we're getting copies of these,
//	//otherwise the fields will change them later, changing the copy in our dictionary)
//	[favoritesDict addObject:[NSDictionary dictionaryWithObjectsAndKeys:
//		[[[textField_linkText stringValue] copy] autorelease], KEY_LINK_TITLE,
//		[[[[textView_URL textStorage] string] copy] autorelease], KEY_LINK_URL,
//		nil]];
//    [[adium preferenceController] setPreference:favoritesDict forKey:KEY_LINK_FAVORITES group:PREF_GROUP_LINK_FAVORITES];
//    
//    [self favoritesChanged:nil];
//}

- (void)favoritesChanged:(NSNotification *)notification
{
    //refresh our favorites
	[favoritesDict release];
    favoritesDict = [[[adium preferenceController] preferenceForKey:KEY_LINK_FAVORITES group:PREF_GROUP_LINK_FAVORITES] mutableCopy];
    
    [self _buildPopUpMenu];
}


//URL Validation and other Delegate Oddities ---------------------------------------------------------------------------
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

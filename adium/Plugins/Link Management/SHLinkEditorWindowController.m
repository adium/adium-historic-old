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
- (id)initWithWindowNibName:(NSString *)windowNibName forResponder:(NSResponder *)responder;
- (void)_buildPopUpMenu;
- (void)insertLinkTo:(NSString *)urlString withText:(NSString *)linkString inView:(NSResponder *)inView; /*withRange:(NSRange)linkRange*/
@end

@implementation SHLinkEditorWindowController

#pragma mark init methods

+ (void)showLinkEditorForResponder:(NSResponder *)responder onWindow:(NSWindow *)parentWindow showFavorites:(BOOL)showFavorites
{
	SHLinkEditorWindowController	*editorWindow = [[self alloc] initWithWindowNibName:(showFavorites ? LINK_EDITOR_NIB_NAME : FAVS_EDITOR_NIB_NAME)
																		   forResponder:responder];
	
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

- (id)initWithWindowNibName:(NSString *)windowNibName forResponder:(NSResponder *)responder
{
    [super initWithWindowNibName:windowNibName];

	editableView = [responder retain];

	return(self);
}

- (void)dealloc
{
	[editableView release];
    [super dealloc];
}


//Window Methods -------------------------------------------------------------------------------------------------------
#pragma mark Window Methods
- (void)windowDidLoad
{
	if([editableView isKindOfClass:[NSTextView class]]){
		NSRange 	selectionRange = [(NSTextView *)editableView selectedRange];
		NSString    *linkText;
		id   	 	linkURL = nil;

		//Get the selected link
		if(selectionRange.location >= 0 && NSMaxRange(selectionRange) < [[(NSTextView *)editableView textStorage] length]){
			NSRange	scanRange;
			
			linkURL = [[(NSTextView *)editableView textStorage] attribute:NSLinkAttributeName
																  atIndex:selectionRange.location
														   effectiveRange:&scanRange];

		
			//If a link exists at our cursor, expand the selection to encompass that entire link
			if(linkURL){
				[(NSTextView *)editableView setSelectedRange:scanRange];
				selectionRange = scanRange;
			}
		}


		//Place the link title and URL in our fields
		linkText = [[(NSTextView *)editableView attributedSubstringFromRange:selectionRange] string];
		if(linkURL){
			if([linkURL isKindOfClass:[NSString class]]){
				[[textView_URL textStorage] setAttributedString:[[[NSAttributedString alloc]
                                                     initWithString:[(NSString *)linkURL string]] autorelease]];
			}else if([linkURL isKindOfClass:[NSURL class]]){
				[[textView_URL textStorage] setAttributedString:[[[NSAttributedString alloc]
                                                     initWithString:[(NSURL *)linkURL absoluteString]] autorelease]];                
			}
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
    if([self windowShouldClose:nil]) {
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
    NSMutableString *urlString = nil;
    NSString        *linkString = nil;
//    NSRange          linkRange = NSMakeRange(0,0);
    
#warning Use a delegate or target call to clean this up
	if([editableView isKindOfClass:[NSTextView class]]){
        //get our infos out from the text's
        urlString   = [[NSMutableString alloc] initWithString:[[textView_URL textStorage] string]];
        linkString  = [textField_linkText stringValue];
//        linkRange   = selectionRange;
    
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
    
        //call the insertion method
        [self insertLinkTo:[urlString string]
                  withText:linkString
                    inView:editableView/*
                 withRange:linkRange*/];
    }else{
        [self addURLToFavorites:nil];
    }
             
    [self closeWindow:nil];
}

- (void)insertLinkTo:(NSString *)urlString withText:(NSString *)linkString inView:(NSResponder *)inView /*withRange:(NSRange)linkRange*/
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
    /*[tempURLString addAttribute:NSForegroundColorAttributeName
                          value:[NSColor blueColor]
                          range:subStringRange];
    [tempURLString addAttribute:NSUnderlineStyleAttributeName
                          value:[NSNumber numberWithInt:1]
                          range:subStringRange];*/

//    if(editLink){ //replace selected text if editing
        [[(NSTextView *)inView textStorage] replaceCharactersInRange:[(NSTextView *)inView selectedRange] withAttributedString:tempURLString];
//    }else{ 
		
		
		//make sure link attrib doesn't bleed into newly entered text
		if(NSMaxRange([(NSTextView *)inView selectedRange]) == [[(NSTextView *)inView textStorage] length]){

			//        if(nil != stringAttributes) { 
			            [[(NSTextView *)inView textStorage] appendAttributedString:[[[NSAttributedString alloc] initWithString:@" "
			                                                                                   attributes:stringAttributes] autorelease]];
			 //       }else{
			 //           [tempURLString appendAttributedString:[[[NSAttributedString alloc] initWithString:@" "] autorelease]];
			 //       }
		}
		
//        //insert link at insertion point
////        [[(NSTextView *)inView textStorage] insertAttributedString:tempURLString atIndex:linkRange.location];
//    }



		//get our typing attribs if they exist
		//if([inView respondsToSelector:@selector(textStorage)]){
			[[(NSTextView *)inView textStorage] setAttributes:stringAttributes range:NSMakeRange(NSMaxRange([(NSTextView *)inView selectedRange]),0)];
		//}
		

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

- (IBAction)addURLToFavorites:(id)sender
{
    //get our info form text fields and set a new pref/key for it (We need to make sure we're getting copies of these,
	//otherwise the fields will change them later, changing the copy in our dictionary)
	[favoritesDict addObject:[NSDictionary dictionaryWithObjectsAndKeys:
		[[[textField_linkText stringValue] copy] autorelease], KEY_LINK_TITLE,
		[[[[textView_URL textStorage] string] copy] autorelease], KEY_LINK_URL,
		nil]];
    [[adium preferenceController] setPreference:favoritesDict forKey:KEY_LINK_FAVORITES group:PREF_GROUP_LINK_FAVORITES];
    
    [self favoritesChanged:nil];
}

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

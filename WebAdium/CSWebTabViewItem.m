#import "CSWebTabViewItem.h"
#import "CSWebViewController.h"
#import "CSWebWindowController.h"

#define LABEL_SIDE_PAD		0

@interface CSWebTabViewItem (PRIVATE)

- (id)initWithWebView:(CSWebViewController *)inWebView;
- (void)drawLabel:(BOOL)shouldTruncateLabel inRect:(NSRect)labelRect;
- (NSSize)sizeOfLabel:(BOOL)computeMin;
- (NSAttributedString *)attributedLabelStringWithColor:(NSColor *)textColor;

@end

@implementation CSWebTabViewItem

+ (CSWebTabViewItem *)webTabWithView:(CSWebViewController *)inWebView
{
	return([[[self alloc] initWithWebView:inWebView] autorelease]);
}

//init
- (id)initWithWebView:(CSWebViewController *)inWebView
{
    [super initWithIdentifier:nil];
	
    webView = [inWebView retain];	
    //Configure ourself for the web view
    [webView setDelegate:self];
    //[self messageViewController:messageView chatChangedTo:[messageView chat]];
	
    //Set our contents
    [self setView:[webView view]];
    
    return(self);
}

//
- (void)dealloc
{
    [webView release];
	[super dealloc];
}

- (void)makeActive:(id)sender
{
	NSTabView	*tabView = [self tabView];
    NSWindow	*window	= [tabView window];
	
    if([tabView selectedTabViewItem] != self){
        [tabView selectTabViewItem:self]; //Select our tab
    }
	
    if(![window isKeyWindow]){
        [window makeKeyAndOrderFront:nil]; //Bring our window to the front
    }
}

- (void)close:(id)sender
{
	[[self tabView] removeTabViewItem:self];
}

- (CSWebViewController *)webViewController
{
	return(webView);
}

- (void)tabViewItemWasSelected
{
	
}

//Drawing
- (void)drawLabel:(BOOL)shouldTruncateLabel inRect:(NSRect)labelRect
{
    BOOL		texturedWindow = [[[self tabView] window] isTextured];
    NSColor		*textColor = nil;
    BOOL		selected;
    
    //Disable sub-pixel rendering.  It looks horrible with embossed text
    CGContextSetShouldSmoothFonts([[NSGraphicsContext currentContext] graphicsPort], 0);
	
    //
    selected = ([[self tabView] selectedTabViewItem] == self);
    textColor = [NSColor blackColor];
    if(!textColor) textColor = (texturedWindow ? [NSColor colorWithCalibratedWhite:0.16 alpha:1.0] : [NSColor controlTextColor]);
	
    //Emboss the name (Textured window only)
    if(texturedWindow){
		if([textColor colorIsDark]){
			[[self attributedLabelStringWithColor:[NSColor colorWithCalibratedWhite:1.0 alpha:0.4]]
                                    drawInRect:NSOffsetRect(labelRect, 0, -1)];
		}else{
			[[self attributedLabelStringWithColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.4]]
                                    drawInRect:NSOffsetRect(labelRect, 0, -1)];
		}
    }
	
    [[self attributedLabelStringWithColor:textColor] drawInRect:labelRect];
}

- (NSSize)sizeOfLabel:(BOOL)computeMin
{
    NSSize		size = [[self attributedLabelStringWithColor:[NSColor blackColor]] size]; //Name width
	
    //Padding
    size.width += LABEL_SIDE_PAD * 2;
	
    //Make sure we return an even integer width
    if(size.width != (int)size.width){
        size.width = (int)size.width + 1;
    }
	
    return(size);
}

//
- (NSString *)labelString
{
    return [webView title];
}

//
- (NSAttributedString *)attributedLabelStringWithColor:(NSColor *)textColor
{
    BOOL		    texturedWindow = [[[self tabView] window] isTextured];
    NSFont		    *font = (texturedWindow ? [NSFont boldSystemFontOfSize:11] : [NSFont systemFontOfSize:11]);
    NSAttributedString      *displayName;
    NSParagraphStyle	    *paragraphStyle;
	
    //Paragraph Style (Turn off clipping by word)
    paragraphStyle = [NSParagraphStyle styleWithAlignment:NSCenterTextAlignment lineBreakMode:NSLineBreakByClipping];
	
    //Name
    displayName = [[NSAttributedString alloc] initWithString:[self labelString] attributes:
		[NSDictionary dictionaryWithObjectsAndKeys:
			font, NSFontAttributeName,
			paragraphStyle, NSParagraphStyleAttributeName,
			textColor, NSForegroundColorAttributeName,
			nil]];
	
    return([displayName autorelease]);
}

- (void)titleHasChanged
{
	if ([self labelString])
		[[[self tabView] window] setTitle:[self labelString]];
	[[[[[self tabView] window] windowController] customTabsView] resizeTabs];
}

@end

/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2004, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
 | This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 | General Public License as published by the Free Software Foundation; either version 2 of the License,
 | or (at your option) any later version.
 |
 | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 | Public License for more details.
 |
 | You should have received a copy of the GNU General Public License along with this program; if not,
 | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 \------------------------------------------------------------------------------------------------------ */
#import <unistd.h>
#import "AISCLViewController.h"
#import "AISCLCell.h"
#import "AIStandardListOutlineView.h"
#import "AISCLViewPlugin.h"
#import "AIListCell.h"


#define MAX_DISCLOSURE_HEIGHT				13		//Max height/width for our disclosure triangles

#define	PREF_GROUP_DUAL_WINDOW_INTERFACE	@"Dual Window Interface"
#define KEY_DUAL_RESIZE_HORIZONTAL			@"Autoresize Horizontal"

#define PREF_GROUP_CONTACT_STATUS_COLORING	@"Contact Status Coloring"

@interface AISCLViewController (PRIVATE)
- (void)contactListChanged:(NSNotification *)notification;
- (void)contactOrderChanged:(NSNotification *)notification;
- (void)contactAttributesChanged:(NSNotification *)notification;
- (void)preferencesChanged:(NSNotification *)notification;
- (void)frameDidChange:(NSNotification *)notification;
- (void)mouseEntered:(NSEvent *)theEvent;
- (void)mouseExited:(NSEvent *)theEvent;
- (void)_installCursorRect;
- (void)_removeCursorRect;
- (void)_startTrackingMouse;
- (void)_stopTrackingMouse;
- (void)_killMouseMovementTimer;
- (void)_showTooltipAtPoint:(NSPoint)screenPoint;
- (void)_desiredSizeChanged;
- (void)_configureTransparencyAndShadows;
- (void)_hideTooltip;
- (void)_endTrackingMouse;
@end

@interface NSObject (_AIRespondsToUpdateShadows)
- (void)setUpdateShadowsWhileScrolling:(BOOL)update;
@end

@implementation AISCLViewController

+ (AISCLViewController *)contactListViewController
{
    return([[[self alloc] init] autorelease]);    
}

- (AISCLViewController *)init
{
    [super init];

    //Init
    tooltipTrackingTag = -1;
	inDrag = NO;
	windowHidesOnDeactivate = NO;
	alreadyDidDealloc = NO;
	dragItems = nil;
	tooltipMouseLocationTimer = nil;
    tooltipCount = 0;
	lastMouseLocation = NSMakePoint(0,0);
	tooltipLocation = NSMakePoint(0,0);
	
	contactListView = [[AIStandardListOutlineView alloc] initWithFrame:NSMakeRect(0,0,100,100)]; //Arbitrary frame
//	[contactListView addTableColumn:[[NSTableColumn alloc] initWithIdentifier:@"moo"]];
//	[contactListView reloadData];
#warning put in nib?
	NSTableColumn	*column = [[NSTableColumn alloc] initWithIdentifier:@"moo"];
	[column setDataCell:[[[AIListCell alloc] init] autorelease]];
	[contactListView addTableColumn:column];
	[contactListView setDelegate:self];
	
	
	//
	[contactListView registerForDraggedTypes:[NSArray arrayWithObject:@"AIListObject"]];
	
    //Install the necessary observers
    [[adium notificationCenter] addObserver:self selector:@selector(contactListChanged:) 
									   name:Contact_ListChanged
									 object:nil];
    [[adium notificationCenter] addObserver:self selector:@selector(contactOrderChanged:)
									   name:Contact_OrderChanged 
									 object:nil];
    [[adium notificationCenter] addObserver:self selector:@selector(listObjectAttributesChanged:) 
									   name:ListObject_AttributesChanged
									 object:nil];
    [[adium notificationCenter] addObserver:self selector:@selector(preferencesChanged:) 
									   name:Preference_GroupChanged 
									 object:nil];

	
	
    //Watch for resolution and screen configuration changes
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
														   selector:@selector(screenParametersChanged:) 
															   name:NSApplicationDidChangeScreenParametersNotification 
															 object:nil];
	
    [contactListView setTarget:self];
    [contactListView setDataSource:self];
    [contactListView setDelegate:self];
    [contactListView setDoubleAction:@selector(performDefaultActionOnSelectedContact:)];
	
	//Fetch and update the contact list
    [self contactListChanged:nil];
	
    //Apply the preferences to our view - needs to happen _after_ fetching & updating the contact list
    [self preferencesChanged:nil];
				
    return(self);
}

- (AIListCell *)outlineViewDataCell
{
	return([[AIListCell alloc] init]);
}

- (void)dealloc
{    
    //Remove observers (general)
    [[adium notificationCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];

	//Make sure the view stops observing, too, in case the dealloc order is not the expected one
    [[NSNotificationCenter defaultCenter] removeObserver:contactListView];
	
    //Hide any open tooltips
	[self _removeCursorRect];
	
	//Mark that we're done and therefore should not respond to further requests
	alreadyDidDealloc = YES;
	
    //Close down and release the view
    [contactListView setTarget:nil];
    [contactListView setDataSource:nil];
    [contactListView setDelegate:nil];
    [contactListView release]; contactListView = nil;
	
    [super dealloc];
}

//Return our contact list view
- (NSView *)contactListView
{
    return(contactListView);
}


//A contact list preference has changed
- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] isEqualToString:PREF_GROUP_CONTACT_LIST_DISPLAY]){
        NSDictionary	*prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_CONTACT_LIST_DISPLAY];
		
        NSColor		*color = [[prefDict objectForKey:KEY_SCL_CONTACT_COLOR] representedColor];
        NSColor		*groupColor = [[prefDict objectForKey:KEY_SCL_GROUP_COLOR] representedColor];
        BOOL		alternatingGrid = [[prefDict objectForKey:KEY_SCL_ALTERNATING_GRID] boolValue];
        BOOL		customGroupColor = [[prefDict objectForKey:KEY_SCL_CUSTOM_GROUP_COLOR] boolValue];
        BOOL		boldGroups = [[prefDict objectForKey:KEY_SCL_BOLD_GROUPS] boolValue];
        		
        BOOL		showLabels = [[prefDict objectForKey:KEY_SCL_SHOW_LABELS] boolValue];
        BOOL		labelAroundContactOnly = [[prefDict objectForKey:KEY_SCL_LABEL_AROUND_CONTACT] boolValue];
        BOOL		outlineLabels = [[prefDict objectForKey:KEY_SCL_OUTLINE_LABELS] boolValue];
		BOOL		useGradient = [[prefDict objectForKey:KEY_SCL_USE_GRADIENT] boolValue];
		float		labelOpacity = [[prefDict objectForKey:KEY_SCL_LABEL_OPACITY] floatValue];

        //outlineGroups only works on Panther or better
        BOOL		outlineGroups = ([[prefDict objectForKey:KEY_SCL_OUTLINE_GROUPS] boolValue] && [NSApp isOnPantherOrBetter]);
        NSColor		*outlineGroupsColor = [[prefDict objectForKey:KEY_SCL_OUTLINE_GROUPS_COLOR] representedColor];
		
        BOOL		labelGroups = [[prefDict objectForKey:KEY_SCL_LABEL_GROUPS] boolValue];
        NSColor		*labelGroupsColor = [[prefDict objectForKey:KEY_SCL_LABEL_GROUPS_COLOR] representedColor];
        
        float		alpha = [[prefDict objectForKey:KEY_SCL_OPACITY] floatValue];
		
		tooltipShouldDisplay = [[prefDict objectForKey:KEY_SCL_SHOW_TOOLTIPS] boolValue];

        //Contact and group fonts
        NSFont  *font = [[prefDict objectForKey:KEY_SCL_FONT] representedFont];
		NSFont	*boldFont = [[NSFontManager sharedFontManager] convertFont:font toHaveTrait:NSBoldFontMask];
		if(!boldFont) boldFont = font;
		[contactListView setFont:font];
#warning ###		[contactListView setGroupFont:(boldGroups ? boldFont : font)];
		
        //Row Height and spacing
        float 	fontHeight = [font defaultLineHeightForFont];
        if(boldFont){
            float boldHeight = [boldFont defaultLineHeightForFont];            
            if(boldHeight > fontHeight) fontHeight = boldHeight;
        }
        [contactListView setRowHeight:fontHeight];
        [contactListView setIntercellSpacing:NSMakeSize(3.0,[[prefDict objectForKey:KEY_SCL_SPACING] floatValue])];      
		
		
		/////////////////////////
		{
#warning ###			float capHeight = [[contactListView groupFont] capHeight];
#warning ###			[contactListView setIndentationPerLevel:(capHeight > MAX_DISCLOSURE_HEIGHT ? MAX_DISCLOSURE_HEIGHT : capHeight)];
		}
		///////////////
		
		
		
		
        NSColor		*backgroundColor = [[prefDict objectForKey:KEY_SCL_BACKGROUND_COLOR] representedColorWithAlpha:alpha];
        NSColor		*gridColor = [[prefDict objectForKey:KEY_SCL_GRID_COLOR] representedColorWithAlpha:alpha];
          
        //Colors
#warning ###        [contactListView setShowLabels:showLabels];
#warning ###        if (showLabels) {
#warning ###            [contactListView setOutlineLabels:outlineLabels];
#warning ###			[contactListView setUseGradient:useGradient];
#warning ###            [contactListView setLabelOpacity:labelOpacity];
#warning ###        }
        
#warning ###        [contactListView setLabelAroundContactOnly:labelAroundContactOnly];
#warning ###        [contactListView setColor:color];
#warning ###        [contactListView setGroupColor:(customGroupColor ? groupColor : color)];
        [contactListView setBackgroundColor:backgroundColor];
        [(NSScrollView *)[[contactListView superview] superview] setDrawsBackground:NO];
        
#warning ###        if (outlineGroups)
#warning ###            [contactListView setOutlineGroupColor:outlineGroupsColor];          
#warning ###        else
#warning ###            [contactListView setOutlineGroupColor:nil];
        
#warning ###        if (labelGroups)
#warning ###            [contactListView setLabelGroupColor:labelGroupsColor];
#warning ###        else
#warning ###            [contactListView setLabelGroupColor:nil];
        
        //Grid
#warning ###        [contactListView setDrawsAlternatingRows:alternatingGrid];
#warning ###        [contactListView setAlternatingRowColor:gridColor];

		//Opacity, Shadows
		[self _configureTransparencyAndShadows];
				
#warning ###		[contactListView _performFullRecalculation];
    }
   
    //Resizing
    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] isEqualToString:PREF_GROUP_DUAL_WINDOW_INTERFACE]){
        //This is sloppy, we shouldn't be reading the interface plugin's preferences
        //We need to convert the desired size of SCLOutlineView to a lazy cache, so we can always tell it to resize from here
        //and not care what the interface is doing with the information.
        NSDictionary    *notOurPrefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_DUAL_WINDOW_INTERFACE];
        horizontalResizingEnabled = [[notOurPrefDict objectForKey:KEY_DUAL_RESIZE_HORIZONTAL] boolValue];
    }

	if ([(NSString *)[[notification userInfo] objectForKey:@"Group"] isEqualToString:PREF_GROUP_CONTACT_STATUS_COLORING]){
		//Update the display if the coloring we're using on our contacts changed.
		[contactListView display];
	}
}

//Configure the transparency and shadowing of the window containing our list
- (void)_configureTransparencyAndShadows
{
	if([contactListView window]){
		NSDictionary	*prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_CONTACT_LIST_DISPLAY];
		float   		alpha = [[prefDict objectForKey:KEY_SCL_OPACITY] floatValue];
		BOOL			hasShadow = [[prefDict objectForKey:KEY_SCL_SHADOWS] boolValue];
				
		//Shadow
		[[contactListView window] setHasShadow:hasShadow];
		if([[contactListView enclosingScrollView] respondsToSelector:@selector(setUpdateShadowsWhileScrolling:)]){
			[[contactListView enclosingScrollView] setUpdateShadowsWhileScrolling:((alpha != 1.0) && hasShadow)];
		}
		[[contactListView window] setOpaque:(alpha == 1.0)];
#warning ###		[contactListView setUpdateShadowsWhileDrawing:((alpha != 1.0) && hasShadow)];

		//Force a redraw of the window and shadow
		[[contactListView window] compatibleInvalidateShadow];
		[[contactListView window] setViewsNeedDisplay:YES];
	}
}










	
@end

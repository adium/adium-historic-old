//
//  AIListLayoutWindowController.h
//  Adium
//
//  Created by Adam Iser on Sun Aug 01 2004.
//

@interface AIListLayoutWindowController : AIWindowController {
	IBOutlet		NSPopUpButton		*popUp_contactTextAlignment;
	IBOutlet		NSPopUpButton		*popUp_groupTextAlignment;
	IBOutlet		NSPopUpButton		*popUp_windowStyle;
	IBOutlet		NSPopUpButton		*popUp_extendedStatusStyle;
	IBOutlet		NSPopUpButton		*popUp_extendedStatusPosition;
	IBOutlet		NSPopUpButton		*popUp_userIconPosition;
	IBOutlet		NSPopUpButton		*popUp_statusIconPosition;
	IBOutlet		NSPopUpButton		*popUp_serviceIconPosition;

	IBOutlet		NSButton			*checkBox_userIconVisible;
	IBOutlet		NSButton			*checkBox_extendedStatusVisible;
	IBOutlet		NSButton			*checkBox_statusIconsVisible;
	IBOutlet		NSButton			*checkBox_serviceIconsVisible;
	IBOutlet		NSButton			*checkBox_windowHasShadow;
	IBOutlet		NSButton			*checkBox_verticalAutosizing;
	IBOutlet		NSButton			*checkBox_horizontalAutosizing;

	IBOutlet		NSTextField			*textField_horizontalWidthText;
	IBOutlet		NSSlider			*slider_horizontalWidth;
	IBOutlet		NSTextField			*textField_horizontalWidthIndicator;
	
	IBOutlet		NSSlider			*slider_userIconSize;
	IBOutlet		NSTextField			*textField_userIconSize;
	IBOutlet		NSSlider			*slider_contactSpacing;
	IBOutlet		NSTextField			*textField_contactSpacing;
	IBOutlet		NSSlider			*slider_groupTopSpacing;
	IBOutlet		NSTextField			*textField_groupTopSpacing;
	IBOutlet		NSSlider			*slider_groupBottomSpacing;
	IBOutlet		NSTextField			*textField_groupBottomSpacing;
	IBOutlet		NSSlider			*slider_windowTransparency;
	IBOutlet		NSTextField			*textField_windowTransparency;
	IBOutlet		NSSlider			*slider_contactLeftIndent;
	IBOutlet		NSTextField			*textField_contactLeftIndent;
	IBOutlet		NSSlider			*slider_contactRightIndent;
	IBOutlet		NSTextField			*textField_contactRightIndent;
	
	IBOutlet		JVFontPreviewField	*fontField_contact;	
	IBOutlet		JVFontPreviewField	*fontField_status;	
	IBOutlet		JVFontPreviewField	*fontField_group;	
	
	IBOutlet		NSTextField			*textField_layoutName;

	NSString				*layoutName;
}

+ (id)listLayoutOnWindow:(NSWindow *)parentWindow withName:(NSString *)inName;
- (IBAction)cancel:(id)sender;
- (IBAction)okay:(id)sender;
- (void)preferenceChanged:(id)sender;

@end

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

#import "AILinkTextView.h"

@interface LNAboutBoxController : AIWindowController {
	IBOutlet	NSPanel		*panel_licenseSheet;
	IBOutlet	NSTextView	*textView_license;
	
    IBOutlet	NSButton	*button_duckIcon;
    IBOutlet	NSButton	*button_buildButton;
    IBOutlet	NSTextField	*textField_version;
    IBOutlet	NSTextView	*textView_credits;

	//Version and duck clicking
    NSString 				*buildNumber, *buildDate;
    int						numberOfDuckClicks, numberOfBuildFieldClicks;
    
	//Scrolling
    NSTimer					*scrollTimer;
    float					scrollLocation;
    int						maxScroll;
    float               	scrollRate;
}

+ (LNAboutBoxController *)aboutBoxController;
- (IBAction)closeWindow:(id)sender;
- (IBAction)adiumDuckClicked:(id)sender;
- (IBAction)buildFieldClicked:(id)sender;
- (IBAction)visitHomepage:(id)sender;
- (IBAction)showLicense:(id)sender;
- (IBAction)hideLicense:(id)sender;

@end

/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2005, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

#import <Cocoa/Cocoa.h>

@class AIAccountProxySettings, AIAccountViewController;

@interface AIEditAccountWindowController : AIWindowController {
	//Account preferences
	IBOutlet	NSImageView					*image_serviceIcon;
	IBOutlet	NSTextField					*textField_accountDescription;
	IBOutlet	NSTextField					*textField_serviceName;
	IBOutlet	ESImageViewWithImagePicker  *imageView_userIcon;
    IBOutlet	NSTabView					*tabView_auxiliary;

	//Replacable views
	IBOutlet	NSView						*view_accountSetup;
	IBOutlet	NSView						*view_accountProxy;
	IBOutlet	NSView						*view_accountProfile;
	IBOutlet	NSView						*view_accountOptions;

	//Current configuration
    AIAccountViewController		*accountViewController;
	AIAccountProxySettings 		*accountProxyController;
	AIAccount					*account;
	
	//Delete if the sheet is canceled (should be YES when called on a new account, NO otherwise)
	BOOL	deleteIfCanceled;
}

+ (void)editAccount:(AIAccount *)account onWindow:(id)parentWindow deleteIfCanceled:(BOOL)inDeleteIfCanceled;
- (IBAction)cancel:(id)sender;
- (IBAction)okay:(id)sender;

@end

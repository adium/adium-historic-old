/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2003, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

@class	AISendingTextView;

@interface AIAwayStatusWindowController : AIWindowController
{
    IBOutlet NSButton 		*button_comeBack;
    IBOutlet NSTextView 	*textView_awayMessage;
    IBOutlet NSTextField	*textField_awayTime;
    IBOutlet NSButton           *button_mute;
    IBOutlet NSButton           *button_showBezel;
    
    NSDate	*awayDate;
    NSTimer	*awayTimer;
    NSString 	*timeStampFormat;
}

+ (AIAwayStatusWindowController *)awayStatusWindowController;
+ (void)updateAwayStatusWindow;
+ (void)setWindowVisible:(bool)visible;
- (IBAction)comeBack:(id)sender;
- (void)updateWindow;
- (void)setVisible:(bool)visible;
- (IBAction)toggleMute:(id)sender;
- (IBAction)toggleShowBezel:(id)sender;
@end

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

#import "IdleTimePlugin.h"

@class AIAccountController, AIIdleTimePlugin;

@interface IdleTimeWindowController : NSWindowController
{
    AIIdleTimePlugin            *plugin;

    IBOutlet 	NSPopUpButton   *popUp_Accounts;
    IBOutlet	NSButton        *checkBox_SetManually;
    IBOutlet	NSTextField     *textField_IdleDays;
    IBOutlet	NSTextField     *textField_IdleHours;
    IBOutlet	NSTextField     *textField_IdleMinutes;
    IBOutlet	NSStepper       *stepper_IdleDays;
    IBOutlet	NSStepper       *stepper_IdleHours;
    IBOutlet	NSStepper       *stepper_IdleMinutes;
    IBOutlet	NSButton        *button_Apply;
}

+ (id)idleTimeWindowControllerForPlugin:(AIIdleTimePlugin *)inPlugin;
- (id)initWithWindowNibName:(NSString *)windowNibName forPlugin:(AIIdleTimePlugin *)inPlugin;
- (IBAction)apply:(id)sender;
- (IBAction)configureControls:(id)sender;
+ (void)closeSharedInstance;
- (IBAction)closeWindow:(id)sender;
- (BOOL)windowShouldClose:(id)sender;

@end

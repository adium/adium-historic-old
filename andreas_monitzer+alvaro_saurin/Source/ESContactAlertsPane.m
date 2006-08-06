/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "ESContactAlertsPane.h"
#import <Adium/ESContactAlertsViewController.h>

/*!
 * @class ESContactAlertsPane
 * @brief Get Info window pane which configures an ESContactAlertsViewController instance
 */
@implementation ESContactAlertsPane

/*!
 * @brief Category
 */
- (CONTACT_INFO_CATEGORY)contactInfoCategory{
    return AIInfo_Alerts;
}
/*!
 * @brief Nib name
 */
- (NSString *)nibName{
    return @"ContactAlerts";
}

/*!
 * @brief Configure the ESContactAlertsViewController for a list object
 */
- (void)configureForListObject:(AIListObject *)inObject{
	[contactAlertsViewController configureForListObject:inObject];
}

/*!
 * @brief View will close
 */
- (void)viewWillClose
{
	[contactAlertsViewController viewWillClose];
	
	[super viewWillClose];
}
@end

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

#import "ErrorMessageHandlerPlugin.h"
#import <AIUtilities/AIUtilities.h>
#import "ErrorMessageWindowController.h"


@implementation ErrorMessageHandlerPlugin

- (void)installPlugin
{
    //Install our observers
    [[owner notificationCenter] addObserver:self selector:@selector(handleError:) name:Interface_ErrorMessageReceived object:nil];
}

- (void)uninstallPlugin
{
    [ErrorMessageWindowController closeSharedInstance]; //Close the error window
}

- (void)handleError:(NSNotification *)notification
{
    NSDictionary	*userInfo;
    NSString		*errorTitle;
    NSString		*errorDesc;
    NSString		*windowTitle;
    
    //Get the error info
    userInfo = [notification userInfo];
    errorTitle = [userInfo objectForKey:@"Title"];
    errorDesc = [userInfo objectForKey:@"Description"];
    windowTitle = [userInfo objectForKey:@"Window Title"];

    //Log to console
    NSLog([NSString stringWithFormat:@"%@: %@ (%@)",windowTitle,errorTitle,errorDesc]);

    //Display an alert
    [[ErrorMessageWindowController errorMessageWindowControllerWithOwner:owner] displayError:errorTitle withDescription:errorDesc withTitle:windowTitle];
}

@end

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
/** 
 * $Revision: 1.47 $
 *  $Date: 2004/08/23 17:23:12 $
 *  $Author#
 *
 **/

//Localization
#ifndef AILocalizedString
#define AILocalizedString(key, comment) [[NSBundle bundleForClass: [self class]] localizedStringForKey: (key) value:@"" table:nil]
#endif

//Static strings
#ifndef DeclareString
#define DeclareString(var)			static NSString * (var) = nil;
#endif
#ifndef InitString
#define InitString(var,string)		if (! (var) ) (var) = [(string) retain];
#endif
#ifndef ReleaseString
#define ReleaseString(var)			if ( (var) ) { [(var) release]; (var) = nil; } 
#endif

//First, as other objects are generally subclasses of AIObject
//#import "AIObject.h"

//#import "ESObjectWithStatus.h"

#import "AIAccount.h"
#import "AIAccountViewController.h"
#import "AIActionDetailsPane.h"
#import "AIChat.h"
#import "AIContentMessage.h"
#import "AIContentContext.h"
#import "AIContentObject.h"
#import "AIContentStatus.h"
#import "AIContentTyping.h"
#import "AIEmoticon.h"
#import "AIException.h"
#import "ESFileTransfer.h"
#import "AIIconState.h"
#import "AIListContact.h"
#import "AIListGroup.h"
#import "AIListObject.h"
#import "AIMessageEntryTextView.h"
#import "AIMetaContact.h"
#import "AIModularPane.h"
#import "AIModularPaneCategoryView.h"
#import "AIContactInfoPane.h"
#import "AIPlugin.h"
#import "AIPreferencePane.h"
#import "AIEmoticonPreferences.h"
#import "AIServiceType.h"
#import "AISortController.h"
#import "AIWindowController.h"
#import "AIContextMenuTextView.h"
#import "DCJoinChatViewController.h"
#import "AIAbstractListWindowController.h"
//#import "DCJoinChatWindowController.h"

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

//Localization
#ifndef AILocalizedString
#define AILocalizedString(key, comment) NSLocalizedStringFromTableInBundle(key,nil,[NSBundle bundleForClass: [self class]],comment)
#define AILocalizedStringFromTable(key, table, comment) NSLocalizedStringFromTableInBundle(key,table,[NSBundle bundleForClass: [self class]],comment)
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

#import "AIAccount.h"
#import "AIService.h"
#import "AIAccountViewController.h"
#import "AIActionDetailsPane.h"
#import "AIChat.h"
#import "AIContentMessage.h"
#import "AIContentContext.h"
#import "AIContentObject.h"
#import "AIContentStatus.h"
#import "AIContentTyping.h"
#import "AIEmoticon.h"
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
#import "AISortController.h"
#import "AIWindowController.h"
#import "AIContextMenuTextView.h"
#import "DCJoinChatViewController.h"
#import "AIListOutlineView.h"
#import "AIAbstractListController.h"
#import "AIUserIcons.h"
#import "AIServiceIcons.h"
#import "AIStatusIcons.h"
#import "AIEditStateWindowController.h"

#import "AILocalizationAssistance.h"


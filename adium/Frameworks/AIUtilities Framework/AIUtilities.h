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

//Localization
#ifndef AILocalizedString
#define AILocalizedString(key, comment) [[NSBundle bundleForClass: [self class]] localizedStringForKey: (key) value:@"" table:nil]
#endif

//Static strings
//#ifndef DeclareString
#define DeclareString(var)			static NSString * (var) = nil;
//#endif
//#ifndef InitString
#define InitString(var,string)		if (! (var) ) (var) = [(string) retain];
//#endif
//#ifndef ReleaseString
#define ReleaseString(var)			if ( (var) ) { [(var) release]; (var) = nil; } 
//#endif

#import "AIAlternatingRowOutlineView.h"
#import "AIAlternatingRowTableView.h"
#import "AIAnimatedFloater.h"
#import "AIAnimatedView.h"
#import "AIAppleScriptAdditions.h"
#import "AIAttributedStringAdditions.h"
#import "AIAutoScrollView.h"
#import "AIBezierPathAdditions.h"
#import "AIColorAdditions.h"
#import "AIColorSelectionPopUpButton.h"
#import "AIColoredBoxView.h"
#import "AICompletingTextField.h"
#import "AICursorAdditions.h"
#import "AICustomTabCell.h"
#import "AICustomTabDragging.h"
#import "AICustomTabsView.h"
#import "AIDictionaryAdditions.h"
#import "AIDockingWindow.h"
#import "AIEventAdditions.h"
#import "AIFileManagerAdditions.h"
#import "AIFlexibleTableView.h"
#import "AIFontAdditions.h"
#import "AIGradient.h"
#import "AIGradientCell.h"
#import "AIHTMLDecoder.h"
#import "AIImageTextCell.h"
#import "AIKeychain.h"
#import "AILinkTextView.h"
#import "AILinkTrackingController.h"
#import "AIMenuAdditions.h"
#import "AIMultiCellOutlineView.h"
#import "AIMutableOwnerArray.h"
#import "AIOutlineView.h"
#import "AIParagraphStyleAdditions.h"
#import "AIPlasticButton.h"
#import "AIPlasticMinusButton.h"
#import "AIPlasticPlusButton.h"
#import "AIPopUpButtonAdditions.h"
#import "AIScaledImageCell.h"
#import "AIScrollViewAdditions.h"
#import "AISendingTextView.h"
#import "AISleepNotification.h"
#import "AISmartStepper.h"
#import "AISmoothTooltipTracker.h"
#import "AISocket.h"
#import "AIStringAdditions.h"
#import "AIStringFormatter.h"
#import "AITabViewAdditions.h"
#import "AITableViewAdditions.h"
#import "AITableViewPopUpButtonCell.h"
#import "AITextAttachmentExtension.h"
#import "AITextAttributes.h"
#import "AITextFieldAdditions.h"
#import "AIToolbarUtilities.h"
#import "AITooltipUtilities.h"
#import "AIVerticallyCenteredTextCell.h"
#import "AIViewAdditions.h"
#import "AIWindowAdditions.h"
#import "BZArrayAdditions.h"
#import "BZContextImageBridge.h"
#import "BZFontManagerAdditions.h"
#import "BZGenericViewCell.h"
#import "CBApplicationAdditions.h"
#import "CBObjectAdditions.h"
#import "ESArrayAdditions.h"
#import "ESBorderlessWindow.h"
#import "ESBundleAdditions.h"
#import "ESDateFormatterAdditions.h"
#import "ESDelayedTextField.h"
#import "ESFileWrapperExtension.h"
#import "ESFloater.h"
#import "ESImageAdditions.h"
#import "ESImageViewWithImagePicker.h"
#import "ESOutlineViewAdditions.h"
#import "ESQuicklyResizingPanel.h"
#import "ESSystemNetworkDefaults.h"
#import "ESTextViewWithPlaceholder.h"
#import "ESURLAdditions.h"
#import "IconFamily.h"
#import "JVFontPreviewField.h"
#import "MVMenuButton.h"
#import "NDRunLoopMessenger.h"
#import "NEHMutableStringAdditions.h"
#import "NSString+CarbonFSSpecCreation.h"
#import "QTSoundFilePlayer.h"
#import "SUSpeaker.h"

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
#define AILocalizedString(key, comment) NSLocalizedStringFromTableInBundle(key,nil,[NSBundle bundleForClass: [self class]],comment)
#define AILocalizedStringFromTable(key, table, comment) NSLocalizedStringFromTableInBundle(key,table,[NSBundle bundleForClass: [self class]],comment)
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

#import <AIUtilities/AIAlternatingRowOutlineView.h>
#import <AIUtilities/AIAlternatingRowTableView.h>
#import <AIUtilities/AIAnimatedFloater.h>
#import <AIUtilities/AIAnimatedView.h>
#import <AIUtilities/AIAppleScriptAdditions.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIAutoScrollView.h>
#import <AIUtilities/AIBezierPathAdditions.h>
#import <AIUtilities/AIColorAdditions.h>
#import <AIUtilities/AIColorSelectionPopUpButton.h>
#import <AIUtilities/AIColoredBoxView.h>
#import <AIUtilities/AICompletingTextField.h>
#import <AIUtilities/AICursorAdditions.h>
#import <AIUtilities/AICustomTabCell.h>
#import <AIUtilities/AICustomTabDragging.h>
#import <AIUtilities/AICustomTabsView.h>
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AIDockingWindow.h>
#import <AIUtilities/AIEventAdditions.h>
#import <AIUtilities/AIFileManagerAdditions.h>
#import <AIUtilities/AIFlexibleTableView.h>
#import <AIUtilities/AIFontAdditions.h>
#import <AIUtilities/AIGradient.h>
#import <AIUtilities/AIGradientCell.h>
#import <AIUtilities/AIHTMLDecoder.h>
#import <AIUtilities/AIImageTextCell.h>
#import <AIUtilities/AIKeychain.h>
#import <AIUtilities/AILinkTextView.h>
#import <AIUtilities/AILinkTrackingController.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIMultiCellOutlineView.h>
#import <AIUtilities/AIMutableOwnerArray.h>
#import <AIUtilities/AINetworkConnectivity.h>
#import <AIUtilities/AIOutlineView.h>
#import <AIUtilities/AIParagraphStyleAdditions.h>
#import <AIUtilities/AIPlasticButton.h>
#import <AIUtilities/AIPlasticMinusButton.h>
#import <AIUtilities/AIPlasticPlusButton.h>
#import <AIUtilities/AIPopUpButtonAdditions.h>
#import <AIUtilities/AIScaledImageCell.h>
#import <AIUtilities/AIScrollViewAdditions.h>
#import <AIUtilities/AISendingTextView.h>
#import <AIUtilities/AISleepNotification.h>
#import <AIUtilities/AISmartStepper.h>
#import <AIUtilities/AISmoothTooltipTracker.h>
#import <AIUtilities/AISocket.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AIStringFormatter.h>
#import <AIUtilities/AITabViewAdditions.h>
#import <AIUtilities/AITableViewAdditions.h>
#import <AIUtilities/AITableViewPopUpButtonCell.h>
#import <AIUtilities/AITextAttachmentExtension.h>
#import <AIUtilities/AITextAttributes.h>
#import <AIUtilities/AITextFieldAdditions.h>
#import <AIUtilities/AIToolbarUtilities.h>
#import <AIUtilities/AITooltipUtilities.h>
#import <AIUtilities/AIVerticallyCenteredTextCell.h>
#import <AIUtilities/AIViewAdditions.h>
#import <AIUtilities/AIWindowAdditions.h>
#import <AIUtilities/BZArrayAdditions.h>
#import <AIUtilities/BZContextImageBridge.h>
#import <AIUtilities/BZFontManagerAdditions.h>
#import <AIUtilities/BZGenericViewCell.h>
#import <AIUtilities/CBApplicationAdditions.h>
#import <AIUtilities/CBObjectAdditions.h>
#import <AIUtilities/ESArrayAdditions.h>
#import <AIUtilities/ESBorderlessWindow.h>
#import <AIUtilities/ESBundleAdditions.h>
#import <AIUtilities/ESDateFormatterAdditions.h>
#import <AIUtilities/ESDelayedTextField.h>
#import <AIUtilities/ESExpandedRecursiveLock.h>
#import <AIUtilities/ESFileWrapperExtension.h>
#import <AIUtilities/ESFlexibleToolbarItem.h>
#import <AIUtilities/ESFloater.h>
#import <AIUtilities/ESImageAdditions.h>
#import <AIUtilities/ESImageViewWithImagePicker.h>
#import <AIUtilities/ESOutlineViewAdditions.h>
#import <AIUtilities/ESQuicklyResizingPanel.h>
#import <AIUtilities/ESSystemNetworkDefaults.h>
#import <AIUtilities/ESTextViewWithPlaceholder.h>
#import <AIUtilities/ESURLAdditions.h>
#import <AIUtilities/IconFamily.h>
#import <AIUtilities/JVFontPreviewField.h>
#import <AIUtilities/MVMenuButton.h>
#import <AIUtilities/ESImageButton.h>
#import <AIUtilities/NDRunLoopMessenger.h>
#import <AIUtilities/NEHMutableStringAdditions.h>
#import <AIUtilities/NSString+CarbonFSSpecCreation.h>
#import <AIUtilities/QTSoundFilePlayer.h>
#import <AIUtilities/SUSpeaker.h>

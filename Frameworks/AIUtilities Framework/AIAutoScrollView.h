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

/*!
	@class AIAutoScrollView
	@abstract <tt>NSScrollView</tt> subclass which adds automatic scrolling, scroll bar hiding, and other features.
	@discussion This <tt>NSScrollView</tt> subclass adds:<br>
	 - Automatic scrolling as text is added and automatic hiding of the scroll bar, even on 10.2 (these features were added in 10.3)<br>
	 - Methods to scroll to the top and bottom of the view<br>
	 - Key press forwarding to the document view<br>
	 - Focus ring drawing for views such as NSTextView which do not normally draw a focus ring<br>
*/
@interface AIAutoScrollView : NSScrollView {
    NSRect			oldDocumentFrame;

    BOOL			autoScrollToBottom;
	BOOL			inAutoScrollToBottom;

    BOOL			autoHideScrollBar;

	BOOL			passKeysToDocumentView;

	BOOL			alwaysDrawFocusRingIfFocused;
	BOOL			shouldDrawFocusRing;
	NSResponder		*lastResp;
}

/*!
	@method setAutoHideScrollBar:
	@abstract Set if the scroll bar should be automatically hidden and shown as necessary
	@discussion If YES, the scroll bar will be hidden when it is not needed and automatically shown when the document view exceeds the frame available for its display. The default value is NO.
	@param inValue YES if the scroll bar should be automatically hidden; NO if not.
*/
- (void)setAutoHideScrollBar:(BOOL)inValue;

/*!
	@method setAutoScrollToBottom:
	@abstract Set if the scrollView should scroll to the bottom when new content is added
	@discussion If YES, the scrollView will scroll to the bottom when new content is added (i.e. when the frame of the document view increases), bringing the new data into visibility. Automatic scrolling will only occur if the view was scrolled to the bottom previously; it will not force a scroll to the bottom if the user has scrolled up in the scrollView. The default value is NO.
	@param inValue YES if the scrollView should automatically scroll as described above.
*/
- (void)setAutoScrollToBottom:(BOOL)inValue;

/*!
	@method scrollToTop
	@abstract Scroll to the top of the documentView.
	@discussion Scroll to the top of the documentView.
*/
- (void)scrollToTop;

/*!
	@method scrollToBottom
	@abstract Scroll to the bottom of the documentView.
	@discussion Scroll to the bottom of the documentView.
*/
- (void)scrollToBottom;

/*!
	@method setPassKeysToDocumentView:
	@abstract Set if keys unrelated to scrolling should be passed to the scrollView's documentView
	@discussion If YES, keyDown: events which the scrollView receives and which do not cause it to scroll will be passed to the documentView for handling. Defualts to NO.
	@param inValue YES if keys should be passed to the document view.
*/
- (void)setPassKeysToDocumentView:(BOOL)inValue;

/*!
	@method setAlwaysDrawFocusRingIfFocused:
	@abstract Set if a focus ring should be drawn in all cases when the view has focus.
	@discussion Some contained views, such as NSTextFields, do not draw focus rings.  This is generally correct, but it may be desirable to draw a focus ring around such views anyways.  If <b>inFlag</b> is YES, a focus ring will be drawn when the view has focus regardless of its type. The default value is NO.
	@param inFlag YES if the focus ring should always be drawn
*/
- (void)setAlwaysDrawFocusRingIfFocused:(BOOL)inFlag;

@end

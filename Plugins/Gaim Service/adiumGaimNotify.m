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

#import "ESGaimNotifyEmailController.h"
#import "adiumGaimNotify.h"
#import "SLGaimCocoaAdapter.h"
#import <AIUtilities/CBObjectAdditions.h>

static void *adiumGaimNotifyMessage(GaimNotifyMsgType type, const char *title, const char *primary, const char *secondary, GCallback cb,void *userData)
{
	GaimDebug (@"adiumGaimNotifyMessage: type: %i\n%s\n%s\n%s ",
			   type,
			   (title ? title : ""),
			   (primary ? primary : ""),
			   (secondary ? secondary : ""));

	return ([[SLGaimCocoaAdapter sharedInstance] handleNotifyMessageOfType:type
																 withTitle:title
																   primary:primary
																 secondary:secondary]);
}

static void *adiumGaimNotifyEmails(size_t count, gboolean detailed, const char **subjects, const char **froms, const char **tos, const char **urls, GCallback cb,void *userData)
{
    //Values passed can be null
    return([ESGaimNotifyEmailController handleNotifyEmails:count 
												  detailed:detailed
												  subjects:subjects
													 froms:froms
													   tos:tos
													  urls:urls]);
}

static void *adiumGaimNotifyEmail(const char *subject, const char *from, const char *to, const char *url, GCallback cb,void *userData)
{
	return(adiumGaimNotifyEmails(1,
								 TRUE,
								 (subject ? &subject : NULL),
								 (from ? &from : NULL),
								 (to ? &to : NULL),
								 (url ? &url : NULL),
								 cb, userData));
}

static void *adiumGaimNotifyFormatted(const char *title, const char *primary, const char *secondary, const char *text, GCallback cb,void *userData)
{
	GaimDebug (@"adiumGaimNotifyFormatted: %s\n%s\n%s\n%s ",
			   (title ? title : ""),
			   (primary ? primary : ""),
			   (secondary ? secondary : ""),
			   (text ? text : ""));

	return ([[SLGaimCocoaAdapter sharedInstance] handleNotifyFormattedWithTitle:title
																		primary:primary
																	  secondary:secondary
																		   text:text]);	
}

static void *adiumGaimNotifyUserinfo(GaimConnection *gc, const char *who, const char *title, const char *primary, const char *secondary, const char *text, GCallback cb,void *userData)
{
	NSString	*textString = [NSString stringWithUTF8String:text];
	
	if (GAIM_CONNECTION_IS_VALID(gc)){
		GaimAccount		*account = gc->account;
		GaimBuddy		*buddy = gaim_find_buddy(account,who);
		AIListContact   *theContact = contactLookupFromBuddy(buddy);
		
		
		[accountLookup(account) mainPerformSelector:@selector(updateUserInfo:withData:)
										 withObject:theContact
										 withObject:textString];
	}
	
    return(adium_gaim_get_handle());
}

static void *adiumGaimNotifyUri(const char *uri)
{
	if (uri){
		NSURL   *notifyURI = [NSURL URLWithString:[NSString stringWithUTF8String:uri]];
		[[NSWorkspace sharedWorkspace] openURL:notifyURI];
	}
	
	return(adium_gaim_get_handle());
}

static void adiumGaimNotifyClose(GaimNotifyType type,void *uiHandle)
{
	GaimDebug (@"adiumGaimNotifyClose");
}

static GaimNotifyUiOps adiumGaimNotifyOps = {
    adiumGaimNotifyMessage,
    adiumGaimNotifyEmail,
    adiumGaimNotifyEmails,
    adiumGaimNotifyFormatted,
	adiumGaimNotifyUserinfo,
    adiumGaimNotifyUri,
    adiumGaimNotifyClose
};

GaimNotifyUiOps *adium_gaim_notify_get_ui_ops(void)
{
	return &adiumGaimNotifyOps;
}

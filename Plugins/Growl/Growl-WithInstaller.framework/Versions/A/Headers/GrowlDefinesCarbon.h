//
// GrowlDefinesCarbon.h
//
// Automatically generated from GrowlDefines.h on Wed 2005-02-09 by GenCarbonHeader.pl
//

#ifndef _GROWLDEFINES_H
#define _GROWLDEFINES_H

/*!	@header GrowlDefines.h
 *	@abstract   Defines all the notification keys.
 *	@discussion Defines all the keys used for registration with Growl and for
 *	 Growl notifications.
 *	 
 *	 Most applications should use the functions or methods of Growl.framework
 *	 instead of posting notifications such as those described here.
 *	@updated 2004-01-25
 */

// UserInfo Keys for Registration
#pragma mark UserInfo Keys for Registration

/*!	@group Registration userInfo keys
 *	@abstract	Keys for the userInfo dictionary of a GROWL_APP_REGISTRATION distributed notification.
 *	@discussion The values of these keys describe the application and the
 *	 notifications it may post.
 *
 *	 Your application must register with Growl before it can post Growl
 *	 notifications (and have them not be ignored). However, as of Growl 0.6,
 *	 posting GROWL_APP_REGISTRATION notifications directly is no longer the
 *	 preferred way to register your application. Your application should instead
 *	 use Growl.framework's delegate system.
 *	 See +[GrowlApplicationBridge setGrowlDelegate:] or Growl_SetDelegate for
 *	 more information.
 */

/*!	@defined GROWL_APP_NAME
 *	@abstract The name of your application.
 *	@discussion The name of your application. This should remain stable between
 *	 different versions and incarnations of your application.
 *	 For example, "SurfWriter" is a good app name, whereas "SurfWriter 2.0" and
 *	 "SurfWriter Lite" are not.
 */
#define GROWL_APP_NAME					CFSTR("ApplicationName")
/*!	@defined GROWL_APP_ICON
 *	@abstract The image data for your application's icon.
 *	@discussion Image data representing your application's icon. This may be
 *	 superimposed on a notification icon as a badge, used as the notification
 *	 icon when a notification-specific icon is not supplied, or ignored
 *	 altogether, depending on the display. Must be in a format supported by
 *	 NSImage, such as TIFF, PNG, GIF, JPEG, BMP, PICT, or PDF.
 *
 *	 Optional. Not supported by all display plugins.
 */
#define GROWL_APP_ICON					CFSTR("ApplicationIcon")
/*!	@defined GROWL_NOTIFICATIONS_DEFAULT
 *	@abstract The array of notifications to turn on by default.
 *	@discussion These are the names of the notifications that should be enabled
 *	 by default when your application registers for the first time. If your
 *	 application reregisters, Growl will look here for any new notification
 *	 names found in GROWL_NOTIFICATIONS_ALL, but ignore any others.
 */
#define GROWL_NOTIFICATIONS_DEFAULT		CFSTR("DefaultNotifications")
/*!	@defined GROWL_NOTIFICATIONS_ALL
 *	@abstract The array of all notifications your application can send.
 *	@discussion These are the names of all of the notifications that your
 *	 application may post. See GROWL_NOTIFICATION_NAME for a discussion of good
 *	 notification names.
 */
#define GROWL_NOTIFICATIONS_ALL			CFSTR("AllNotifications")
/*!	@defined GROWL_NOTIFICATIONS_USER_SET
 *	@abstract The array of notifications the user has turned on.
 *	@discussion This array contains the names of all the notifications the user
 *	 has enabled. Your application should not interact with this key.
 */
#define GROWL_NOTIFICATIONS_USER_SET	CFSTR("AllowedUserNotifications")

// UserInfo Keys for Notifications
#pragma mark UserInfo Keys for Notifications

/*!	@group Notification userInfo keys
 *	@abstract	Keys for the userInfo dictionary of a GROWL_NOTIFICATION distributed notification.
 *	@discussion The values of these keys describe the content of a Growl
 *	 notification.
 *
 *	 Not all of these keys are supported by all displays. Only the name, title,
 *	 and description of a notification are universal. Most of the built-in
 *	 displays do support all of these keys, and most other visual displays
 *	 probably will also. But, as of 0.6, the Log, MailMe, and Speech displays
 *	 support only textual data.
 */

/*!	@defined GROWL_NOTIFICATION_NAME
 *	@abstract The name of the notification.
 *	@discussion The name of the notification. This should be human-readable, as
 *	 it's shown in the prefpane, in the list of notifications your application
 *	 supports. */
#define GROWL_NOTIFICATION_NAME			CFSTR("NotificationName")
/*!	@defined GROWL_NOTIFICATION_TITLE
 *	@abstract The title to display in the notification.
 *	@discussion The title of the notification. Should be very brief.
 *	 The title usually says what happened, e.g. "Download complete".
 */
#define GROWL_NOTIFICATION_TITLE		CFSTR("NotificationTitle")
/*!	@defined GROWL_NOTIFICATION_DESCRIPTION
 *	@abstract The description to display in the notification.
 *	@discussion The description should be longer and more verbose than the title.
 *	 The description usually tells the subject of the action,
 *	 e.g. "Growl-0.6.dmg downloaded in 5.02 minutes".
 */
#define GROWL_NOTIFICATION_DESCRIPTION  	CFSTR("NotificationDescription")
/*!	@defined GROWL_NOTIFICATION_ICON
 *	@discussion Image data for the notification icon. Must be in a format
 *	 supported by NSImage, such as TIFF, PNG, GIF, JPEG, BMP, PICT, or PDF.
 *
 *	 Optional. Not supported by all display plugins.
 */
#define GROWL_NOTIFICATION_ICON			CFSTR("NotificationIcon")
/*!	@defined GROWL_NOTIFICATION_APP_ICON
 *	@discussion Image data for the application icon, in case GROWL_APP_ICON does
 *	 not apply for some reason. Must be in a format supported by NSImage, such
 *	 as TIFF, PNG, GIF, JPEG, BMP, PICT, or PDF.
 *
 *	 Optional. Not supported by all display plugins.
 */
#define GROWL_NOTIFICATION_APP_ICON		CFSTR("NotificationAppIcon")
/*!	@defined GROWL_NOTIFICATION_PRIORITY
 *	@discussion The priority of the notification as an integer number from
 *	 -2 to +2 (+2 being highest).
 *
 *	 Optional. Not supported by all display plugins.
 */
#define GROWL_NOTIFICATION_PRIORITY		CFSTR("NotificationPriority")
/*!	@defined GROWL_NOTIFICATION_STICKY
 *	@discussion A Boolean number controlling whether the notification is sticky.
 *
 *	 Optional. Not supported by all display plugins.
 */
#define GROWL_NOTIFICATION_STICKY		CFSTR("NotificationSticky")
/*!	@defined GROWL_NOTIFICATION_CLICK_CONTEXT
 *	@abstract Identifies which notification was clicked.
 *	@discussion An identifier for the notification for clicking purposes.
 *
 *	 This will be passed back to the application when the notification is
 *	 clicked. It must be plist-encodable (a data, dictionary, array, number, or
 *	 string object), and it should be unique for each notification you post.
 *	 A good click context would be a UUID string returned by NSProcessInfo or
 *	 CFUUID.
 *
 *	 Optional. Not supported by all display plugins.
 */
#define GROWL_NOTIFICATION_CLICK_CONTEXT			CFSTR("NotificationClickContext")

//add documentation comments
#define GROWL_NOTIFICATION_FORCE_APP_LINK	CFSTR("NotificationForceAppLink")
#define GROWL_NOTIFICATION_LINKS		CFSTR("NotificationLinks")

// Notifications
#pragma mark Notifications

/*!	@group Notification names
 *	@abstract	Names of distributed notifications used by Growl.
 *	@discussion	These are notifications used by applications (directly or
 *	 indirectly) to interact with Growl, and by Growl for interaction between
 *	 its components.
 *
 *	 Most of these should no longer be used in Growl 0.6 and later, in favor of
 *	 Growl.framework's GrowlApplicationBridge APIs.
 */

/*!	@defined GROWL_APP_REGISTRATION
 *	@abstract The distributed notification for registering your application.
 *	@discussion This is the name of the distributed notification that can be
 *	 used to register applications with Growl.
 *
 *	 The userInfo dictionary for this notification can contain these keys:
 *	 <ul>
 *	 	<li>GROWL_APP_NAME</li>
 *	 	<li>GROWL_APP_ICON</li>
 *	 	<li>GROWL_NOTIFICATIONS_ALL</li>
 *	 	<li>GROWL_NOTIFICATIONS_DEFAULT</li>
 *	 </ul>
 *
 *	 No longer recommended as of Growl 0.6. An alternate method of registering
 *	 is to use Growl.framework's delegate system.
 *	 See +[GrowlApplicationBridge setGrowlDelegate:] or Growl_SetDelegate for
 *	 more information.
 */
#define GROWL_APP_REGISTRATION			CFSTR("GrowlApplicationRegistrationNotification")
/*!	@defined GROWL_APP_REGISTRATION_CONF
 *	@abstract The distributed notification for confirming registration.
 *	@discussion The name of the distributed notification sent to confirm the
 *	 registration. Used by the Growl preference pane. Your application probably
 *	 does not need to use this notification.
 */
#define GROWL_APP_REGISTRATION_CONF		CFSTR("GrowlApplicationRegistrationConfirmationNotification")
/*!	@defined GROWL_NOTIFICATION
 *	@abstract The distributed notification for Growl notifications.
 *	@discussion This is what it all comes down to. This is the name of the
 *	 distributed notification that your application posts to actually send a
 *	 Growl notification.
 *
 *	 The userInfo dictionary for this notification can contain these keys:
 *	 <ul>
 *	 	<li>GROWL_NOTIFICATION_NAME (required)</li>
 *	 	<li>GROWL_NOTIFICATION_TITLE (required)</li>
 *	 	<li>GROWL_NOTIFICATION_DESCRIPTION (required)</li>
 *	 	<li>GROWL_NOTIFICATION_ICON</li>
 *	 	<li>GROWL_NOTIFICATION_APP_ICON</li>
 *	 	<li>GROWL_NOTIFICATION_PRIORITY</li>
 *	 	<li>GROWL_NOTIFICATION_STICKY</li>
 *	 	<li>GROWL_NOTIFICATION_CLICK_CONTEXT</li>
 *	 	<li>GROWL_APP_NAME (required)</li>
 *	 </ul>
 *
 *	 No longer recommended as of Growl 0.6. Three alternate methods of posting
 *	 notifications are +[GrowlApplicationBridge notifyWithTitle:description:notificationName:iconData:priority:isSticky:clickContext:],
 *	 Growl_NotifyWithTitleDescriptionNameIconPriorityStickyClickContext, and
 *	 Growl_PostNotification.
 */
#define GROWL_NOTIFICATION				CFSTR("GrowlNotification")
/*!	@defined GROWL_SHUTDOWN
 *	@abstract The distributed notification name that tells Growl to shutdown.
 *	@discussion The Growl preference pane posts this notification when the
 *	 "Stop Growl" button is clicked.
 */
#define GROWL_SHUTDOWN					CFSTR("GrowlShutdown")
/*!	@defined GROWL_PING
 *	@abstract A distributed notification to check whether Growl is running.
 *	@discussion This is used by the Growl preference pane. If it receives a
 *	 GROWL_PONG, the preference pane takes this to mean that Growl is running.
 */
#define GROWL_PING						CFSTR("Honey, Mind Taking Out The Trash")
/*!	@defined GROWL_PONG
 *	@abstract The distributed notification sent in reply to GROWL_PING.
 *	@discussion GrowlHelperApp posts this in reply to GROWL_PING.
 */
#define GROWL_PONG						CFSTR("What Do You Want From Me, Woman")
/*!	@defined GROWL_IS_READY
 *	@abstract The distributed notification sent when Growl starts up.
 *	@discussion GrowlHelperApp posts this when it has begin listening on all of
 *	 its sources for new notifications. GrowlApplicationBridge (in
 *	 Growl.framework), upon receiving this notification, reregisters using the
 *	 registration dictionary supplied by its delegate.
 */
#define GROWL_IS_READY					CFSTR("Lend Me Some Sugar; I Am Your Neighbor!")
/*!	@defined GROWL_NOTIFICATION_CLICKED
 *	@abstract The distributed notification sent when a supported notification is clicked.
 *	@discussion When a Growl notification with a click context is clicked on by
 *	 the user, Growl posts this distributed notification.
 *	 The GrowlApplicationBridge responds to this notification by calling a
 *	 callback in its delegate.
 */
#define GROWL_NOTIFICATION_CLICKED             CFSTR("GrowlClicked!")

/*!	@group Other symbols
 *	@abstract Symbols which don't fit into any of the other categories.
 */

/*!	@defined GROWL_KEY_CLICKED_CONTEXT
 *	@abstract Used internally as the key for the clickedContext passed over DNC.
 *	@discussion This key is used in GROWL_NOTIFICATION_CLICKED, and contains the
 *	 click context that was supplied in the original notification.
 */
#define GROWL_KEY_CLICKED_CONTEXT              CFSTR("ClickedContext")
/*!	@defined GROWL_REG_DICT_EXTENSION
 *	@abstract The filename extension for registration dictionaries.
 *	@discussion The GrowlApplicationBridge in Growl.framework registers with
 *	 Growl by creating a file with the extension of .(GROWL_REG_DICT_EXTENSION)
 *	 and opening it in the GrowlHelperApp. This happens whether or not Growl is
 *	 running; if it was stopped, it quits immediately without listening for
 *	 notifications.
 */
#define GROWL_REG_DICT_EXTENSION		CFSTR("growlRegDict")

#endif //ndef _GROWLDEFINES_H

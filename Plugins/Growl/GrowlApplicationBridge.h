//
//  GrowlApplicationBridge.h
//  Growl
//
//  Created by Evan Schoenberg on Wed Jun 16 2004.
//

/*!
@header
 @abstract   Defines the GrowlApplicationBridge class
 @discussion This header defines the GrowlApplicationBridge class as well as
	the GROWL_PREFPANE_BUNDLE_IDENTIFIER constant.
 */

#import <Foundation/Foundation.h>

/*!
@defined    GROWL_PREFPANE_BUNDLE_IDENTIFIER
 @discussion The bundle identifier for the Growl prefpane
 */
#define GROWL_PREFPANE_BUNDLE_IDENTIFIER	@"com.growl.prefpanel"
#define GROWL_PREFPANE_NAME					@"Growl.prefPane"

/*!
@class      GrowlAppBridge
@abstract   A class used to interface with Growl
@discussion This class provides a means to interface with Growl.

Currently it provides a way to detect if Growl is installed and launch the GrowlHelperApp
if it's not already running.
*/
@interface GrowlAppBridge : NSObject {
	
}

/*!
@method launchGrowlIfInstalledNotifyingTarget:selector:context:
	@abstract Launches GrowlHelperApp and notifies when Growl is ready
	@discussion Launches the GrowlHelperApp if it's not already running and notifies the target when 
	Growl is ready to receive notifications.
	@param target The target to notify
	@param selector The selector to call on target (this should take a single argument)
	@param context A context object to pass through to the selector
	@result Returns YES if GrowlHelperApp began launching, NO if Growl isn't installed
 */
+ (BOOL)launchGrowlIfInstalledNotifyingTarget:(id)target selector:(SEL)selector context:(void *)context registrationDict:(NSDictionary *)regDict;

	/*!
	@method isGrowlRunning
	 @abstract Detects whether GrowlHelperApp is currently running
	 @discussion Cycles through the process list to find if GrowlHelperApp is running and returns the
	 status
	 @result Returns YES if GrowlHelperApp is running, NO otherwise
	 */
+ (BOOL)isGrowlRunning;
@end

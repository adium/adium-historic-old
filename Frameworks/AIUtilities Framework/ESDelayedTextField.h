//
//  ESDelayedTextField.h
//  Adium
//
//  Created by Evan Schoenberg on Wed Mar 10 2004.

/*!
	@class ESDelayedTextField
	@abstract Text field which groups changes, triggering its action after a period without changes
	@discussion An <tt>ESDelayedTextField</tt> is identical to an NSTextField except, instead of sending its target an action only when enter is pressed or the field loses focus, it sends the action after a specified delay without changes.  This allows an intermediate behavior between changing every time the text chagnes (via the textDidChange: notification) and changing only when editing is complete.
*/
@interface ESDelayedTextField : NSTextField {
	NSTimer *delayedChangesTimer;
	float   delayInterval;
}

/*!
	@method fireImmediately
	@abstract Immediately send the action to the target.
	@discussion Immediately send the action to the target. If the field had changed but has not yet sent its action (because the delay interval has not been reached), it immediately sends the action and cancels the delayed send.  This should be sent before programatically changing the text (if the view is configuring for some new display but the changes the user made previously should saved). It should also be called before its containing view is closed so changes may be immediately applied..
*/ 
- (void)fireImmediately;

/*!
	@method setDelayInterval:
	@abstract Set the interval which must pass without changes before the action is triggered.
	@discussion Set the interval which must pass without changes before the action is triggered.  If changes are made within this interval, the timer is reset and inInterval must then pass from the time of the new edit.
	@param inInterval The new interval (in seconds). The default value is 0.5 seconds.
*/
- (void)setDelayInterval:(float)inInterval;

/*!
	@method delayInterval:
	@abstract The current triggering delay interval
	@discussion The current triggering delay interval
	@return inInterval The delay interval (in seconds).
*/
- (float)delayInterval;

@end

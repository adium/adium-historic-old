/*!
	@header NDScriptData.h
	@abstract Header file from the project NDScriptDataProjectAlpha
	@discussion Defines the Classes <tt>NDScriptData</tt>, <tt>NDScriptHandler</tt> and <tt>NDScriptContext</tt>
 
	Created by Nathan Day on Tue Apr 27 2004.
	Copyright &#169; 2003 Nathan Day. All rights reserved.
*/
#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>

@class	NDComponentInstance;

extern const short		kScriptResourceID;

/*!
	@class NDScriptData
	@abstract Class for representing script data <tt>OSAID</tt>
	@discussion <tt>NDScriptData</tt> is the base class for <tt>NDScriptHandler</tt> and <tt>NDSccriptContext</tt>. Instances of <tt>NDScriptData</tt> can represent script data.
*/
@interface NDScriptData : NSObject <NSCopying, NSCoding>
{
@protected
	OSAID							scriptID;
	NDComponentInstance		* componentInstance;
}

/*!
	@method scriptDataWithAppleEventDescriptor:componentInstance:
	@abstract Create a new script data object.
	@discussion Returns a new <tt>NDScriptData</tt> or a subclass from the contents of the <tt>NSAppleEventDescriptor</tt> <tt><i>descriptor</i></tt>
	@param descriptor The AppleEvent descriptor ot be converted to script data.
	@param componentInstance The component instance to use, a value of <tt>nil</tt> to use the default AppleScript context.
	@result A new <tt>NDScriptData</tt> or <tt>nil</tt> if unsuccessful.
 */
+ (id)scriptDataWithAppleEventDescriptor:(NSAppleEventDescriptor *)descriptor componentInstance:(NDComponentInstance *)componentInstance;

/*!
	@method initWithAppleEventDescriptor:componentInstance:
	@abstract Initialize a <tt>NDSciptData</tt>
	@discussion Initializes the reviever by coercing the <tt>NSAppleEventDescriptor</tt> <tt><i>descriptor</i></tt>, if you dont known what the best <tt>NDScriptData</tt> subclass is for the <tt>NSAppleEventDescriptor</tt>  then use the method <tt>+scriptDataWithAppleEventDescriptor:componentInstance:</tt> instead.
	@param descriptor The AppleEvent descriptor ot be converted to script data.
	@param componentInstance The component instance to use, a value of <tt>nil</tt> to use the default AppleScript context.
	@result A initialized <tt>NDScriptData</tt>. 
*/
- (id)initWithAppleEventDescriptor:(NSAppleEventDescriptor *)descriptor componentInstance:(NDComponentInstance *)componentInstance;

/*!
	@method initWithData:componentInstance:
	@abstract Initialize a <tt>NDSciptData</tt>
	@discussion Intialises the reciever with the <tt>NSData</tt> <tt><i>data</i></tt>, this is the data returned from the method <tt>-data</tt>, it is also the data stored within script files, both data forks or resource forks.
	@param data The <tt>NSData</tt>  object.
	@param componentInstance The component instance to use, a value of <tt>nil</tt> to use the default AppleScript context.
	@result A initialized <tt>NDScriptData</tt>, or <tt>nil</tt> of initialization fails.
*/
- (id)initWithData:(NSData *)data componentInstance:(NDComponentInstance *)componentInstance;

/*!
	@method initWithContentsOfFile:componentInstance:
	@abstract Initialize a <tt>NDSciptData</tt>
	@discussion Intialises the reciever with the contents of the file at the path <tt><i>path</i></tt>, if script data can not be found within data fork the any script data within the resource fork.
	@param path The path of the script file.
	@param componentInstance The component instance to use, a value of <tt>nil</tt> to use the default AppleScript context.
	@result A initialized <tt>NDScriptData</tt>, or <tt>nil</tt> of initialization fails.
*/
- (id)initWithContentsOfFile:(NSString *)path componentInstance:(NDComponentInstance *)componentInstance;

/*!
	@method initWithContentsOfURL:componentInstance:
	@abstract Initialize a <tt>NDSciptData</tt>
	@discussion Intialises the reciever with the contents of the file at the file url <tt><i>URL</i></tt>, if script data can not be found within data fork the any script data within the resource fork.
	@param URL The file url of the script file.
	@param componentInstance The component instance to use, a value of <tt>nil</tt> to use the default AppleScript context.
	@result A initialized <tt>NDScriptData</tt>, or <tt>nil</tt> of initialization fails.
*/
- (id)initWithContentsOfURL:(NSURL *)URL componentInstance:(NDComponentInstance *)componentInstance;

/*!
	@method initWithComponentInstance:
	@abstract Initialize a <tt>NDSciptData</tt>
	@discussion <tt>initWithComponentInstance:</tt> initializes the reciever with a component instance, <tt>initWithComponentInstance:</tt> is the designated initializer for the class <tt>NDScriptData</tt>
	@param componentInstance <#disc#>
	@result <#result#>
 */
- (id)initWithComponentInstance:(NDComponentInstance *)componentInstance;
/*!
	@method data
	@abstract Return script data as <tt>NSData</tt>.
	@discussion Returns an <tt>NSData</tt> object of the script data, this data is the same as store within compiled script files.
	@result A <tt>NSData</tt> instance, or <tt>nil</tt> if the data could not be returned.
*/
- (NSData *)data;

/*!
	@method appleEventDescriptorValue
	@abstract Returns script data as NSAppleEventDescriptor.
	@discussion Returns a NSAppleEventDescriptor object that can be used to pass script data into AppleEvents or passing script data between different NDComponentInsances. 
	@result A <tt>NSAppleEventDescriptor</tt> instance, or <tt>nil</tt> if the data could not be returned.
*/
- (NSAppleEventDescriptor *)appleEventDescriptorValue;

/*!
	@method bestAppleEventDescriptorType
	@abstract Determine the best <tt>NSAppleEventDescriptor</tt> type to represent script data.
	@discussion <tt>bestAppleEventDescriptorType</tt> determines the best <tt>NSAppleEventDescriptor</tt> type  to represent the reciever, this is the type the object returned from <tt>-appleEventDescriptorValue</tt> will be.
	@result A <tt>DescType</tt> value.
*/
- (DescType)bestAppleEventDescriptorType;

/*!
	@method stringValue
	@abstract Get a string representation.
	@discussion Coerces the reciever into a <tt>NSString</tt>, if you are after the source code from a compiled script, then you are better of using the method <tt>--[NDScriptHandler source]</tt>.
	@result A <tt>NSString</tt> or <tt>nil</tt> if coercion failed.
*/
- (NSString *)stringValue;

/*!
	@method componentInstance
	@abstract Get the scripting component instance
	@discussion Returns the scripting component for the reciever.
	@result The <tt>NDComponentInstance</tt> for the reciever.
*/
- (NDComponentInstance *)componentInstance;

/*!
	@method isValue
	@abstract Test script data for a value.
	@discussion <tt>isValue</tt> is used to determine whether or not the script data is a script value.
	@result Returns <tt>YES</tt> if the reciever is a value; otherwise, it returns <tt>NO</tt>.
*/
- (BOOL)isValue;

/*!
	@method isCompiledScript
	@abstract Test script data for a complied script.
	@discussion <tt>isCompiledScript</tt> is used to determine whether or not the reciever is a compiled script.
	@result Returns <tt>YES</tt> if the reciever is a compilied script; otherwise, it returns <tt>NO</tt>.
*/
- (BOOL)isCompiledScript;

/*!
	@method hasScriptContext
	@abstract <#Abstract#>
	@discussion <#Discussion#>
	@result <#result#>
 */
- (BOOL)hasScriptContext;

/*!
	@method hasOpenHandler
	@abstract Test script data for a open handler.
	@discussion <tt>hasOpenHandler</tt> is used to query the reciever as to whether it contains a handler for the <tt>kAEOpenDocuments</tt> event.
	@result Returns <tt>YES</tt> if the reciever is a compilied script with an open handler; otherwise, it returns <tt>NO</tt>.
 */
- (BOOL)hasOpenHandler;
/*!
	@method writeToFile:atomically:
	@abstract Write script data to a file.
	@discussion Writes the script data in the receiver to the file specified by <tt><i>path</i></tt>. If <tt><i>atomically</i></tt> is <tt>YES</tt>, the script data is written to a backup file, and then, assuming no errors occur, the backup file is renamed to the specified filename. Otherwise, the script data is written directly to the specified file.
	@param path The file path.
	@param atomically Write to a backup file first.
	@result This method returns <tt>YES</tt> if the operation succeeds; otherwise, it returns <tt>NO</tt>.
*/
- (BOOL)writeToFile:(NSString *)path atomically:(BOOL)atomically;

/*!
	@method writeToURL:atomically:
	@abstract Write script data to a file.
	@discussion Writes the script data in the receiver to the location specified by <tt>URL</tt>. If <tt>atomically</tt> is <tt>YES</tt>, the script data is written to a backup location, and then, assuming no errors occur, the backup location is renamed to the specified name. Otherwise, the script data is written directly to the specified location. <tt>atomically</tt> is ignored if <tt>URL</tt> is not of a type the supports atomic writes.
	@param URL The file URL.
	@param atomically Write to a backup file first.
	@result This method returns <tt>YES</tt> if the operation succeeds; otherwise, it returns <tt>NO</tt>.
*/
- (BOOL)writeToURL:(NSURL *)URL atomically:(BOOL)atomically;

/*!
	@method copyWithComponentInstance:
	@abstract Copy a script data.
	@discussion Returns a new <tt>NDScriptData</tt> instance which uses the component instance <tt>componentInstance</tt> different script data instances can only be used together if they share the same component instance.
	@param componentInstance The component instance to use, a value of <tt>nil</tt> to use the default AppleScript context.
	@result A new <tt>NDScriptData</tt> instance.
 */
- (id)copyWithComponentInstance:(NDComponentInstance *)componentInstance;

/*!
	@method isEqualToScriptData:
	@abstract Test if two script datas are equal.
	@discussion Compares the receiving script data object to <tt>scriptData</tt>. If the contents of <tt>scriptData</tt> is equal to the contents of the receiver, this method returns <tt>YES</tt>. If not, it returns <tt>NO</tt>. Two data objects are equal if they both have the same component instance and there script ids (OSAID) are equal.
	@param scriptData The script data to compere the reciever with.
	@result This method returns <tt>YES</tt> if the reciever and <tt>scriptData</tt> are equal; otherwise, it returns <tt>NO</tt>.
 */
- (BOOL)isEqualToScriptData:(NDScriptData *)scriptData;

@end


/*!
    @class NDScriptHandler
    @abstract Class to represent script data with executable content.
    @discussion <tt>NDScriptHandler</tt> stores executable code that can be executed within a script context, <tt>NDScriptHandler</tt> can not be executed in there own write.
*/
@interface NDScriptHandler : NDScriptData
{
@protected
	OSAID					resultScriptID;
	NDScriptData		* resultScriptData;
}

/*!
	@method initWithSource:modeFlags:componentInstance:
	@abstract Initialize a <tt>NDSciptData</tt>
	@discussion Initializes the receiver with with compiled <tt><i>source</i></tt>, the <tt><i>modeFlags</i></tt> can be used to control ho the compilied script behaves when running and can be an or'ed combination of any of the following values;
	<blockquote>
		 <dl>
			 <dt><tt><em>kOSAModePreventGetSource</em></tt></dt>
			 <dd>This mode flag may be used to instruct the scripting component to not retain the "source" of an expression. This will cause the method <tt>source</tt> to return the <tt>nil</tt> if used. However, some scripting components may not retain the source anyway. This is mainly used when either space efficiency is desired, or a script is to be "locked" so that its implementation may not be viewed.</dd>
			<dt><tt><em>kOSAModeNeverInteract</em></tt></dt>
			 <dd>This mode flag indicates the script may interact with the user if necessary. Adds <tt>kAENeverInteract</tt> to the <tt>sendMode</tt> parameter of <tt>AESend</tt> for events sent when the script is executed. </dd>
			 <dt><tt><em>kOSAModeCanInteract</em></tt></dt>
			 <dd>This mode flag indicates the script may interact with the user. Adds <tt>kAECanInteract</tt> to the <tt>sendMode</tt> parameter of <tt>AESend</tt> for events sent when the script is executed.</dd>
			 <dt><tt><em>kOSAModeAlwaysInteract</em></tt></dt>
			 <dd>This mode flag indicates that the script may interact with the user. Adds <tt>kAEAlwaysInteract</tt> to the <tt>sendMode</tt> parameter of <tt>AESend</tt> for events sent when the script is executed. </dd>
			 <dt><tt><em>kOSAModeDontReconnect</em></tt></dt>
			 <dd>This mode flag indicates that the script may not reconnect if necessary. Adds <tt>kAEDontReconnect</tt> to the <tt>sendMode</tt> parameter of <tt>AESend</tt> for events sent when the script is executed.</dd>
			 <dt><tt><em>kOSAModeCantSwitchLayer</em></tt></dt>
			 <dd>This mode flag indicates whether <tt>AppleEvents</tt> should be sent with the <tt>kAECanSwitchLayer</tt> mode flag sent. This flag is exactly the opposite of the AppleEvent flag <tt>kAECanSwitchLayer</tt>. This is to provide a more convenient default, such as not supplying any mode (<tt>kOSANullMode</tt>) means to send events with <tt>kAECanSwitchLayer</tt>. Supplying the <tt>kOSAModeCantSwitchLayer</tt> mode flag will cause <tt>AESend</tt> to be called without <tt>kAECanSwitchLayer</tt>.</dd>
		 </dl>
	</blockquote>
	@param source A <tt>NSString</tt> to be compilied.
	@param modeFlags Or'ed combination of values to determine how the script behaves whiles running.
	@param componentInstance The component instance to use, a value of <tt>nil</tt> to use the default AppleScript context.
	@result A initialized <tt>NDScriptHandler</tt>, or <tt>nil</tt> of initialization fails.
*/
- (id)initWithSource:(NSString *)source modeFlags:(long)modeFlags componentInstance:(NDComponentInstance *)componentInstance;

/*!
	@method source
	@abstract Retrieve script source.
	@discussion <tt>source</tt> decompiles the reciever if available and returns it, if the source is not available then <tt>nil</tt> is return.
	@result Returns a <tt>NSString</tt> contain the source if available; otherwise <tt>nil</tt> is returned.
*/
- (NSString *)source;

/*!
	@method resultScriptData
	@abstract Get the execution result.
	@discussion Returns <tt>NDScriptData</tt> or a subclass for the result of the last execution of the reciever. If the result type is a script then <tt>resultScriptData</tt> returns a <tt>NDScriptContext</tt> instance, if the result is a script handler then <tt>resultScriptData</tt> returns a <tt>NDScriptHandler</tt> instance, for all other results types <tt>resultScriptData</tt> returns a <tt>NDSciptData</tt>.
	@result A <tt>NDScriptData</tt> representing the result.
 */
- (NDScriptData *)resultScriptData;

@end


/*!
	@class NDScriptContext
	@abstract Class to represent a script context, compiled AppleScript.
	@discussion NDScriptContext is what you normal think of when you think of an compilied AppleScript, a NDScriptContext can contain multiple script handlers and script properites.
*/
@interface NDScriptContext : NDScriptHandler
{
@protected
	NDScriptData		* parentScriptData;
	long int				executionModeFlags;
}

/*!
	@method compileExecuteSource:componentInstance:
	@abstract Compile and execute a string.
	@discussion A convience method for quickly executing a string, this method can be used when the string is to only be execute once.
	@param source A <tt>NSString</tt> to be compilied.
	@param componentInstance The component instance to use, a value of <tt>nil</tt> to use the default AppleScript context.
	@result A <tt>NDScriptData</tt> for the execution result.
 */
+ (NDScriptData *)compileExecuteSource:(NSString *)source componentInstance:(NDComponentInstance *)componentInstance;

/*!
	@method initWithData:parentScriptData:
	@abstract Initialize a <tt>NDSciptContext</tt>
	@discussion Initializes the reciever with the script data within the <tt>NSData</tt> <tt><i>data</i></tt>, setting <tt><i>parentData</i></tt> as the parent, if the script data with <tt><i>data</i></tt> is not a script context.
	@param data The <tt>NSData</tt>  object.
	@param parentData The scipt data to become the parent, usually a script context.
	@result A initialized <tt>NDScriptContext</tt>, or <tt>nil</tt> of initialization fails.
*/
- (id)initWithData:(NSData *)data parentScriptData:(NDScriptData *)parentData;

/*!
	@method initWithParentScriptData:name:
	@abstract Initialize a <tt>NDSciptContext</tt>
	@discussion Initializes the reciever with a parent script and a name.
	@param parentScriptData A script data to set as the parent script, usually a script context.
	@param name <#disc#>
	@result A initialized <tt>NDScriptContext</tt>, or <tt>nil</tt> of initialization fails.
*/
- (id)initWithParentScriptData:(NDScriptData *)parentScriptData name:(NSString *)name;

/*!
	@method initWithContentsOfFile:parentScriptData:
	@abstract Initialize a <tt>NDSciptContext</tt>
	@discussion <#Discussion#>
	@param path The path of the script file.
	@param parentData <#disc#>
	@result A initialized <tt>NDScriptContext</tt>, or <tt>nil</tt> of initialization fails.
*/
- (id)initWithContentsOfFile:(NSString *)path parentScriptData:(NDScriptData *)parentData;

/*!
	@method initWithContentsOfURL:parentScriptData:
	@abstract Initialize a <tt>NDSciptContext</tt>
	@discussion <#Discussion#>
	@param URL <#disc#>
	@param parentData <#disc#>
	@result A initialized <tt>NDScriptContext</tt>, or <tt>nil</tt> of initialization fails.
*/
- (id)initWithContentsOfURL:(NSURL *)URL parentScriptData:(NDScriptData *)parentData;

/*!
	@method augmentWithSource:
	@abstract Augment script context.
	@discussion <#Discussion#>
	@param source A <tt>NSString</tt> to be compilied.
	@result This method returns <tt>YES</tt> if the operation succeeds; otherwise, it returns <tt>NO</tt>.
*/
- (BOOL)augmentWithSource:(NSString *)source;

/*!
	@method parentScriptData
	@abstract Get a script objects parent.
	@discussion <#Discussion#>
	@result <#result#>
*/
- (NDScriptData *)parentScriptData;

/*!
	@method setParentScriptData:
	@abstract Set a script objects parent
	@discussion <#Discussion#>
	@param parentData <#disc#>
	@result This method returns <tt>YES</tt> if the operation succeeds; otherwise, it returns <tt>NO</tt>.
*/
- (BOOL)setParentScriptData:(NDScriptData *)parentData;

/*!
	@method name
	@abstract <#Abstract#>
	@discussion <#Discussion#>
	@result <#result#>
 */
- (NSString *)name;

/*!
	@method setName:
	@abstract <#Abstract#>
	@discussion <#Discussion#>
	@param name <#disc#>
	@result <#result#>
 */
- (void)setName:(NSString *)name;

/*!
	@method execute
	@abstract Execute a script context
	@discussion <#Discussion#>
	@result This method returns <tt>YES</tt> if the operation succeeds; otherwise, it returns <tt>NO</tt>.
*/
- (BOOL)execute;

/*!
	@method executeScriptHandler:
	@abstract Execute a script handler within a script context.
	@discussion <#Discussion#>
	@param scriptData <#disc#>
	@result This method returns <tt>YES</tt> if the operation succeeds; otherwise, it returns <tt>NO</tt>.
*/
- (BOOL)executeScriptHandler:(NDScriptHandler *)scriptHandler;

/*!
	@method executeEvent:
	@abstract Execute an AppleEvent.
	@discussion <#Discussion#>
	@param descriptor <#disc#>
	@result This method returns <tt>YES</tt> if the operation succeeds; otherwise, it returns <tt>NO</tt>.
*/
- (BOOL)executeEvent:(NSAppleEventDescriptor *)descriptor;

/*!
	@method executionModeFlags
	@abstract Get the execution mad flags.
	@discussion <#Discussion#>
	@result <#result#>
*/
- (long int)executionModeFlags;

/*!
	@method setExecutionModeFlags:mask:
	@abstract Set the execution mode flags.
	@discussion <#Discussion#>
	@param flags <#disc#>
	@param mask <#disc#>
	@result <#result#>
*/
- (void)setExecutionModeFlags:(long int)flags mask:(long int)mask;

/*!
	@method setExecutionModeFlags:
	@abstract <#Abstract#>
	@discussion <#Discussion#>
	@param flags <#disc#>
	@result <#result#>
*/
- (void)setExecutionModeFlags:(long int)flags;

/*!
	@method appleEventTarget
	@abstract <#Abstract#>
	@discussion <#Discussion#>
	@result <#result#>
*/
- (NSAppleEventDescriptor *)appleEventTarget;


/*!
	@method arrayOfEventIdentifier
	@abstract returns all event identifies the script respondes to.
	@discussion returns and <tt>NSArray</tt> of <tt>NSDictionary</tt>s with the keys "<tt>EventClass</tt>" and "<tt>EventID</tt> and <tt>NSString</tt>swith the name of any subroutines".
	@result  returns an <tt>NSArray</tt> of event identifier <tt>NSDictionary</tt>s.
*/
- (NSArray *)arrayOfEventIdentifier;
/*!
	@method arrayOfSubroutineNames
	@abstract <#Abstract#>
	@discussion <#Discussion#>
	@result <#result#>
*/
- (NSArray *)arrayOfSubroutineNames;

/*!
	@method respondsToEventClass:eventID:
	@abstract Tests whether the script responds to an AppleEvent.
	@discussion This method test whether the script responds to the passed event identifier.
	@param eventClass  the event class.
	@param eventID  the event identifier.
	@result  returns <tt>YES</tt> if the script reponds to the event identifier.
*/
- (BOOL)respondsToEventClass:(AEEventClass)eventClass eventID:(AEEventID)eventID;

/*!
	@method respondsToSubroutineNamed:
	@abstract Tests whether the script responds to a subroutine call.
	@discussion This method test whether the script inplements the subroutine <tt><i>name</i></tt>, subroutine names are case insensitive and so the string <tt><i>name</i></tt> is converted to lower case first.
	@param name The subroutine name.
	@result  returns <tt>YES</tt> if the script reponds to the subroutine call; otherwise <tt>NO</tt> is returned.
*/
- (BOOL)respondsToSubroutineNamed:(NSString *)name;

/*!
	@method scriptHandlerForSubroutineNamed:
	@abstract <#Abstract#>
	@discussion <#Discussion#>
	@param name The subroutine name.
	@result Returns a script handler.
*/
- (NDScriptHandler *)scriptHandlerForSubroutineNamed:(NSString *)name;

/*!
	@method scriptHandlerForEventClass:eventID:
	@abstract <#Abstract#>
	@discussion <#Discussion#>
	@param eventClass <#disc#>
	@param eventID <#disc#>
	@result Returns a script handler.
*/
- (NDScriptHandler *)scriptHandlerForEventClass:(AEEventClass)eventClass eventID:(AEEventID)eventID;

/*!
	@method setSubroutineNamed:toScriptHandler:
	@abstract Set the handler to subroutine.
	@discussion <#Discussion#>
	@param name The subroutine name.
	@param scriptHandler <#disc#>
	@result This method returns <tt>YES</tt> if the operation succeeds; otherwise, it returns <tt>NO</tt>.
*/
- (BOOL)setSubroutineNamed:(NSString *)name toScriptHandler:(NDScriptHandler *)scriptHandler;

/*!
	@method setEventClass:eventID:toScriptHandler:
	@abstract Set the handler to subroutine.
	@discussion <#Discussion#>
	@param eventClass <#disc#>
	@param eventID <#disc#>
	@param scriptHandler <#disc#>
	@result This method returns <tt>YES</tt> if the operation succeeds; otherwise, it returns <tt>NO</tt>.
*/
- (BOOL)setEventClass:(AEEventClass)eventClass eventID:(AEEventID)eventID toScriptHandler:(NDScriptHandler *)scriptHandler;

/*!
	@method addSubroutineNamed:scriptHandler:
	@abstract <#Abstract#>
	@discussion <#Discussion#>
	@param name The subroutine name.
	@param scriptHandler <#disc#>
	@result This method returns <tt>YES</tt> if the operation succeeds; otherwise, it returns <tt>NO</tt>.
*/
- (BOOL)addSubroutineNamed:(NSString *)name withScriptHandler:(NDScriptHandler *)scriptHandler;

/*!
	@method addEventClass:eventID:withScriptHandler:
	@abstract <#Abstract#>
	@discussion <#Discussion#>
	@param eventClass <#disc#>
	@param eventID <#disc#>
	@param scriptHandler <#disc#>
	@result This method returns <tt>YES</tt> if the operation succeeds; otherwise, it returns <tt>NO</tt>.
*/
- (BOOL)addEventClass:(AEEventClass)eventClass eventID:(AEEventID)eventID withScriptHandler:(NDScriptHandler *)scriptHandler;

/*!
	@method arrayOfPropertyNames
	@abstract Get array of property names.
	@discussion Returns an array of string for every property contained within the receiver.
	@result An <tt>NSArray</tt> of <tt>NSStrings</tt>
*/
- (NSArray *)arrayOfPropertyNames;
/*!
	@method hasPropertyName:
	@abstract Test if the reciever has a property
	@discussion <tt>hasPropertyName:</tt> test whether the reciever has a property with the name <tt><i>name</i></tt>.
	@param name The property name.
	@result This method returns <tt>YES</tt> if the reciever has the property; otherwise, it returns <tt>NO</tt>.
*/
- (BOOL)hasPropertyName:(NSString *)name;

/*!
	@method scriptDataForPropertyOfType:
	@abstract Test if the reciever has a property
	@discussion <tt>hasPropertyName:</tt> test whether the reciever has a property with the type <tt><i>propCode</i></tt>. For example <tt><i>propCode</i> = pASParent</tt> can test if the reciever has a parent script context.
	@param propCode <#disc#>
	@result <#result#>
*/
- (NDScriptData *)scriptDataForPropertyOfType:(DescType)propCode;

/*!
	@method scriptDataForPropertyNamed:
	@abstract <#Abstract#>
	@discussion <#Discussion#>
	@param propertyName The property name.
	@result <#result#>
*/
- (NDScriptData *)scriptDataForPropertyNamed:(NSString *)propertyName;
/*!
	@method setPropertyOfType:toScriptData:
	@abstract Sets the value of a script property.
	@discussion Sets the value of a script property within the reciever script.
	@param propCode <#disc#>
	@param scriptData A script data to be used to set the value for the property specified by <tt><i>propCode</i></tt>.
	@result This method returns <tt>YES</tt> if the operation succeeds; otherwise, it returns <tt>NO</tt>.
*/
- (BOOL)setPropertyOfType:(DescType)propCode toScriptData:(NDScriptData *)aScriptData;

/*!
	@method setPropertyNamed:toScriptData:
	@abstract Sets the value of a script property.
	@discussion Sets the value of a script property within the reciever script.
	@param propertyName Name of the property to set. The variable name is case-sensitive and must exactly match the case of the variable name as supplied by the method <tt>arrayOfPropertyNames</tt> or the method <tt>source</tt>.
	@param scriptData A script data to be used to set the value for the property specified by <tt><i>propertyName</i></tt>.
	@result Return <tt>YES</tt> if successful.
*/
- (BOOL)setPropertyNamed:(NSString *)propertyName toScriptData:(NDScriptData *)scriptData;
/*!
	@method changePropertyNamed:toScriptData:
	@abstract Changes the value of a script property.
	@discussion Changes the value of a script property within the reciever script, if the property does not already exist then <tt>changePropertyNamed:toScriptData:</tt> will fail.
	@param propertyName The property name.
	@param scriptData A script data to be used to set the value for the property specified by <tt><i>propertyName</i></tt>.
	@result This method returns <tt>YES</tt> if the operation succeeds; otherwise, it returns <tt>NO</tt>.
*/
- (BOOL)changePropertyNamed:(NSString *)propertyName toScriptData:(NDScriptData *)scriptData;

@end

/*!
	@category NSAppleEventDescriptor(NDScriptDataValueExtension)
	@abstract category of <tt>NSAppleEventDescriptor</tt>.
	@discussion adds a method to <tt>NSAppleEventDescriptor</tt> retrieve a <tt>NDScriptData</tt> or subclass from a <tt>NSAppleEventDescriptor</tt>.
*/
@interface NSAppleEventDescriptor (NDScriptDataValueExtension)
/*!
	@method scriptDataValue
	@abstract Category method for <tt>NSAppleEventDescriptor (NDScriptContextValueExtension)</tt>, converts any script data within a AppleEvent descriptor into an <tt>NDScriptContext</tt>
	@discussion If an AppleScript return a AppleScript as it&rsquo;s result, this method can be used to convert the result <tt>NSAppleEventDescriptor</tt> into a <tt>NDScriptContext</tt>. The <tt>NSAppleEventDescriptor</tt> method objectValue will use this method if available.
	@result a <tt>NDScriptContext</tt> object for the AppleScript contained within the AppleEvent descriptor.
*/
- (NDScriptData *)scriptDataValue;
/*!
	@method descriptorWithScriptData:
	@abstract <#Abstract#>
	@discussion <#Discussion#>
	@param scriptData <#disc#>
	@result <#result#>
*/
+ (NSAppleEventDescriptor *)descriptorWithScriptData:(NDScriptData *)scriptData;

@end

/*!
	@category NDScriptData(NDExtended)
	@abstract <#Abstract#>
	@discussion <#Discussion#>
*/
@interface NDScriptData (NDExtended)

/*!
	@method scriptDataWithAppleEventDescriptor:
	@abstract <#Abstract#>
	@discussion <#Discussion#>
	@param descriptor <#disc#>
	@result A new <tt>NDScriptData</tt>, or <tt>nil</tt> of creation fails.
*/
+ (id)scriptDataWithAppleEventDescriptor:(NSAppleEventDescriptor *)descriptor;

/*!
	@method scriptDataWithData:
	@abstract <#Abstract#>
	@discussion <#Discussion#>
	@param data The <tt>NSData</tt>  object.
	@result A new <tt>NDScriptData</tt>, or <tt>nil</tt> of creation fails
*/
+ (id)scriptDataWithData:(NSData *)data;

/*!
	@method scriptDataWithData:componentInstance:
	@abstract <#Abstract#>
	@discussion <#Discussion#>
	@param data The <tt>NSData</tt>  object.
	@param componentInstance The component instance to use, a value of <tt>nil</tt> to use the default AppleScript context.
	@result A new <tt>NDScriptData</tt>, or <tt>nil</tt> of creation fails
*/
+ (id)scriptDataWithData:(NSData *)data componentInstance:(NDComponentInstance *)componentInstance;

/*!
	@method scriptDataWithContentsOfURL:componentInstance:
	@abstract <#Abstract#>
	@discussion <#Discussion#>
	@param URL <#disc#>
	@param componentInstance The component instance to use, a value of <tt>nil</tt> to use the default AppleScript context.
	@result A new <tt>NDScriptData</tt>, or <tt>nil</tt> of creation fails
 */
+ (id)scriptDataWithContentsOfURL:(NSURL *)URL componentInstance:(NDComponentInstance *)componentInstance;

/*!
	@method scriptDataWithContentsOfURL:
	@abstract <#Abstract#>
	@discussion <#Discussion#>
	@param URL <#disc#>
	@result A new <tt>NDScriptData</tt>, or <tt>nil</tt> of creation fails
 */
+ (id)scriptDataWithContentsOfURL:(NSURL *)URL;

/*!
	@method scriptDataWithContentsOfFile:
	@abstract <#Abstract#>
	@discussion <#Discussion#>
	@param path The path of the script file.
	@result A new <tt>NDScriptData</tt>, or <tt>nil</tt> of creation fails
 */
+ (id)scriptDataWithContentsOfFile:(NSString *)path;

/*!
	@method scriptDataWithContentsOfFile:componentInstance:
	@abstract <#Abstract#>
	@discussion <#Discussion#>
	@param path The path of the script file.
	@param componentInstance The component instance to use, a value of <tt>nil</tt> to use the default AppleScript context.
	@result A new <tt>NDScriptData</tt>, or <tt>nil</tt> of creation fails
 */
+ (id)scriptDataWithContentsOfFile:(NSString *)path componentInstance:(NDComponentInstance *)componentInstance;

/*!
	@method scriptDataWithObject:componentInstance:
	@abstract <#Abstract#>
	@discussion <#Discussion#>
	@param object <#disc#>
	@param componentInstance The component instance to use, a value of <tt>nil</tt> to use the default AppleScript context.
	@result A new <tt>NDScriptData</tt>, or <tt>nil</tt> of creation fails
 */
+ (id)scriptDataWithObject:(id)object componentInstance:(NDComponentInstance *)componentInstance;

/*!
	@method scriptDataWithObject:
	@abstract <#Abstract#>
	@discussion <#Discussion#>
	@param object <#disc#>
	@result A new <tt>NDScriptData</tt>, or <tt>nil</tt> of creation fails
 */
+ (id)scriptDataWithObject:(id)object;
/*!
	@method initWithContentsOfFile:
	@abstract <#Abstract#>
	@discussion <#Discussion#>
	@param path The path of the script file.
	@result A initialized <tt>NDScriptData</tt>, or <tt>nil</tt> of initialization fails.
 */
- (id)initWithContentsOfFile:(NSString *)path;

/*!
	@method initWithContentsOfURL:
	@abstract <#Abstract#>
	@discussion <#Discussion#>
	@param URL <#disc#>
	@result A initialized <tt>NDScriptData</tt>, or <tt>nil</tt> of initialization fails.
 */
- (id)initWithContentsOfURL:(NSURL *)URL;

/*!
	@method initWithData:
	@abstract <#Abstract#>
	@discussion <#Discussion#>
	@param data The <tt>NSData</tt>  object.
	@result A initialized <tt>NDScriptData</tt>, or <tt>nil</tt> of initialization fails.
*/
- (id)initWithData:(NSData *)data;

/*!
	@method initWithObject:componentInstance:
	@abstract <#Abstract#>
	@discussion <#Discussion#>
	@param object <#disc#>
	@param componentInstance The component instance to use, a value of <tt>nil</tt> to use the default AppleScript context.
	@result A initialized <tt>NDScriptData</tt>, or <tt>nil</tt> of initialization fails.
 */
- (id)initWithObject:(id)object componentInstance:(NDComponentInstance *)componentInstance;

/*!
	@method initDataWithObject:
	@abstract <#Abstract#>
	@discussion <#Discussion#>
	@param object <#disc#>
	@result A initialized <tt>NDScriptData</tt>, or <tt>nil</tt> of initialization fails.
 */
- (id)initDataWithObject:(id)object;

/*!
	@method objectValue
	@abstract <#Abstract#>
	@discussion <#Discussion#>
	@result <#result#>
*/
- (id)objectValue;
/*!
	@method writeToURL:
	@abstract <#Abstract#>
	@discussion <#Discussion#>
	@param URL The file URL to write the script data file.
	@result This method returns <tt>YES</tt> if the operation succeeds; otherwise, it returns <tt>NO</tt>.
*/
- (BOOL)writeToURL:(NSURL *)URL;

/*!
	@method writeToFile:
	@abstract <#Abstract#>
	@discussion <#Discussion#>
	@param path The path to write the script data file.
	@result This method returns <tt>YES</tt> if the operation succeeds; otherwise, it returns <tt>NO</tt>.
*/
- (BOOL)writeToFile:(NSString *)path;

@end

/*!
    @category NDScriptHandler(NDExtended)
    @abstract <#Abstact#>
    @discussion <#Discussion#>
*/
@interface NDScriptHandler (NDExtended)
/*!
	@method scriptDataWithSource:
	@abstract <#Abstract#>
	@discussion <#Discussion#>
	@param source A <tt>NSString</tt> to be compilied.
	@result A new <tt>NDScriptHandler</tt>, or <tt>nil</tt> of creation fails.
 */
+ (id)scriptDataWithSource:(NSString *)source;

/*!
	@method scriptDataWithSource:componentInstance:
	@abstract <#Abstract#>
	@discussion <#Discussion#>
	@param source A <tt>NSString</tt> to be compilied.
	@param componentInstance The component instance to use, a value of <tt>nil</tt> to use the default AppleScript context.
	@result A new <tt>NDScriptHandler</tt>, or <tt>nil</tt> of creation fails.
 */
+ (id)scriptDataWithSource:(NSString *)source componentInstance:(NDComponentInstance *)componentInstance;
/*!
	@method initWithSource:
	@abstract <#Abstract#>
	@discussion <#Discussion#>
	@param source A <tt>NSString</tt> to be compilied.
	@result A initialized <tt>NDScriptHandler</tt>, or <tt>nil</tt> of initialization fails.
 */
- (id)initWithSource:(NSString *)source;
/*!
	@method initWithSource:componentInstance:
	@abstract <#Abstract#>
	@discussion <#Discussion#>
	@param source A <tt>NSString</tt> to be compilied.
	@param componentInstance The component instance to use, a value of <tt>nil</tt> to use the default AppleScript context.
	@result A initialized <tt>NDScriptHandler</tt>, or <tt>nil</tt> of initialization fails.
 */
- (id)initWithSource:(NSString *)source componentInstance:(NDComponentInstance *)componentInstance;
/*!
	@method resultAppleEventDescriptor
	@abstract Get the execution result.
	@discussion <#Discussion#>
	@result <#result#>
 */
- (NSAppleEventDescriptor *)resultAppleEventDescriptor;
/*!
	@method resultObject
	@abstract Get the execution result.
	@discussion <#Discussion#>
	@result <#result#>
 */
- (id)resultObject;
/*!
	@method resultData
	@abstract Get the execution result.
	@discussion <#Discussion#>
	@result <#result#>
 */
- (NSData *)resultData;
/*!
	@method resultAsString
	@abstract Get the execution result.
	@discussion <#Discussion#>
	@result <#result#>
 */
- (NSString *)resultAsString;
@end

/*!
	@category NDScriptContext(NDExtended)
	@abstract <#Abstract#>
	@discussion <#Discussion#>
*/
@interface NDScriptContext (NDExtended)

/*!
	@method scriptData
	@abstract <#Abstract#>
	@discussion <#Discussion#>
	@result A new <tt>NDScriptContext</tt>, or <tt>nil</tt> of creation fails.
 */
+ (id)scriptData;

/*!
	@method scriptDataWithName:
	@abstract <#Abstract#>
	@discussion <#Discussion#>
	@param name <#disc#>
	@result A new <tt>NDScriptContext</tt>, or <tt>nil</tt> of creation fails.
 */
+ (id)scriptDataWithName:(NSString *)name;

/*!
	@method compileExecuteSource:
	@abstract <#Abstract#>
	@discussion <#Discussion#>
	@param source A <tt>NSString</tt> to be compilied.
	@result A <tt>NDScriptData</tt> for the result from the execution the script <tt><i>source</i></tt>.
*/
+ (NDScriptData *)compileExecuteSource:(NSString *)source;

/*!
	@method scriptDataWithParentScriptData:name:
	@abstract <#Abstract#>
	@discussion <#Discussion#>
	@param parentScriptData A script data to set as the parent script, usually a script context.
	@param name <#disc#>
	@result A new <tt>NDScriptContext</tt>, or <tt>nil</tt> of creation fails.
*/
+ (id)scriptDataWithParentScriptData:(NDScriptData *)parentScriptData name:(NSString *)name;

/*!
	@method scriptDataWithParentScriptData:
	@abstract <#Abstract#>
	@discussion <#Discussion#>
	@param parentScriptData A script data to set as the parent script, usually a script context
	@result A new <tt>NDScriptContext</tt>, or <tt>nil</tt> of creation fails.
*/
+ (id)scriptDataWithParentScriptData:(NDScriptData *)parentScriptData;

/*!
	@method scriptDataWithSource:parentScriptData:
	@abstract <#Abstract#>
	@discussion <#Discussion#>
	@param source A <tt>NSString</tt> to be compilied.
	@param parentScriptData A script data to set as the parent script, usually a script context
	@result A new <tt>NDScriptContext</tt>, or <tt>nil</tt> of creation fails.
*/
+ (id)scriptDataWithSource:(NSString *)source parentScriptData:(NDScriptData *)parentScriptData;

/*!
	@method initWithParentScriptData:
	@abstract <#Abstract#>
	@discussion <#Discussion#>
	@param parentScriptData A script data to set as the parent script, usually a script context.
	@result A initialized <tt>NDScriptContext</tt>, or <tt>nil</tt> of initialization fails.
*/
- (id)initWithParentScriptData:(NDScriptData *)parentScriptData;

/*!
	@method initWithSource:modeFlags:parentScriptData:
	@abstract Initialize a <tt>NDSciptContext</tt>
	@discussion <#Discussion#>
	@param source A <tt>NSString</tt> to be compilied.
	@param modeFlags <#disc#>
	@param parentData <#disc#>
	@result A initialized <tt>NDScriptContext</tt>, or <tt>nil</tt> of initialization fails.
 */
- (id)initWithSource:(NSString *)source modeFlags:(long)modeFlags parentScriptData:(NDScriptData *)parentData;

/*!
	@method initWithSource:parentScriptData:
	@abstract <#Abstract#>
	@discussion <#Discussion#>
	@param source A <tt>NSString</tt> to be compilied.
	@param parentScriptData A script data to set as the parent script, usually a script context.
	@result A initialized <tt>NDScriptContext</tt>, or <tt>nil</tt> of initialization fails.
*/
- (id)initWithSource:(NSString *)source parentScriptData:(NDScriptData *)parentScriptData;

/*!
	@method parentObject
	@abstract Get a script objects parent.
	@discussion <#Discussion#>
	@result <#result#>
 */
- (id)parentObject;

/*!
	@method setParentObject:
	@abstract Set a script objects parent
	@discussion <#Discussion#>
	@param object <#disc#>
	@result This method returns <tt>YES</tt> if the operation succeeds; otherwise, it returns <tt>NO</tt>.
 */
- (BOOL)setParentObject:(id)object;

/*!
	@method executeOpen:
	@abstract <#Abstract#>
	@discussion <#Discussion#>
	@param parameters <#disc#>
	@result <#result#>
*/
- (BOOL)executeOpen:(NSArray *)parameters;

/*!
	@method executeSubroutineNamed:argumentsArray:
	@abstract <#Abstract#>
	@discussion <#Discussion#>
	@param name The subroutine name.
	@param array <#disc#>
	@result This method returns <tt>YES</tt> if the operation succeeds; otherwise, it returns <tt>NO</tt>.
*/
- (BOOL)executeSubroutineNamed:(NSString *)name argumentsArray:(NSArray *)array;

/*!
	@method executeSubroutineNamed:arguments:...
	@abstract <#Abstract#>
	@discussion <#Discussion#>
	@param name The subroutine name.
	@param firstObject <#disc#>
	@result This method returns <tt>YES</tt> if the operation succeeds; otherwise, it returns <tt>NO</tt>.
*/
- (BOOL)executeSubroutineNamed:(NSString *)name arguments:(id)firstObject, ...;

/*!
	@method executeSubroutineNamed:labelsAndArguments:...
	@abstract <#Abstract#>
	@discussion <#Discussion#>
	@param name The subroutine name.
	@param label <#disc#>
	@result This method returns <tt>YES</tt> if the operation succeeds; otherwise, it returns <tt>NO</tt>.
*/
- (BOOL)executeSubroutineNamed:(NSString *)name labelsAndArguments:(AEKeyword)label, ...;

/*!
	@method descriptorForPropertyNamed:
	@abstract <#Abstract#>
	@discussion <#Discussion#>
	@param propertyName The property name.
	@result <#result#>
*/
- (NSAppleEventDescriptor *)descriptorForPropertyNamed:(NSString *)propertyName;

/*!
	@method objectForPropertyNamed:
	@abstract <#Abstract#>
	@discussion <#Discussion#>
	@param propertyName The property name.
	@result <#result#>
*/
- (id)objectForPropertyNamed:(NSString *)propertyName;

/*!
	@method setPropertyNamed:toDescriptor:
	@abstract <#Abstract#>
	@discussion <#Discussion#>
	@param propertyName The property name.
	@param descriptor <#disc#>
	@result This method returns <tt>YES</tt> if the operation succeeds; otherwise, it returns <tt>NO</tt>.
*/
- (BOOL)setPropertyNamed:(NSString *)propertyName toDescriptor:(NSAppleEventDescriptor *)descriptor;

/*!
	@method changePropertyNamed:toDescriptor:
	@abstract <#Abstract#>
	@discussion <#Discussion#>
	@param propertyName The property name.
	@param descriptor <#disc#>
	@result This method returns <tt>YES</tt> if the operation succeeds; otherwise, it returns <tt>NO</tt>.
*/
- (BOOL)changePropertyNamed:(NSString *)propertyName toDescriptor:(NSAppleEventDescriptor *)descriptor;

/*!
	@method setPropertyNamed:toObject:
	@abstract <#Abstract#>
	@discussion <#Discussion#>
	@param propertyName The property name.
	@param object <#disc#>
	@result This method returns <tt>YES</tt> if the operation succeeds; otherwise, it returns <tt>NO</tt>.
*/
- (BOOL)setPropertyNamed:(NSString *)propertyName toObject:(id)object;

/*!
	@method changePropertyNamed:toObject:
	@abstract <#Abstract#>
	@discussion <#Discussion#>
	@param propertyName The property name.
	@param object <#disc#>
	@result This method returns <tt>YES</tt> if the operation succeeds; otherwise, it returns <tt>NO</tt>.
*/
- (BOOL)changePropertyNamed:(NSString *)propertyName toObject:(id)object;

/*!
	@method setExecutionModeNeverInteract:
	@abstract <#Abstract#>.
	@discussion Indicate whether or not the script may interact with the user if necessary. Adds <tt>kAENeverInteract</tt> to the <tt><i>sendMode</i></tt> parameter of <tt>AESend</tt> for events sent when the script is executed. This is equivalent to <tt>[self setExecutionModeFlags:flag?kOSAModeNeverInteract:0 mask:kOSAModeNeverInteract]</tt>
	@param flag <#result#>
 */
- (void)setExecutionModeNeverInteract:(BOOL)flag;

/*!
	@method executionModeNeverInteract
	@abstract <#Abstract#>.
	@discussion Indicate whether or not the script may interact with the user if necessary. Adds <tt>kAENeverInteract</tt> to the <tt><i>sendMode</i></tt> parameter of <tt>AESend</tt> for events sent when the script is executed. This is equivalent to <tt>([self executionModeFlags] & kOSAModeNeverInteract)</tt>
	@result Returns <tt>YES</tt> if never interact; otherwise returns <tt>NO</tt>.
 */
- (BOOL)executionModeNeverInteract;

/*!
	@method setExecutionModeCanInteract:
	@abstract <#Abstract#>.
	@discussion Indicate whether or not the script may interact with the user. Adds <tt>kAECanInteract</tt> to the <tt><i>sendMode</i></tt> parameter of <tt>AESend</tt> for events sent when the script is executed. This is equivalent to <tt>[self setExecutionModeFlags:flag?kOSAModeCanInteract:0 mask:kOSAModeCanInteract]</tt>
	@param flag <#result#>
 */
- (void)setExecutionModeCanInteract:(BOOL)flag;

/*!
	@method executionModeCanInteract
	@abstract <#Abstract#>.
	@discussion Indicate whether or not the script may interact with the user. Adds <tt>kAECanInteract</tt> to the <tt><i>sendMode</i></tt> parameter of <tt>AESend</tt> for events sent when the script is executed. This is equivalent to <tt>([self executionModeFlags] & kOSAModeCanInteract)</tt>
	@result Returns <tt>YES</tt> if CanInteract; otherwise returns <tt>NO</tt>.
 */
- (BOOL)executionModeCanInteract;

/*!
	@method setExecutionModeAlwaysInteract:
	@abstract <#Abstract#>.
	@discussion Indicate whether or not the script should always interact with the user. Adds <tt>kAEAlwaysInteract</tt> to the <tt><i>sendMode</i></tt> parameter of <tt>AESend</tt> for events sent when the script is executed. This is equivalent to <tt>[self setExecutionModeFlags:flag?kOSAModeAlwaysInteract:0 mask:kOSAModeAlwaysInteract]</tt>
	@param flag <#result#>
 */
- (void)setExecutionModeAlwaysInteract:(BOOL)flag;

/*!
	@method executionModeAlwaysInteract
	@abstract <#Abstract#>.
	@discussion Indicate whether or not the script should always interact with the user. Adds <tt>kAEAlwaysInteract</tt> to the <tt><i>sendMode</i></tt> parameter of <tt>AESend</tt> for events sent when the script is executed. This is equivalent to <tt>([self executionModeFlags] & kOSAModeAlwaysInteract)</tt>
	@result Returns <tt>YES</tt> if AlwaysInteract; otherwise returns <tt>NO</tt>.
 */
- (BOOL)executionModeAlwaysInteract;

/*!
	@method setExecutionModeCanSwitchLayer:
	@abstract <#Abstract#>.
	@discussion Indicate whether or not the script should always interact with the user. Adds <tt>kAECanSwitchLayer</tt> to the <tt><i>sendMode</i></tt> parameter of <tt>AESend</tt> for events sent when the script is executed. This is equivalent to <tt>[self setExecutionModeFlags:flag?0:kOSAModeCantSwitchLayer mask:kOSAModeCantSwitchLayer]</tt>
	@param flag <#result#>
 */
- (void)setExecutionModeCanSwitchLayer:(BOOL)flag;

/*!
	@method executionModeCanSwitchLayer
	@abstract <#Abstract#>.
	@discussion Indicate whether or not the script should always interact with the user. Adds <tt>kAECanSwitchLayer</tt> to the <tt><i>sendMode</i></tt> parameter of <tt>AESend</tt> for events sent when the script is executed. This is equivalent to <tt>([self executionModeFlags] & kOSAModeCantSwitchLayer) == 0</tt>
	@result Returns <tt>YES</tt> if can switch layer; otherwise returns <tt>NO</tt>.
 */
- (BOOL)executionModeCanSwitchLayer;

/*!
	@method setExecutionModeReconnect:
	@abstract <#Abstract#>.
	@discussion Indicate whether or not the script may reconnect if necessary. Adds <tt>kAEDontReconnect</tt> to the <tt><i>sendMode</i></tt> parameter of <tt>AESend</tt> for events sent when the script is executed. This is equivalent to <tt>[self setExecutionModeFlags:flag?0:kOSAModeDontReconnect mask:kOSAModeDontReconnect]</tt>
	@param flag <#result#>
 */
- (void)setExecutionModeReconnect:(BOOL)flag;

/*!
	@method executionModeReconnect
	@abstract <#Abstract#>.
	@discussion Indicate whether or not the script may reconnect if necessary. Adds <tt>kAEDontReconnect</tt> to the <tt><i>sendMode</i></tt> parameter of <tt>AESend</tt> for events sent when the script is executed. This is equivalent to <tt>([self executionModeFlags] & kOSAModeDontReconnect)</tt>
	@result Returns <tt>YES</tt> if reconnect; otherwise returns <tt>NO</tt>.
 */
- (BOOL)executionModeReconnect;

/*!
	@method setExecutionModeRecord:
	@abstract <#Abstract#>.
	@discussion Indicate whether AppleEvents should be sent with the <tt>kAEDontRecord</tt> mode flag. This flag is exactly the opposite the AppleEvent flag <tt>kAEDontRecord</tt>.  This is to provide a more convenient default, such as not supplying any mode (<tt>kOSANullMode</tt>) means to send events with <tt>kAEDontRecord</tt>.  Supplying the <tt>kOSAModeDoRecord</tt> mode flag will cause <tt>AESend</tt> to be called without <tt>kAEDontRecord</tt>. This is equivalent to <tt>[self setExecutionModeFlags:flag?kOSAModeDoRecord:0 mask:kOSAModeDoRecord]</tt>
	@param flag <#result#>
 */
- (void)setExecutionModeRecord:(BOOL)flag;

/*!
	@method executionModeRecord
	@abstract <#Abstract#>.
	@discussion Indicate whether AppleEvents should be sent with the <tt>kAEDontRecord</tt> mode flag. This flag is exactly the opposite the AppleEvent flag <tt>kAEDontRecord</tt>.  This is to provide a more convenient default, such as not supplying any mode (<tt>kOSANullMode</tt>) means to send events with <tt>kAEDontRecord</tt>.  Supplying the <tt>kOSAModeDoRecord</tt> mode flag will cause <tt>AESend</tt> to be called without <tt>kAEDontRecord</tt>. This is equivalent to <tt>([self executionModeFlags] & kOSAModeDoRecord)</tt>
	@result Returns <tt>YES</tt> if record; otherwise returns <tt>NO</tt>.
 */
- (BOOL)executionModeRecord;

@end

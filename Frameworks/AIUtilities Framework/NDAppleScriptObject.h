/*!
	@header NDAppleScriptObject
	@abstract Header file for <tt>NDAppleScriptObject</tt>.
	@discussion <tt>NDAppleScriptObject</tt> is used to represent compiled AppleScripts within Cocoa. The only restriction for use of this code is that you keep the comments with the head files especially my name. Use of this code is at your own risk yada yada yada...
 */


#import <Foundation/Foundation.h>
#import <Carbon/Carbon.h>
#import "NDAppleScriptObject_Protocols.h"

extern const short		kScriptResourceID;
extern const NSString	* NDAppleScriptOffendingObject;
extern const NSString	* NDAppleScriptPartialResult;

@class	NDComponentInstance;

/*!
	@class NDAppleScriptObject
	@abstract Class to represent an AppleScript.
	@discussion As well as representing an AppleScript, <tt>NDAppleScriptObject</tt> also can maintain separate context for each AppleScript, useful if you want to run each script within a seperate thread. <tt>NDAppleScriptObject</tt> is interface compatible with <tt>NSAppleScript</tt>
  */
@interface NDAppleScriptObject : NSObject
{
@private
	OSAID							compiledScriptID,
									resultingValueID;
	NDComponentInstance				* componentInstance;
	NSString						* scriptSource;
	long							executionModeFlags;
}

/*!
	@method compileExecuteString:
	@abstract Compiles and executes the AppleScript within the passed string.
	@discussion Executes the script by calling it&rsquo;s run handler.
	@param string  A string that contains the AppleScript source to be compiled and executed.
	@result  Returns the result of executing the AppleScript as a Objective-C object, see <tt> objectValue:</tt> for more details.
 */
+ (id)compileExecuteString:(NSString *)string;

/*!
	@method compileExecuteString:componentInstance:
	@abstract Compiles and executes the AppleScript within the passed string.
	@discussion Executes the script by calling it&rsquo;s run handler.
	@param string  A string that contains the AppleScript source to be compiled and executed.
	@param componentInstance The <tt>NDComponentInstance</tt> to use the AppleScript with.
	@result  Returns the result of executing the AppleScript as a Objective-C object. See <tt>resultObject</tt> for more details.
 */
+ (id)compileExecuteString:(NSString *)string componentInstance:(NDComponentInstance *)componentInstance;

/*!
	@method appleScriptObjectWithString:
	@abstract Returns an <tt>NDAppleScriptObject</tt> compiled from passed string.
	@discussion An autoreleasing version of <tt>initWithString:</tt> with mode flags set to <tt>kOSAModeCompileIntoContext</tt>.
	@param string  A string that contains the AppleScript source to be compiled.
	@result  Returns the <tt>NDAppleScriptObject</tt> instance.
 */
+ (id)appleScriptObjectWithString:(NSString *)string;
/*!
	@method appleScriptObjectWithString:componentInstance:
	@abstract Returns an <tt>NDAppleScriptObject</tt> compiled from passed string.
	@discussion An autoreleasing version of <tt>initWithString:</tt> with mode flags set to <tt>kOSAModeCompileIntoContext</tt>.
	@param string  A string that contains the AppleScript source to be compiled.
	@param componentInstance The <tt>NDComponentInstance</tt> to use the AppleScript with.
	@result  Returns the <tt>NDAppleScriptObject</tt> instance.
 */
+ (id)appleScriptObjectWithString:(NSString *)string componentInstance:(NDComponentInstance *)componentInstance;

/*!
	@method appleScriptObjectWithData:
	@abstract Returns an <tt>NDAppleScriptObject</tt> from the <tt>NSData</tt> containing a compiled AppleScript.
	@discussion An autoreleasing version of <tt>initWithData:</tt>.
	@param string  A string that contains the AppleScript source to be compiled.
	@result  Returns the <tt>NDAppleScriptObject</tt> instance.
 */
+ (id)appleScriptObjectWithData:(NSData *)data;

/*!
	@method appleScriptObjectWithData:componentInstance:
	@abstract Returns an <tt>NDAppleScriptObject</tt> from the <tt>NSData</tt> containing a compiled AppleScript.
	@discussion An autoreleasing version of initWithData:.
	@param string  A string that contains the AppleScript source to be compiled.
	@param componentInstance The <tt>NDComponentInstance</tt> to use the AppleScript with.
	@result  Returns the <tt>NDAppleScriptObject</tt> instance.
 */
+ (id)appleScriptObjectWithData:(NSData *)data componentInstance:(NDComponentInstance *)componentInstance;
/*!
	@method appleScriptObjectWithContentsOfFile:
	@abstract Returns an <tt>NDAppleScriptObject</tt> by reading in the compiled AppleScript at passed path.
	@discussion An autoreleasing version of initWithContentsOfFile:.
	@param path  A path to the compiled AppleScript file.
	@result  Returns the <tt>NDAppleScriptObject</tt> instance.
 */
+ (id)appleScriptObjectWithContentsOfFile:(NSString *)path;

/*!
	@method appleScriptObjectWithContentsOfFile:componentInstance:
	@abstract Returns an <tt>NDAppleScriptObject</tt> by reading in the compiled AppleScript at passed path.
	@discussion An autoreleasing version of initWithContentsOfFile:.
	@param path  A path to the compiled AppleScript file.
	@param componentInstance The <tt>NDComponentInstance</tt> to use the AppleScript with.
	@result  Returns the <tt>NDAppleScriptObject</tt> instance.
 */
+ (id)appleScriptObjectWithContentsOfFile:(NSString *)aPath componentInstance:(NDComponentInstance *)componentInstance;
/*!
	@method appleScriptObjectWithContentsOfURL:
	@abstract Returns an <tt>NDAppleScriptObject</tt> by reading in the compiled AppleScript at passed file URL.
	@discussion An autoreleasing version of initWithContentsOfURL:.
	@param URL  A file URL to the compiled AppleScript file.
	@result  Returns the <tt>NDAppleScriptObject</tt> instance.
 */
+ (id)appleScriptObjectWithContentsOfURL:(NSURL *)URL;
/*!
	@method appleScriptObjectWithContentsOfURL:componentInstance:
	@abstract Returns an <tt>NDAppleScriptObject</tt> by reading in the compiled AppleScript at passed file URL.
	@discussion An autoreleasing version of initWithContentsOfURL:.
	@param URL  A file URL to the compiled AppleScript file.
	@param componentInstance The <tt>NDComponentInstance</tt> to use the AppleScript with.
	@result  Returns the <tt>NDAppleScriptObject</tt> instance.
 */
+ (id)appleScriptObjectWithContentsOfURL:(NSURL *)URL componentInstance:(NDComponentInstance *)componentInstance;

/*!
	@method initWithString:
	@abstract Returns an <tt>NDAppleScriptObject</tt> compiled from passed string.
	@discussion initWithString:modeFlags: with the default component and mode flags of <tt>kOSAModeCompileIntoContext</tt>.
	@param string  A string that contains the AppleScript source to be compiled.
	@result  Returns the <tt>NDAppleScriptObject</tt> instance.
 */
- (id)initWithString:(NSString *)string;

/*!
	@method initWithString:modeFlags:
	@abstract Returns an <tt>NDAppleScriptObject</tt> compiled from passed string.
	@discussion initWithString:modeFlags: with the default component.
	@param string  A string that contains the AppleScript source to be compiled.
	@param modeFlags  Mode flags passed to OSACompile (see Apple OSA documentation).
	@result  Returns the <tt>NDAppleScriptObject</tt> instance.
 */
- (id)initWithString:(NSString *)string modeFlags:(long)modeFlags;
/*!
	@method initWithContentsOfFile:
	@abstract Initialises receiver with a compiled AppleScript file.
	@discussion Initialize the receiver with the compiled AppleScript file at the supplied path, the compiled AppleScript can be in either the resource fork or the data fork. If the file is not complied and is instead a AppleScript as text then you must read in the text of the file and pass it to <tt>initWithString:modeFlags:</tt>. 
	@param path The path for the compiled AppleScript file.
	@result An initialized <tt>NDAppleScriptObject</tt>
  */
- (id)initWithContentsOfFile:(NSString *)path;
/*!
	@method initWithContentsOfFile:component:
	@abstract Initialises receiver with a compiled AppleScript file.
	@discussion Initialize the receiver with the compiled AppleScript file at the supplied path and a <tt>NDComponentInstance</tt> as returned from the method <tt>+[NDComponentInstance findNextComponent]</tt>, the compiled AppleScript can be in either the resource fork or the data fork.  If the file is not complied and is instead a AppleScript as text then you must read in the text of the file and pass it to <tt>initWithString:modeFlags:</tt>. 
	@param path The path for the compiled AppleScript file.
	@param componentInstance The <tt>NDComponentInstance</tt> to use the AppleScript with.
	@result An initialized <tt>NDAppleScriptObject</tt>
 */
- (id)initWithContentsOfFile:(NSString *)path componentInstance:(NDComponentInstance *)componentInstance;
/*!
	@method initWithContentsOfURL:
	@abstract Initialises receiver with a compiled AppleScript file.
	@discussion Initialize the receiver with the compiled AppleScript file at the supplied file URL, the compiled AppleScript can be in either the resource fork or the data fork. If the file is not complied and is instead a AppleScript as text then use the <tt>initWithString:modeFlags:</tt> method instead obtaining the string with the method<tt>-[NSString initWithURL:]</tt>.
	@param URL The file URL for the compiled AppleScript file.
	@result An initialized <tt>NDAppleScriptObject</tt>
 */
- (id)initWithContentsOfURL:(NSURL *)URL;
/*!
	@method initWithContentsOfURL:component:
	@abstract Initialises receiver with a compiled AppleScript file.
	@discussion Initialize the receiver with the compiled AppleScript file at the supplied file URL and a <tt>NDComponentInstance</tt> as returned from the method <tt>+[NDComponentInstance findNextComponent]</tt>, the compiled AppleScript can be in either the resource fork or the data fork. If the file is not complied and is instead a AppleScript as text then use the <tt>initWithString:modeFlags:</tt> method instead obtaining the string with the method<tt>-[NSString initWithURL:]</tt>.
	@param URL The file URL for the compiled AppleScript file.
	@param componentInstance The <tt>NDComponentInstance</tt> to use the AppleScript with.
	@result An initialized <tt>NDAppleScriptObject</tt>
 */
- (id)initWithContentsOfURL:(NSURL *)URL componentInstance:(NDComponentInstance *)componentInstance;
/*!
	@method initWithData:
	@abstract Initialises receiver with compiled AppleScript data.
	@discussion Initialize the with a <tt>NSData</tt> object containing the data for an compiled AppleScript.
	@param data A <tt>NSData</tt> object containing the compiled AppleScript.
	@result An initialized <tt>NDAppleScriptObject</tt>
  */
- (id)initWithData:(NSData *)data;

/*!
	@method initWithString:modeFlags:component:
	@abstract Returns an <tt>NDAppleScriptObject</tt> compiled from passed string.
	@discussion Initialzes the recieve by compiling the recieved source, if compilation failes then the error can be returned with the method <tt>error</tt> and the method <tt>isCompiled</tt> returns false.
	@param URL  A file URL to the compiled AppleScript file.
	@result  Returns the <tt>NDAppleScriptObject</tt> instance.
 */
- (id)initWithString:(NSString *)string modeFlags:(long)modeFlags componentInstance:(NDComponentInstance *)componentInstance;
/*!
	@method initWithData:component:
	@abstract Initialises receiver with compiled AppleScript data.
	@discussion Initialize the with a <tt>NSData</tt> object containing the data for an compiled AppleScript and a <tt>NDComponentInstance</tt> as returned from the method <tt>+[NDComponentInstance findNextComponent]</tt>.
	@param data A <tt>NSData</tt> object containing the compiled AppleScript.
	@param componentInstance The <tt>NDComponentInstance</tt> to use the AppleScript with.
	@result An initialized <tt>NDAppleScriptObject</tt>
 */
- (id)initWithData:(NSData *)data componentInstance:(NDComponentInstance *)componentInstance;

/*!
	@method data
	@abstract Returns the compiled script within a <tt>NSData</tt> instance.
	@discussion The returned <tt>NSData</tt> instance contains a compiled script which can be
				passed to the <tt>initWithData:component:</tt> method.
	@result  Returns an <tt>NSData</tt> instance.
 */
- (NSData *)data;

/*!
	@method execute
	@abstract Executes the script.
	@discussion Executes the script.
	@result  Returns <tt>YES</tt> if execution was successful.
 */
- (BOOL)execute;

/*!
	@method executeOpen
	@abstract Sends an open event.
	@discussion Executes the script by calling its open handler passing an alias list creaed from parameters.
	@param parameters  An <tt>NSArray</tt> containing paths (<tt>NSString</tt>) or <tt>NSURL</tt>&rsquo;s which is
			converted into an alias list.
	@result  returns <tt>YES</tt> if execution was successful.
 */
- (BOOL)executeOpen:(NSArray *)parameters;

/*!
	@method executeEvent:
	@abstract Execute an AppleEvent.
	@discussion Sends an AppleEvent to the script.
	@param event  An <tt>NSAppleEventDescriptor</tt> containing the apple event.
	@result  Returns <tt>YES</tt> if execution was successful.
 */
- (BOOL)executeEvent:(NSAppleEventDescriptor *)event;

/*!
	@method executeSubroutineNamed:argumentsArray:
	@abstract Execute an AppleScript function.
	@discussion Executes the AppleScript subroutine <tt><i>name</i></tt> passing the objects within <tt>array</tt> as positional arguments after being converted to <tt>NSAppleEventDescriptor</tt>s with the method <tt>-[NSAppleEventDescriptor descriptorWithObject:]</tt>.
	@param name The function name, this is case insensitive.
	@param array An array of arguments.
	@result  Returns <tt>YES</tt> if execution was successful.
 */
- (BOOL)executeSubroutineNamed:(NSString *)name argumentsArray:(NSArray *)array;

/*!
	@method executeSubroutineNamed:arguments:...
	@abstract Execute an AppleScript function.
	@discussion Executes the AppleScript subroutine <tt><i>name</i></tt> passing the objects starting with <tt><i>firstObject</i></tt> as positional arguments after being converted to <tt>NSAppleEventDescriptor</tt>s with the method <tt>-[NSAppleEventDescriptor descriptorWithObject:]</tt>.
	@param name The function name, this is case insensitive.
	@param firstObject The first object of a list of arguments terminated with <tt>nil</tt>.
	@result  Returns <tt>YES</tt> if execution was successful.
 */
- (BOOL)executeSubroutineNamed:(NSString *)name arguments:(id)firstObject, ...;

/*!
	@method executeSubroutineNamed:labelsAndArguments:
	@abstract Execute an AppleScript function.
	@discussion <p><tt>executeSubroutineNamed:labelsAndArguments:</tt> executes an AppleScript subroutine with labeled arguments starting with the label <tt><i>label</i></tt>, if the keyword <tt>keyASPrepositionGiven</tt> is found the remaining arguments will be passed to the method <tt>userRecordDescriptorWithObjectAndKeys:arguments:</tt> and the result is given the keyword <tt>keyASUserRecordFields</tt>.</p>
	<p>For example to execute the AppleScript subroutine
	<blockquote>
		<pre><font color="#660000">foo</font> <font color="#000066">for</font> <font color="#660000"><i>arg1</i></font> <font color="#000066"><b>given</b></font> <font color="#005500">argument</font>:<font color="#660000"><i>arg2</i></font> </pre>
	</blockquote>
	you would do the following
	<blockquote>
		<pre>theSubroutine = [theAppleScript executeSubroutineNamed:&#64;"<font color="#660000">foo</font>"
	&#9;&#9;labelsAndArguments:<font color="#000066">keyASPrepositionFor</font>, <font color="#660000"><i>arg1</i></font>,
	&#9;&#9;<font color="#000066"><b>keyASPrepositionGiven</b></font>, <font color="#660000"><i>arg2</i></font>, &#64;"<font color="#005500">argument</font>", nil];</pre>
	</blockquote>
	which is equivalent to
	<blockquote>
		<pre>theSubroutine = [theAppleScript executeSubroutineNamed:&#64;"<font color="#660000">foo</font>"
		&#9;&#9;labelsAndArguments:<font color="#000066">keyASPrepositionFor</font>, <font color="#660000"><i>arg1</i></font>, <font color="#000066"><b>keyASUserRecordFields</b></font>,
		&#9;&#9;[NSAppleEventDescriptor userRecordDescriptorWithObjectAndKeys:<font color="#660000"><i>arg2</i></font>, &#64;"<font color="#005500">argument</font>", nil],
		&#9;&#9;(AEKeyword)0];</pre>
	</blockquote></p>
	<p>Possible keywords are;
	<blockquote><blockquote>
		<table border="1"  width="90%">
			<thead><tr><th>Key Word</th><th>AppleScript key word</th></tr></thead>
			<tr><td align="center"><tt>keyASPrepositionAbout</tt></td><td align="center"><tt>about</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionAbove</tt></td><td align="center"><tt>above</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionAgainst</tt></td><td align="center"><tt>against</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionApartFrom</tt></td><td align="center"><tt>apart from</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionAround</tt></td><td align="center"><tt>around</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionAsideFrom</tt></td><td align="center"><tt>aside from</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionAt</tt></td><td align="center"><tt>at</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionBelow</tt></td><td align="center"><tt>below</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionBeneath</tt></td><td align="center"><tt>beneath</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionBeside</tt></td><td align="center"><tt>beside</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionBetween</tt></td><td align="center"><tt>between</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionBy</tt></td><td align="center"><tt>by</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionFor</tt></td><td align="center"><tt>for</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionFrom</tt></td><td align="center"><tt>from</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionGiven</tt></td><td align="center"><tt>given</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionIn</tt></td><td align="center"><tt>in</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionInsteadOf</tt></td><td align="center"><tt>instead of</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionInto</tt></td><td align="center"><tt>into</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionOn</tt></td><td align="center"><tt>on</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionOnto</tt></td><td align="center"><tt>onto</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionOutOf</tt></td><td align="center"><tt>out of</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionOver</tt></td><td align="center"><tt>over</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionSince</tt></td><td align="center"><tt>since</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionThrough</tt></td><td align="center"><tt>through</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionThru</tt></td><td align="center"><tt>thru</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionTo</tt></td><td align="center"><tt>to</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionUnder</tt></td><td align="center"><tt>under</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionUntil</tt></td><td align="center"><tt>until</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionWith</tt></td><td align="center"><tt>with</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionWithout</tt></td><td align="center"><tt>without</tt></td></tr>
			<tr><td align="center"><tt>keyASUserRecordFields</tt></td><td align="center">key for a list descriptor of user record fields</td></tr>
		</table>
	</blockquote></blockquote></p>
	<p>To find out the rules for use of the key words see the AppleScript language documentation.</p>
	@param name The function name, this is case insensitive.
	@param label The first label of a list of labels and arguments, terminated with a 0 <tt>AEKeyword</tt> or <tt>nil</tt> if the end arguments follow the keyword <tt>keyASPrepositionGiven</tt>.
	@result  Returns <tt>YES</tt> if execution was successful.
 */
- (BOOL)executeSubroutineNamed:(NSString *)name labelsAndArguments:(AEKeyword)label, ...;

/*!
	@method arrayOfEventIdentifier
	@abstract Returns all event identifiers the script responds to.
	@discussion Returns an <tt>NSArray</tt> of <tt>NSDictionary</tt>s with the keys "<tt>EventClass</tt>" and "<tt>EventID</tt>".
	@result  Returns an <tt>NSArray</tt> of event identifier <tt>NSDictionary</tt>s.
 */
- (NSArray *)arrayOfEventIdentifier;

/*!
	@method respondsToEventClass:eventID:
	@abstract Tests whether the script responds to an AppleEvent.
	@discussion This method test whether the script responds to the passed event identifier.
	@param eventClass  The event class.
	@param eventID  The event identifier.
	@result  Returns true if the script reponds to the event identifier.
 */
- (BOOL)respondsToEventClass:(AEEventClass)eventClass eventID:(AEEventID)eventID;

/*!
	@method respondsToSubroutine:
	@abstract Tests whether the script responds to a subroutine call.
	@discussion This method test whether the script inplements the subroutine <tt><i>name</i></tt>, subroutine names are case insensitive and so the string <tt><i>name</i></tt> is converted to lower case first.
	@param name The subroutine name.
	@result  Returns true if the script reponds to the subroutine call.
 */
- (BOOL)respondsToSubroutine:(NSString *)name;

/*!
	@method arrayOfPropertyNames
	@abstract Get array of property names.
	@discussion Returns an array of string for every property contained within the receiver.
	@result An <tt>NSArray</tt> of <tt>NSStrings</tt>
 */
- (NSArray *)arrayOfPropertyNames;

/*!
	@method descriptorForPropertyNamed:
	@abstract <#Abstract#>
	@discussion <#Discussion#>
	@param variableName <#disc#>
	@result <#result#>
 */
- (NSAppleEventDescriptor *)descriptorForPropertyNamed:(NSString *)variableName;

/*!
	@method descriptorForPropertyNamed:
	@abstract <#Abstract#>
	@discussion <#Discussion#>
	@param variableName <#disc#>
	@result <#result#>
 */
- (id)valueForPropertyNamed:(NSString *)variableName;

/*!
	@method setPropertyNamed:toDescriptor:define:
	@abstract Sets the value of a script property.
	@discussion Sets the value of a script property within the recievers script.
	@param variableName Name of the property to set. The variable name is case-sensitive and must exactly match the case of the variable name as supplied by the OSAGetPropertyNames function or the OSAGetSource function.
	@param descriptor A descriptor whose associated data should be used to set the value for the property specified by <tt><i>variableName</i></tt>.
	@param define If yes and then property name does not exist then it is added to the receiver.
	@result Return <tt>YES</tt> if successful.
 */
- (BOOL)setPropertyNamed:(NSString *)variableName toDescriptor:(NSAppleEventDescriptor *)descriptor  define:(BOOL)define;
/*!
	@method setPropertyNamed:toValue:define:
	@abstract Sets the value of a script property.
	@discussion Sets the value of a script property within the recievers script.
	@param variableName Name of the property to set. The variable name is case-sensitive and must exactly match the case of the variable name as supplied by the OSAGetPropertyNames function or the OSAGetSource function.
	@param value An object which should be used to set the value for the property specified by <tt><i>variableName</i></tt>.
	@param define If yes and then property name does not exist then it is added to the receiver.
	@result Return <tt>YES</tt> if successful.
 */
- (BOOL)setPropertyNamed:(NSString *)variableName toValue:(id)value define:(BOOL)define;

/*!
	@method resultAppleEventDescriptor
	@abstract Returns the result as an AppleEvent type..
	@discussion Returns the result of the last script execution as an AppleEvent type within an <tt>NSAppleEventDescriptor</tt>.
	@result  The <tt>NSAppleEventDescriptor</tt> contains the AppleEvent type result.
 */
- (NSAppleEventDescriptor *)resultAppleEventDescriptor;

/*!
	@method resultObject
	@abstract Returns the result as an Objective-C object.
	@discussion Converts the AppleEvent type returned from the last script execution into an
				Objective-C object. The types currently supported are
	<blockquote>
		<table border="1"  width="90%">
			<thead><tr><th>AppleScript Type</th><th>Objective-C Class</th></tr></thead>
			<tr><td align="center">list</td><td align="center"><tt>NSArray</tt></td></tr>
			<tr><td align="center">record</td><td align="center"><tt>NSDictionary</tt></td></tr>
			<tr><td align="center">alias</td><td align="center"><tt>NSURL</tt></td></tr>
			<tr><td align="center">string</td><td align="center"><tt>NSString</tt></td></tr>
			<tr><td align="center">real<br>integer<br>boolean</td><td align="center"><tt>NSNumber</tt></td></tr>
			<tr><td align="center">script</td><td align="center"><tt>NDAppleScriptObject</tt></td></tr>
			<tr><td align="center">anything else</td><td align="center"><tt>NSData</tt></td></tr>
		</table>
	</blockquote> 
	@result  A subclass of <tt>NSObject</tt>.
 */
- (id)resultObject;

/*!
	@method resultData
	@abstract Returns the result as an <tt>NSData</tt> instance.
	@discussion Returns the raw bytes from the result AppleEvent type.
	@result  The NSData instance.
 */
- (id)resultData;

/*!
	@method resultAsString
	@abstract Returns the result as an OSA formatted string.
	@discussion Returns the result as a string by calling OSA&rsquo;s <tt>OSADisplay</tt> function. The result is
				in the same format as seen in Script Editor&rsquo;s result window.
	@result  The <tt>NSString</tt> result.
 */
- (NSString *)resultAsString;

/*!
	@method componentInstance
	@abstract Get the component instance.
	@discussion The <tt>NDComponentInstance</tt> represents the connection to the OSA component.
	@result A <tt>NDComponentInstance</tt>
  */
- (NDComponentInstance *)componentInstance;
/*!
	@method executionModeFlags
	@abstract Returns the execution mode flags.
	@discussion The flags are eqivelent to AESend flags.
	<blockquote><blockquote>
		<table border="1"  width="90%">
		<thead><tr><th>Flag</th><th>Description</th></tr></thead>
			<tr>
				<td align="center"><tt>kOSAModeNeverInteract</tt></td>
				<td>The server application should never interact with the user in response to any of the AppleEvents.</td>
			</tr>
			<tr>
				<td align="center"><tt>kOSAModeCanInteract</tt></td>
				<td>The server application can interact with the user in response to any AppleEvents.</td>
			</tr>
			<tr>
				<td align="center"><tt>kOSAModeAlwaysInteract</tt></td>
				<td>The server applcation can interact with the user.</td>
			</tr>
			<tr>
				<td align="center"><tt>kOSAModeCantSwitchLayer</tt></td>
				<td>If both the client and the sever allow interaction, and if the client application is the active application on the local computer and is waiting for a reply (that is, it has set the <tt>kAEWAitReply</tt> flag), <tt>kOSAModeCantSwitchLayer</tt> brings the server directly to the forground. Otherwise the Notification Manager is used to request the user bring the server application to the foreground.</td>
			</tr>
			<tr>
				<td align="center"><tt>kOSAModeDontReconnect</tt></td>
				<td>The AppleEvent Manager mus not automaticlly try to reconect if the receives a <tt>sessClosedErr</tt> result code from the PPC Toolbox.</td>
			</tr>
			<tr>
				<td align="center"><tt>kOSAModeDoRecord</tt></td>
				<td>Prevents use of <tt>kAEDontRecord</tt> in <tt>sendMode</tt> parameter if <tt>AESend</tt> for the events sent when the script is executed.</td>
			</tr>
		</table>
	</blockquote></blockquote>
 
	@result  A long int containing the execution mode flag bits.
 */
- (long)executionModeFlags;
/*!
	@method setExecutionModeFlags:
	@abstract Sets the execution mode flags.
	@discussion The flags are equivalent to AESend flags.
	<blockquote><blockquote>
	<table border="1"  width="90%">
		<thead><tr><th>Flag</th><th>Description</th></tr></thead>
			<tr>
				<td align="center"><tt>kOSAModeNeverInteract</tt></td>
				<td>The server application should never interact with the user in response to any of the AppleEvents.</td>
			</tr>
			<tr>
				<td align="center"><tt>kOSAModeCanInteract</tt></td>
				<td>The server application can interact with the user in response to any AppleEvents.</td>
			</tr>
			<tr>
				<td align="center"><tt>kOSAModeAlwaysInteract</tt></td>
				<td>The server applcation can interact with the user.</td>
			</tr>
			<tr>
				<td align="center"><tt>kOSAModeCantSwitchLayer</tt></td>
				<td>If both the client and the sever allow interaction, and if the client application is the active application on the local computer and is waiting for a reply (that is, it has set the <tt>kAEWAitReply</tt> flag), <tt>kOSAModeCantSwitchLayer</tt> brings the server directly to the forground. Otherwise the Notification Manager is used to request the user bring the server application to the foreground.</td>
			</tr>
			<tr>
				<td align="center"><tt>kOSAModeDontReconnect</tt></td>
				<td>The AppleEvent Manager mus not automaticlly try to reconect if the receives a <tt>sessClosedErr</tt> result code from the PPC Toolbox.</td>
			</tr>
			<tr>
				<td align="center"><tt>kOSAModeDoRecord</tt></td>
				<td>Prevents use of <tt>kAEDontRecord</tt> in <tt>sendMode</tt> parameter if <tt>AESend</tt> for the events sent when the script is executed.</td>
			</tr>
		</table>
	</blockquote></blockquote>
	@param  modeFlags a long containing the execution mode flag bits.
 */
- (void)setExecutionModeFlags:(long)modeFlags;

/*!
	@method appleEventTarget
	@abstract Returns an AppleEvent desriptor that can be used in constructing complete AppleEvents.
	@discussion When construction AppleEvents using the <tt>NSAppleEventDescriptor</tt> method  <tt>appleEventWithEventClass:eventID:targetDescriptor:returnID:transactionID:</tt> to send to the script with the <tt>NDAppleScriptObject</tt> method <tt>executeEvent:</tt> the <tt>NSAppleEventDescriptor</tt> return from this method can be used as the target discriptor.
	@result A <tt>NSAppleEventDescriptor</tt> to be used as an AppleEvent target.
 */
- (NSAppleEventDescriptor *)appleEventTarget;

/*!
	@method error
	@abstract Get AppleScript Errors.
	@discussion You can use <tt>error</tt> to get information about errors that occurred durring execution or compilation. The returned error info dictionary may contain entries that use any combination of the following keys, including no entries at all. The dictionary returns all of the same keys as within the error dictionary returned with some of Apple&rsquo;s <tt>NSAppleScript</tt> methods.
	<blockquote><blockquote>
		<table border="1"  width="90%">
			<thead><tr><th>Constant</th><th>Description</th></tr></thead>
			<tr>
				<td align="center"><tt>NSAppleScriptErrorMessage</tt></td>
				<td>An <tt>NSString</tt> that supplies a detailed description of the error condition.</td>
			</tr>
			<tr>
				<td align="center"><tt>NSAppleScriptErrorNumber</tt></td>
				<td>An <tt>NSNumber</tt> that specifies the error number.</td>
			</tr>
			<tr>
				<td align="center"><tt>NSAppleScriptErrorAppName</tt></td>
				<td>An <tt>NSString</tt> that specifies the name of the application that generated the error.</td>
			</tr>
			<tr>
				<td align="center"><tt>NSAppleScriptErrorBriefMessage</tt></td>
				<td>An <tt>NSString</tt> that provides a brief description of the error.</td>
			</tr>
			<tr>
				<td align="center"><tt>NSAppleScriptErrorRange</tt></td>
				<td>An <tt>NSValue</tt> that specifies a range.</td>
			</tr>
			<tr>
				<td align="center"><tt>NDAppleScriptOffendingObject</tt></td>
				<td>An <tt>NSAppleEventDescriptor</tt> that specifies an offending object.</td>
			</tr>
			<tr>
				<td align="center"><tt>NDAppleScriptPartialResult</tt></td>
				<td>An object that represent a partial result</td>
			</tr>
		</table>
	</blockquote></blockquote>
	@result A <tt>NSDictionary</tt>  containing error information
 */
- (NSDictionary *)error;

/*!
	@method compile
	@abstract Compile a AppleScript with default mode flags.
	@discussion Compiles the receiver with a mode flag of <tt>kOSAModeCompileIntoContext</tt>, if it is not already compiled. Returns <tt>YES</tt> for success or if the script was already compiled, <tt>NO</tt> otherwise. Currently <tt>NDAppleScriptObject</tt> compiles scripts at initialization and will only not be compiled if compilation failed.
	@result Returns <tt>YES</tt> if successful.
 */
- (BOOL)compile;

/*!
	@method compileWithModeFlags:
	@abstract Compile a AppleScript.
	@discussion Compiles the receiver with the supplied mode flags, if it is not already compiled. Returns <tt>YES</tt> for success or if the script was already compiled, <tt>NO</tt> otherwise. Currently <tt>NDAppleScriptObject</tt> compiles scripts at initialization and will only not be compiled if compilation faile.
	@param modeFlags  Mode flags passed to OSACompile (see Apple OSA documentation).
	@result Returns <tt>YES</tt> if successful.
 */
- (BOOL)compileWithModeFlags:(long)modeFlags;

/*!
	@method isCompiled
	@abstract Is the AppleScript compiled.
	@discussion Returns YES if the receiver is already compiled, NO otherwise. Currently <tt>NDAppleScriptObject</tt> compiles scripts at initialization and will only not be compiled if compilation faile
	@result Returns <tt>YES</tt> if the receiver is compiled.
 */
- (BOOL)isCompiled;

	/*!
	@method source
	@abstract Get the AppleScript source
	@discussion Returns the source code of the receiver if it is available, nil otherwise. It is possible for an <tt>NDAppleScriptObject</tt> to be a script for which the source code is not available but is nonetheless executable (a read-only script).

	@result A <tt>NSString</tt>
 */
- (NSString *)source;

/*!
	@method writeToURL:
	@abstract Writes the receiver as a complied AppleScript.
	@discussion The compiled script is written to the <tt>'scpt'</tt> resource, id <tt>128</tt> of the resource fork of the file.
	@param URL  A file URL for the compiled AppleScript file.
	@result Returns <tt>YES</tt> if writing succeeded.
 */
- (BOOL)writeToURL:(NSURL *)URL;
/*!
	@method writeToURL:inDataFork:atomically:
	@abstract Writes the receiver as a complied AppleScript.
	@discussion If <tt><i>inDataFork</i></tt> is <tt>YES</tt> then the compiled script is written to the data fork of the file otherwise the compiled script is written to the <tt>'scpt'</tt> resource, id <tt>128</tt> of the resource fork of the file. If <tt><i>atomically</i></tt> is <tt>YES</tt> and <tt><i>inDataFork</i></tt> is <tt>YES</tt> then the receiver is written to a copy of the file which then replaces the original.
	@param URL  A file URL for the compiled AppleScript file.
	@param inDataFork <tt>YES</tt> to write the receiver to the data fork instead of the resource fork.
	@param atomically Write the file attomically.
	@result Return <tt>YES</tt> if writing succeeded.
 */
- (BOOL)writeToURL:(NSURL *)URL inDataFork:(BOOL)inDataFork atomically:(BOOL)atomically;

	/*!
	@method writeToURL:Id:
	@abstract Writes the receiver as a complied AppleScript.
	@discussion The compiled script is written to the <tt>'scpt'</tt> resource, with the passed id of the resource fork of the file.
	@param URL  A file URL for the compiled AppleScript file.
	@param ID  The resource id for the compiled AppleScript data.
	@result Return <tt>YES</tt> if writing succeeded.
 */
- (BOOL)writeToURL:(NSURL *)URL Id:(short)ID;
/*!
	@method writeToFile:
	@abstract Writes the receiver as a complied AppleScript.
	@discussion The compiled script is written to the <tt>'scpt'</tt> resource, id <tt>128</tt> of the resource fork of the file.
	@param path  A path for the compiled AppleScript file.
	@result Return <tt>YES</tt> if writing succeeded.
 */
- (BOOL)writeToFile:(NSString *)path;
/*!
	@method writeToFile:inDataFork:atomically:
	@abstract Writes the receiver as a complied AppleScript.
	@discussion If <tt><i>inDataFork</i></tt> is <tt>YES</tt> then the compiled script is written to the data fork of the file otherwise the compiled script is written to the <tt>'scpt'</tt> resource, id <tt>128</tt> of the resource fork of the file. If <tt><i>atomically</i></tt> is <tt>YES</tt> and <tt><i>inDataFork</i></tt> is <tt>YES</tt> then the receiver is written to a copy of the file which then replaces the original.
	@param path  A path for the compiled AppleScript file.
	@param inDataFork <tt>YES</tt> to write the receiver to the data fork instead of the resource fork.
	@param atomically Write the file attomically.
	@result Return <tt>YES</tt> if writing succeeded.
 */
- (BOOL)writeToFile:(NSString *)path inDataFork:(BOOL)inDataFork atomically:(BOOL)atomically;
/*!
	@method writeToFile:Id:
	@abstract Writes the receiver as a complied AppleScript.
	@discussion The compiled script is written to the <tt>'scpt'</tt> resource, with the passed id of the resource fork of the file.
	@param path  A path for the compiled AppleScript file.
	@param ID  The resource id for the compiled AppleScript data.
	@result Return <tt>YES</tt> if writing succeeded.
*/
- (BOOL)writeToFile:(NSString *)path Id:(short)ID;

@end

/*!
	@category NSAppleEventDescriptor(NDAppleScriptValueExtension)
	@abstract Category of <tt>NSAppleEventDescriptor</tt>.
	@discussion Adds a method to <tt>NSAppleEventDescriptor</tt> to retrieve a <tt>NDAppleScriptObject</tt> from a <tt>NSAppleEventDescriptor</tt>.
 */
@interface NSAppleEventDescriptor (NDAppleScriptObjectValueExtension)
/*!
	@method appleScriptValue
	@abstract Category method for <tt>NSAppleEventDescriptor (NDAppleScriptObjectValueExtension)</tt>, converts any script data within a AppleEvent descriptor into an <tt>NDAppleScriptObject</tt>
	@discussion If an AppleScript return a AppleScript as it&rsquo;s result, this method can be used to convert the result <tt>NSAppleEventDescriptor</tt> into a <tt>NDAppleScriptObject</tt>. The <tt>NSAppleEventDescriptor</tt> method objectValue will use this method if available.
	@result A <tt>NDAppleScriptObject</tt> object for the AppleScript contained within the AppleEvent descriptor.
 */
- (NDAppleScriptObject *)appleScriptValue;
@end

/*!
	@category NDAppleScriptObject(NSAppleScriptCompatibility)
	@abstract Provides interface compatibility with Apple&rsquo;s <tt>NSAppleScript</tt>
	@discussion Adds methods to <tt>NDAppleScriptObject</tt> to make it interface compatible with <tt>NSAppleScript</tt>. The methods are <tt>initWithContentsOfURL:error:</tt>, <tt>initWithSource:</tt>, <tt>compileAndReturnError:</tt>, <tt>executeAndReturnError:</tt> and <tt>executeAppleEvent:error:</tt>.
 */
@interface NDAppleScriptObject (NSAppleScriptCompatibility)
/*!
	@method initWithContentsOfURL:error:
	@abstract Initialize a <tt>NDAppleScriptObject</tt>.
	@discussion This method is for interface compatibility with Apple&rsquo;s <tt>NSAppleScript</tt>
	@param url A file URL for the compiled AppleScript file.
	@param errorInfo On return contains a <tt>NSDictionary</tt> contain error information.
	@result An initalized <tt>NDAppleScriptObject</tt>
 */
- (id)initWithContentsOfURL:(NSURL *)url error:(NSDictionary **)errorInfo;

/*!
	@method initWithSource:
	@abstract Initialize a <tt>NDAppleScriptObject</tt>.
	@discussion This method is for interface compatibility with Apple&rsquo;s <tt>NSAppleScript</tt>, it is equivalent to <tt>initWithString:</tt> but without compiling of the source.
	@result A <tt>NDAppleScriptObject</tt> object.
 */
- (id)initWithSource:(NSString *)source;

/*!
	@method compileAndReturnError:
	@abstract Compile an AppleScript.
	@discussion This method is for interface compatibility with Apple&rsquo;s <tt>NSAppleScript</tt>
	@param errorInfo If compilation fails, this is set to an <tt>NSDictionary</tt> containing error information. Otherwise, it is set to nil.
	@result Returns <tt>YES</tt> on success.
 */
- (BOOL)compileAndReturnError:(NSDictionary **)errorInfo;

/*!
	@method executeAndReturnError:
	@abstract Execute an AppleScript.
	@discussion This method is for interface compatibility with Apple&rsquo;s <tt>NSAppleScript</tt>
	@param errorInfo If execution fails, this is set to an <tt>NSDictionary</tt> containing error information. Otherwise, it is set to nil.
	@result Returns <tt>YES</tt> on success.
 */
- (NSAppleEventDescriptor *)executeAndReturnError:(NSDictionary **)errorInfo;

/*!
	@method executeAppleEvent:error:
	@abstract Execute an AppleScript.
	@discussion This method is for interface compatibility with Apple&rsquo;s <tt>NSAppleScript</tt>
	@param event  An <tt>NSAppleEventDescriptor</tt> containing the apple event.
	@param errorInfo If execution fails, this is set to an <tt>NSDictionary</tt> containing error information. Otherwise, it is set to nil.
	@result Returns the result <tt>NSAppleEventDescriptor</tt> on success, <tt>nil</tt> otherwise.
 */
- (NSAppleEventDescriptor *)executeAppleEvent:(NSAppleEventDescriptor *)event error:(NSDictionary **)errorInfo;

@end

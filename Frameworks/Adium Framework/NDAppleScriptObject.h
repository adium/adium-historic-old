/*!
	@header NDAppleScriptObject.h
	@abstract Header file from the project NDAppleScriptObjectProjectAlpha
	@discussion 
 
	Created by Nathan Day on Mon May 17 2004.
	Copyright &#169; 2003 Nathan Day. All rights reserved.
 */
#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>
#import "NDScriptData.h"
#import "NDAppleScriptObject_Protocols.h"


/*!
	@class NDAppleScriptObject
	@abstract Class to represent an AppleScript.
	@discussion As well as representing an AppleScript, <tt>NDAppleScriptObject</tt> also can maintain seperate context for each AppleScript, useful if you want to run each script within a seperate thread. <tt>NDAppleScriptObject</tt> is interface compatabile with <tt>NSAppleScript</tt>
*/
@interface NDAppleScriptObject : NDScriptContext
{
@protected
	NSString			* source;
	NSDictionary	* error;
}
/*!
	@method compileExecuteString:componentInstance:
	@abstract <#Abstract#>
	@discussion <#Discussion#>
	@param string <#disc#>
	@param componentInstance <#disc#>
	@result <#result#>
 */
+ (id)compileExecuteString:(NSString *)string componentInstance:(NDComponentInstance *)componentInstance;

/*!
	@method compileExecuteString:
	@abstract <#Abstract#>
	@discussion <#Discussion#>
	@param string <#disc#>
	@result <#result#>
 */
+ (id)compileExecuteString:(NSString *)string;

/*!
	@method error
	@abstract <#Abstract#>
	@discussion <#Discussion#>
	@result <#result#>
 */
- (NSDictionary *)error;

/*!
	@method setSource:
	@abstract <#Abstract#>
	@discussion <#Discussion#>
	@param source <#disc#>
	@result <#result#>
 */
- (void)setSource:(NSString *)source;

/*!
	@method compileWithModeFlags:
	@abstract <#Abstract#>
	@discussion <#Discussion#>
	@param modeFlags <#disc#>
	@result <#result#>
 */
- (BOOL)compileWithModeFlags:(long)modeFlags;

/*!
	@method isCompiled
	@abstract <#Abstract#>
	@discussion <#Discussion#>
	@result <#result#>
 */
- (BOOL)isCompiled;

/*!
	@method writeToURL:inDataFork:atomically:
	@abstract <#Abstract#>
	@discussion <#Discussion#>
	@param URL <#disc#>
	@param inDataFork <#disc#>
	@param atomically <#disc#>
	@result <#result#>
 */
- (BOOL)writeToURL:(NSURL *)URL inDataFork:(BOOL)inDataFork atomically:(BOOL)atomically;

/*!
	@method writeToFile:inDataFork:atomically:
	@abstract <#Abstract#>
	@discussion <#Discussion#>
	@param path <#disc#>
	@param inDataFork <#disc#>
	@param atomically <#disc#>
	@result <#result#>
 */
- (BOOL)writeToFile:(NSString *)path inDataFork:(BOOL)inDataFork atomically:(BOOL)atomically;

/*!
	@method writeToURL:Id:
	@abstract <#Abstract#>
	@discussion <#Discussion#>
	@param URL <#disc#>
	@param ID <#disc#>
	@result <#result#>
 */
- (BOOL)writeToURL:(NSURL *)URL Id:(short)ID;

/*!
	@method writeToFile:Id:
	@abstract <#Abstract#>
	@discussion <#Discussion#>
	@param path <#disc#>
	@param ID <#disc#>
	@result <#result#>
 */
- (BOOL)writeToFile:(NSString *)path Id:(short)ID;

@end

@interface NDAppleScriptObject (NDExtended)
+ (id)appleScriptObjectWithString:(NSString *)string;
+ (id)appleScriptObjectWithString:(NSString *)string componentInstance:(NDComponentInstance *)componentInstance;
+ (id)appleScriptObjectWithData:(NSData *)data;
+ (id)appleScriptObjectWithData:(NSData *)data componentInstance:(NDComponentInstance *)componentInstance;
+ (id)appleScriptObjectWithContentsOfFile:(NSString *)path;
+ (id)appleScriptObjectWithContentsOfFile:(NSString *)path componentInstance:(NDComponentInstance *)componentInstance;
+ (id)appleScriptObjectWithContentsOfURL:(NSURL *)URL;
+ (id)appleScriptObjectWithContentsOfURL:(NSURL *)URL componentInstance:(NDComponentInstance *)componentInstance;
- (id)initWithString:(NSString *)string componentInstance:(NDComponentInstance *)componentInstance;
- (BOOL)compile;
@end

/*!
@category NDAppleScriptObject(NSAppleScriptCompatibility)
	@abstract Provides interface compatability with Apples <tt>NSAppleScript</tt>
	@discussion Adds methods to <tt>NDAppleScriptObject</tt> to make it interface compatible with <tt>NSAppleScript</tt>. The methods are <tt>initWithContentsOfURL:error:</tt>, <tt>compileAndReturnError:</tt>, <tt>executeAndReturnError:</tt> and <tt>executeAppleEvent:error:</tt>.
 */
@interface NDAppleScriptObject (NSAppleScriptCompatibility)
/*!
@method initWithContentsOfURL:error:
	@abstract Initialize a <tt>NDAppleScriptObject</tt>.
	@discussion This method is for interface compatability with Apples <tt>NSAppleScript</tt>
	@param url A file url for the compiled AppleScipt file.
	@param errorInfo On return contains a <tt>NSDictionary</tt> contain errror information.
	@result An initalized <tt>NDAppleScriptObject</tt>
 */
- (id)initWithContentsOfURL:(NSURL *)url error:(NSDictionary **)errorInfo;

	/*!
		 @method initWithSource:
	 @abstract Initialize a <tt>NDAppleScriptObject</tt>.
	 @discussion This method is for interface compatability with Apples <tt>NSAppleScript</tt>, it is equivelent to <tt>initWithString:</tt> but without compiling of the source.
	 @result A <tt>NDAppleScriptObject</tt> object.
	 */
- (id)initWithSource:(NSString *)source;

	/*!
@method compileAndReturnError:
	 @abstract Compile an AppleScipt.
	 @discussion This method is for interface compatability with Apples <tt>NSAppleScript</tt>
	 @param errorInfo On return contains a <tt>NSDictionary</tt> contain errror information.
	 @result Returns <tt>YES</tt> on success.
	 */
- (BOOL)compileAndReturnError:(NSDictionary **)errorInfo;

	/*!
  @method executeAndReturnError:
	 @abstract Execute an AppleScript.
	 @discussion This method is for interface compatability with Apples <tt>NSAppleScript</tt>
	 @param errorInfo On return contains a <tt>NSDictionary</tt> contain errror information.
	 @result Returns <tt>YES</tt> on success.
	 */
- (NSAppleEventDescriptor *)executeAndReturnError:(NSDictionary **)errorInfo;

	/*!
	@method executeAppleEvent:error:
	 @abstract Execute an AppleScript.
	 @discussion This method is for interface compatability with Apples <tt>NSAppleScript</tt>
	 @param event  an <tt>NSAppleEventDescriptor</tt> containing the apple event.
	 @param errorInfo On return contains a <tt>NSDictionary</tt> contain errror information.
	 @result Returns the result <tt>NSAppleEventDescriptor</tt> on success, <tt>nil</tt> otherwise.
	 */
- (NSAppleEventDescriptor *)executeAppleEvent:(NSAppleEventDescriptor *)event error:(NSDictionary **)errorInfo;

@end



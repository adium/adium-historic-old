//
//  AIAppleScriptAdditions.h
//  Adium
//
//  Created by Adam Iser on Mon Feb 16 2004.
//

/*!
 * @category NSAppleScript(AIAppleScriptAdditions)
 * @brief Provides methods for executing functions in an NSAppleScript
 *
 * These methods allow functions to be executed within an NSApplescript and arguments to be passed to those functions
 */
@interface NSAppleScript (AIAppleScriptAdditions)

/*!
 * @brief Exceute a function
 *
 * Executes a function <b>functionName</b> within the <tt>NSAppleScript</tt>, returning error information if necessary
 * @param functionName An <tt>NSString</tt> of the function to be called. It is case sensitive.
 * @param errorInfo A reference to an <tt>NSDictionary</tt> variable, which will be filled with error information if needed. It may be nil if error information is not requested.
 * @return An <tt>NSAppleEventDescriptor</tt> generated by executing the function.
 */
- (NSAppleEventDescriptor *)executeFunction:(NSString *)functionName error:(NSDictionary **)errorInfo;

/*!
 * @brief Exceute a function with arguments
 *
 * Executes a function <b>functionName</b> within the <tt>NSAppleScript</tt>, returning error information if necessary. Arguments in <b>argumentArray</b> are passed to the function.
 * @param functionName An <tt>NSString</tt> of the function to be called. It is case sensitive.
 * @param argumentArray An <tt>NSArray</tt> of <tt>NSString</tt>s to be passed to the function when it is called.
 * @param errorInfo A reference to an <tt>NSDictionary</tt> variable, which will be filled with error information if needed. It may be nil if error information is not requested.
 * @return An <tt>NSAppleEventDescriptor</tt> generated by executing the function.
 */
- (NSAppleEventDescriptor *)executeFunction:(NSString *)functionName withArguments:(NSArray *)argumentArray error:(NSDictionary **)errorInfo;

@end

/*!
	@header NSArray+NDUtilities
	@abstract Category of NSArray
 */

#import <Cocoa/Cocoa.h>
#import "NSArray+NDUtilities.h"

/*!
	@category NSArray(NDUtilities)
	@abstract Additional methods for <tt>NSArray</tt>
	@discussion Provides some ussfull methods for <tt>NSArray</tt>.
 */
@interface NSArray (NDUtilities)

/*!
	@method arrayByUsingFunction:
	@abstract Returns an array of the result a function passed every object.
	@discussion Every object in the receiver is passed to the supplied function and all of the none <tt>nil</tt> results are added to a new <tt>NSArray</tt>. A pointer to a <tt>BOOL</tt> is also passed to the function and if the value it points to is change to <tt>NO</tt> by then function then the enumeration stops. The function should be of the form
	<blockquote>
		<tt>id <i>func</i>( id <i>anObject</i>, BOOL * <i>aFlag</i>)</tt>
		<blockquote>
			<table border = "1"  width = "90%">
				<thead><tr><th>Name</th><th>Description</th></tr></thead>
				<tr><td align = "center"><tt>func</tt></td><td>The function name.</td><tr>
				<tr><td align = "center"><tt>anObject</tt></td><td>The object passed to the function.</td><tr>
				<tr><td align = "center"><tt>aFlag</tt></td><td>A pointer to a <tt><i>BOOL</i></tt> used to stop enumeration over all of the object in the <tt>NSArray</tt>.</td><tr>
			</table>
		</blockquote>
		<b>Result:</b> The object to add to the new array or <tt>nil</tt> to add no object.
	</blockquote>
	@param func The function pointer.
	@result The results <tt>NSArray</tt>
 */
- (NSArray *)arrayByUsingFunction:(id (*)(id, BOOL *))func;

/*!
	@method everyObjectOfKindOfClass:
	@abstract Get every object of given kind.
	@discussion <tt>everyObjectOfKindOfClass:</tt> returns a new array containing every object the returns true the the method <tt>isKindOfClass:</tt>.
	@param class The class to test each object with. 
	@result The result <tt>NSArray</tt>.
  */
- (NSArray *)everyObjectOfKindOfClass:(Class)class;

/*!
	@method makeObjectsPerformFunction:
	@abstract Passes every object to the function.
	@discussion Every object in the receiver is passed to the supplied function. If the function returns <tt>NO</tt> the enumeration stops and <tt>makeObjectsPerformFunction:</tt> returns <tt>NO</tt>, otherwises <tt>makeObjectsPerformFunction:</tt> returns <tt>YES</tt>.
	@param func The function pointer.
	@result Returns <tt>YES</tt> every the function returned <tt>YES</tt> fro every object.
 */
- (BOOL)makeObjectsPerformFunction:(BOOL (*)(id))func;

/*!
	@method makeObjectsPerformFunction:withContext:
	@abstract Passes every object to the function.
	@discussion Every object in the receiver is passed to the supplied function as well as the supplied pointer. If the function returns <tt>NO</tt> the enumeration stops and <tt>makeObjectsPerformFunction:withContext:</tt> returns <tt>NO</tt>, otherwises <tt>makeObjectsPerformFunction:withContext:</tt> returns <tt>YES</tt>.
	@param func The function pointer.
	@param context A pointer to any data for the function.
	@result Returns <tt>YES</tt> every the function returned <tt>YES</tt> fro every object.
 */
- (BOOL)makeObjectsPerformFunction:(BOOL (*)(id, void *))func withContext:(void*)context;
/*!
	@method makeObjectsPerformFunction:withObject:
	@abstract Passes every object to the function.
	@discussion Every object in the receiver is passed to the supplied function as well as the supplied pointer. If the function returns <tt>NO</tt> the enumeration stops and <tt>makeObjectsPerformFunction:withObject:</tt> returns <tt>NO</tt>, otherwises <tt>makeObjectsPerformFunction:withObject:</tt> returns <tt>YES</tt>.
	@param func The function pointer.
	@param object A object for the function.
	@result Returns <tt>YES</tt> every the function returned <tt>YES</tt> fro every object.
 */
- (BOOL)makeObjectsPerformFunction:(BOOL (*)(id, id))func withObject:(id)onject;
/*!
	@method findObjectWithFunction:
	@abstract Find an object by using a function 
	@discussion Each object is passsed to the function <tt><i>func</i></tt> until the function returns true in which case the object is returned
	@param func The function used to test each object.
	@result The found object or nil if none is found
 */
- (id)findObjectWithFunction:(BOOL (*)(id))func;

/*!
	@method findObjectWithFunction:withContext:
	@abstract Find an object by using a function
	@discussion Each object and the <tt><i>context</i></tt> is passsed to the function <tt><i>func</i></tt> until the function returns true in which case the object is returned.
	@param func The function used to test each object.
	@param context A point to some data to be passed to the passed in function.
	@result The found object or nil if none is found
*/
- (id)findObjectWithFunction:(BOOL (*)(id, void *))func withContext:(void*)context;

	/*!
	@method findObjectWithFunction:
	 @abstract Find an object by using a function 
	 @discussion Each object is passsed to the function <tt><i>func</i></tt> returning every object that returns true.
	 @param func The function used to test each object.
	 @result The found object or nil if none is found
	 */
- (NSArray *)findAllObjectWithFunction:(BOOL (*)(id))func;

/*!
	@method findObjectWithFunction:withContext:
	@abstract Find objects by using a function
	@discussion Each object and the <tt><i>context</i></tt> is passsed to the function <tt><i>func</i></tt> returning every object that returns true.
	@param func The function used to test each object.
	@param context A point to some data to be passed to the passed in function.
	@result The found object or nil if none is found
 */
- (NSArray *)findAllObjectWithFunction:(BOOL (*)(id, void *))func withContext:(void*)context;

/*!
	@method indexOfObjectWithFunction:
	@abstract Find an object by using a function
	@discussion Each object is passsed to the function <tt><i>func</i></tt> until the function returns true in which case the index of the object is returned, if no object is found the <tt>NSNotFound</tt>.
	@param func The function used to test each object.
	@result The index of the found object or <tt>NSNotFound</tt> if no object found.
 */
- (unsigned int)indexOfObjectWithFunction:(BOOL (*)(id))func;

/*!
	@method indexOfObjectWithFunction:withContext:
	@abstract Find an object by using a function
	@discussion Each object and the <tt><i>context</i></tt> is passsed to the function <tt><i>func</i></tt> until the function returns true in which case the index of the object is returned, if no object is found the <tt>NSNotFound</tt>.
	@param func The function used to test each object.
	@param context A point to some data to be passed to the passed in function.
	@result The index of the found object or <tt>NSNotFound</tt> if no object found.
 */
- (unsigned int)indexOfObjectWithFunction:(BOOL (*)(id, void *))func withContext:(void*)context;

/*!
	@method sendEveryObjectToTarget:withSelector:
	@abstract Pass contents to an object.
	@discussion <tt>sendEveryObjectToTarget:withSelector:</tt> passes every object within the reciever to the object <tt>target</tt> one at a time through the selector <tt>selector</tt>. The returned value of the selector <tt>selector</tt> is ignored.
	@param target The object each object in the reciever is sent to.
	@param selector The selector for the message sent to <tt>target</tt>
 */
- (void)sendEveryObjectToTarget:(id)target withSelector:(SEL)selector;

/*!
	@method sendEveryObjectToTarget:withSelector:withObject:
	@abstract Pass contents to an object.
	@discussion <tt>sendEveryObjectToTarget:withSelector:withObject:</tt> passes every object within the reciever and the object <tt>object</tt> to the object <tt>target</tt> one at a time through the selector <tt>selector</tt>. The returned value of the selector <tt>selector</tt> is ignored.
	@param target The object each object in the reciever is sent to.
	@param selector The selector for the message sent to <tt>target</tt>
	@param object The object passed along with every object within the reciever.
 */
- (void)sendEveryObjectToTarget:(id)target withSelector:(SEL)selector withObject:(id)object;

/*!
	@method firstObject
	@abstract Get the first object.
	@discussion Returns the first object of the receiver of nil if the receiver is empty.More descriptive version of <tt>[theArray objectAtIndex:0]</tt>
	@result The object.
 */
- (id)firstObject;

/*!
	@method isEmpty
	@abstract Test if the <tt>NSArray</tt> is empty.
	@discussion Returns <tt>YES</tt> if the receiver is empty. More descriptive version of <tt>[theArray count]==0</tt>
	@result Returns <tt>YES</tt> if empty.
 */
- (BOOL)isEmpty;


@end

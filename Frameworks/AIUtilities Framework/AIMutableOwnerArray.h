/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2005, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

#define Highest_Priority  	0.0
#define High_Priority  		0.25
#define Medium_Priority  	0.5
#define Low_Priority  		0.75
#define Lowest_Priority  	1.0

@class AIMutableOwnerArray;

//Delegate protocol for documentation purposes; it is not necessasry to declare conformance to this protocol.
@protocol AIMutableOwnerArrayDelegate
- (void)mutableOwnerArray:(AIMutableOwnerArray *)inArray didSetObject:(id)anObject withOwner:(id)inOwner priorityLevel:(float)priority;
@end

/*!
 *	@class AIMutableOwnerArray
 * @brief An container object that keeps track of who owns each of its objects.
 *
 * <p>Every object in the <tt>AIMutableOwnerArray</tt> has an associated owner.  The best use for this class is when multiple pieces of code may be trying to control the same thing.  For instance, if there are several events that can cause something to change colors, by using an owner-array it is possible to prevent conflicts and determine an average color based on all the values.  It's also easy for a specific owner to remove the value they contributed, or replace it with another.</p>
 * <p>An owner can only own one object in a given <tt>AIMutableOwnerArray</tt>.  
 * <p>Floating point priority levels can be used to dictate the ordering of objects in the array.  Lower numbers have higher priority.</p>
 */
@interface AIMutableOwnerArray : NSObject {
    NSMutableArray	*contentArray;
    NSMutableArray	*ownerArray;
    NSMutableArray	*priorityArray;
	
	BOOL			valueIsSortedToFront;
	
	id				delegate;
}

//Value Storage
/*!
 * @brief Store an object with an owner at default priority
 *
 *	Calls <tt>setObject:withOwner:priorityLevel:</tt>  with a priorityLevel of Medium_Priority
  */
- (void)setObject:(id)anObject withOwner:(id)inOwner;

/*!
 * @brief Store an object with an owner and a priority
 *
 *	<p>Stores an object in the array with a specified owner at a given priority</p>
 *	@param anObject An object to store
 *	@param inOwner The owner of the object
 *  @param priority <p>priority is a float from 0.0 to 1.0, with 0.0 the highest-priority (earliest in the array). Possible preset values are:<br>
 *			- Highest_Priority<br>
 *			- High_Priority<br>
 *			- Medium_Priority<br>
 *			- Low_Priority<br>
 *			- Lowest_Priority<br>
 */
- (void)setObject:(id)anObject withOwner:(id)inOwner priorityLevel:(float)priority;

//Value Retrieval
/*!
 * @brief Greatest <tt>NSNumber</tt> value
 *
 * Assuming the <tt>AIMutableOwnerArray</tt> contains NSNumber instances, returns the greatest (highest-valued) one.
 * @return  Returns the greatest contained <tt>NSNumber</tt> value.
 */
- (NSNumber *)numberValue;

/*!
 * @brief Highest priority object
 *
 * Returns the object with the highest priority, performing no other comparison.
 * @return Returns the object with the highest priority
 */
- (id)objectValue;

/*!
 * @brief Greatest integer value
 *
 * Assuming the <tt>AIMutableOwnerArray</tt> contains <tt>NSNumber</tt> instances, returns the intValue of the greatest (highest-valued) one.
 * @return  Returns the greatest contained integer value.
 */
- (int)intValue;

/*!
 * @brief Greatest double value
 *
 * Assuming the <tt>AIMutableOwnerArray</tt> contains <tt>NSNumber</tt> instances, returns the doubleValue of the greatest (highest-valued) one.
 * @return  Returns the greatest contained double value.
 */
- (double)doubleValue;

/*!
 * @brief Earliest date
 *
 * Assuming the <tt>AIMutableOwnerArray</tt> contains <tt>NSDate</tt> instances, returns the earliest one.
 * @return  Returns the earliest contained date.
 */
- (NSDate *)date;

/*!
 * @brief Retrieve object by owner
 *
 * Retrieve the object within the <tt>AIMutableOwnerArray</tt> owned by the specified owner.
 * @param inOwner An owner
 * @return  Returns the object owned by <i>inOwner</i>.
 */
- (id)objectWithOwner:(id)inOwner;

/*!
 * @brief Retrieve owner by object
 *
 * Retrieve the owner within the <tt>AIMutableOwnerArray</tt> which owns the specified object.  If multiple owners own a single object, returns the one with the highest priority.
 * @param anObject An object
 * @return  Returns the owner which owns <i>anObject</i>.
 */
- (id)ownerWithObject:(id)anObject;

/*!
 * @brief Retrieve priority by owner
 *
 * Retrieve the priority of the object within the <tt>AIMutableOwnerArray</tt> owned by the specified owner.
 * @param inOwner An owner
 * @return  Returns the priority of the object owned by <i>inOwner</i>.
 */
- (float)priorityOfObjectWithOwner:(id)inOwner;

/*!
 * @brief Retrive enumerator for objects
 * 
 * Retrieve an <tt>NSEnumerator</tt> for all objects in the <tt>AIMutableOwnerArray</tt>. Order is not guaranteed.
 * @return  Returns <tt>NSEnumerator</tt> for all objects.
 */
- (NSEnumerator *)objectEnumerator;

/*!
 * @brief Retrieve array of values
 * 
 * Retrieve an <tt>NSArray</tt> for all objects in the <tt>AIMutableOwnerArray</tt>. Order is not guaranteed.
 * @return  Returns <tt>NSArray</tt> for all objects.
 */
- (NSArray *)allValues;

/*!
 * @brief Retrieve number of objects
 * 
 * Retrieve the number of objects in the <tt>AIMutableOwnerArray</tt>.
 * @return  Returns an unsigned of the number of objects.
 */
- (unsigned)count;

//Delegation
/*!
 * @brief Set the delegate
 * 
 * The delegate may implement:<br>
 * <tt>- (void)mutableOwnerArray:(AIMutableOwnerArray *)inArray didSetObject:(id)anObject withOwner:(id)inOwner priorityLevel:(float)priority</tt><br>
 * to be notified with the AIMutableOwnerArray is modified.
 * @param inDelegate The delegate
 */
- (void)setDelegate:(id)inDelegate;

/*!
 * @brief Retrieve the delegate.
 *
 * Retrieve the delegate.
 * @return Returns the delegate.
 */
- (id)delegate;

@end

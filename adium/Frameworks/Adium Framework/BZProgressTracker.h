#import <Foundation/Foundation.h>
#import <time.h>

enum ProgressState {
	ProgressState_Stopped,
	ProgressState_Starting,
	ProgressState_Stalled,
	ProgressState_Paused,
	ProgressState_Working,
	ProgressState_Stopping,
	ProgressState_Finished
};

@protocol BZProgressTracker <NSObject>

- (NSString *)name;
- (NSString *)type;
//future expansion:
//- (NSImage *)icon;

- (float)maximum;
- (float)current;
- (float)speed;
- (NSString *)unit; //e.g. @"MB" for a download
//maybe we should have different units for the three numbers.

- (BOOL)cancel;
- (BOOL)canCancel;
- (BOOL)pause;
- (BOOL)canPause;
- (BOOL)resume;
- (BOOL)canResume;
- (BOOL)start;
- (BOOL)canStart;
- (BOOL)reveal;
- (BOOL)canReveal;
- (BOOL)prepareForDelete;
- (BOOL)canDelete;

- (enum ProgressState)progressState;

@end

/*  BZProgressTracker class; BZProgressTrackerDelegate protocol
 *  
 *  these allow you to use a delegate system to track the progress of an
 *  activity (e.g. an ESFileTransfer instance).
 *  
 *  create an instance of BZProgressTracker with [[BZProgressTracker alloc]
 *  initWithActivity:self name: type:. install the instance as your delegate.
 *  call its stateChanged::::: method (see the BZProgressTrackerDelegate
 *  protocol) after installation, and when anything happens.
 */

@protocol BZProgressTrackerDelegate

- (void)stateChanged:(enum ProgressState)newState current:(float)newCurrent maximum:(float)newMaximum unit:(NSString *)newUnit icon:(NSImage *)newIcon;

@end

@class BZActivityWindowController;

@interface BZProgressTracker: NSObject <BZProgressTrackerDelegate, BZProgressTracker>
{
	id activity;
	NSString *name, *type;
	BZActivityWindowController *activityWindowController;

	float current, maximum;
	NSString *unit;
	NSImage *icon;
	enum ProgressState progressState;

	float lastCurrent;
	clock_t lastTime; //last time the progress changed.
}

- (id)initWithActivity:(id)activity name:(NSString *)name type:(NSString *)type activityWindowController:(BZActivityWindowController *)awc;

//delegate conformance.
- (void)stateChanged:(enum ProgressState)newState current:(float)newCurrent maximum:(float)newMaximum unit:(NSString *)newUnit icon:(NSImage *)newIcon;

//tracker conformance.
- (NSString *)name;
- (NSString *)type;
- (NSImage *)icon;

- (float)maximum;
- (float)current;
- (float)speed;
- (NSString *)unit;
- (enum ProgressState)progressState;

//all activities (objects using a BZProgressTracker as a delegate) should
//  implement some subset of these methods.
//also, if you implement the foo method but not the canFoo method,
//  BZProgressTracker acts as though you have a canFoo method which returned YES.
- (BOOL)cancel;
- (BOOL)canCancel;
- (BOOL)pause;
- (BOOL)canPause;
- (BOOL)resume;
- (BOOL)canResume;
- (BOOL)start;
- (BOOL)canStart;
- (BOOL)reveal;
- (BOOL)canReveal;
/* some notes on the delete methods:
 *  (1) unlike cancel, pause, resume, start, and reveal, the delete method is
 *      named 'prepareForDelete' (because it does not actually delete the
 *      tracker or its activity; the progress view does that).
 *  (2) make sure your activity releases the delegate when its -prepareForDelete
 *      is called. BZProgressTracker expects this.
 *  (3) even though BZProgressTracker's delete methods are implemented in an
 *      absence-tolerant fashion, every activity should implement
 *      -prepareForDelete (as described above).
 */
- (BOOL)prepareForDelete;
- (BOOL)canDelete;

@end

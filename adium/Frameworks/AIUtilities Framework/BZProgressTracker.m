#import <BZProgressTracker.h>

@implementation BZProgressTracker

- (id)initWithActivity:(id)newActivity name:(NSString *)newName type:(NSString *)newType activityWindowController:(BZActivityWindowController *)awc
{
	activity = [newActivity retain]; name = [newName retain]; type = [newType retain];
	activityWindowController = [awc retain];
	[super init];
}

//delegate conformance.
- (void)stateChanged:(enum ProgressState)newState current:(float)newCurrent maximum:(float)newMaximum unit:(NSString *)newUnit icon:(NSImage *)newIcon
{
	float temp = current;

	//copy args to instance vars. Boring stuph.
	progressState = newState;
	current = newCurrent;
	maximum = newMaximum;
	if(unit != newUnit) {
		[unit release];
		unit = [newUnit retain];
	}
	if(icon != newIcon) {
		[icon release];
		icon = [newIcon retain];
	}

	//this is safe if we're already added, and it updates us implicitly.
	[activityWindowController addProgressTracker:self];

	lastTime = clock();
	lastCurrent = temp;
}

//tracker conformance.
- (NSString *)name
{
	return name;
}
- (NSString *)type
{
	return type;
}
- (NSImage *)icon
{
	return icon;
}

- (float)maximum
{
	return maximum;
}
- (float)current
{
	return current;
}
- (float)speed
{
	return (current - lastCurrent) / ((((float)clock()) - lastTime) / CLOCKS_PER_SEC);
	/*expanded version:
	 *	float time = clock();
	 *	time -= lastTime;
	 *	time /= CLOCKS_PER_SEC;
	 *	return (current - lastCurrent) / time;
	 */
}
- (NSString *)unit
{
	return unit;
}
- (enum ProgressState)progressState
{
	return progressState;
}

- (BOOL)cancel
{
	return [self canCancel] && [activity cancel];
}
- (BOOL)canCancel
{
	if([activity respondsToSelector:@selector(canCancel)]) {
		return [activity canCancel];
	} else {
		[activity respondsToSelector:@selector(cancel)];
	}
}
- (BOOL)pause
{
	return [self canPause] && [activity pause];
}
- (BOOL)canPause
{
	if([activity respondsToSelector:@selector(canPause)]) {
		return [activity canPause];
	} else {
		[activity respondsToSelector:@selector(pause)];
	}
}
- (BOOL)resume
{
	return [self canResume] && [activity resume];
}
- (BOOL)canResume
{
	if([activity respondsToSelector:@selector(canResume)]) {
		return [activity canResume];
	} else {
		[activity respondsToSelector:@selector(resume)];
	}
}
- (BOOL)start
{
	return [self canStart] && [activity start];
}
- (BOOL)canStart
{
	if([activity respondsToSelector:@selector(canStart)]) {
		return [activity canStart];
	} else {
		[activity respondsToSelector:@selector(start)];
	}
}
- (BOOL)reveal
{
	return [self canReveal] && [activity reveal];
}
- (BOOL)canReveal
{
	if([activity respondsToSelector:@selector(canReveal)]) {
		return [activity canReveal];
	} else {
		[activity respondsToSelector:@selector(reveal)];
	}
}
- (BOOL)prepareForDelete
{
	return [self canDelete] && [activity prepareForDelete];
}
- (BOOL)canDelete
{
	if([activity respondsToSelector:@selector(canDelete)]) {
		return [activity canDelete];
	} else {
		[activity respondsToSelector:@selector(prepareForDelete)];
	}
}

@end

#import <Foundation/Foundation.h>

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
- (BOOL)canStart;
- (BOOL)start;
- (BOOL)reveal;
- (BOOL)canReveal;

- (enum ProgressState)progressState;

@end

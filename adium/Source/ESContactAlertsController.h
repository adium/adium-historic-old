//
//  ESContactAlertsController.h
//  Adium XCode
//
//  Created by Evan Schoenberg on Wed Nov 26 2003.

@class AIHandle, AIAccount, AIListGroup, AIListContact;

#define One_Time_Event_Fired 		@"One Time Event Fired"

@interface ESContactAlertsController (INTERNAL) 
- (void)initController;
- (void)closeController;
@end

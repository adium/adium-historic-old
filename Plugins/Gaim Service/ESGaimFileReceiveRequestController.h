//
//  ESGaimFileReceiveRequestController.h
//  Adium
//
//  Created by Evan Schoenberg on 9/22/05.
//

#import <Cocoa/Cocoa.h>

@class AIWindowController;

@interface ESGaimFileReceiveRequestController : NSObject {
	AIWindowController	*requestController;
}

+ (ESGaimFileReceiveRequestController *)showFileReceiveWindowWithDict:(NSDictionary *)inDict;

@end

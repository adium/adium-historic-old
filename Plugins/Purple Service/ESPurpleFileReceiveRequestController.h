//
//  ESPurpleFileReceiveRequestController.h
//  Adium
//
//  Created by Evan Schoenberg on 9/22/05.
//

#import <Cocoa/Cocoa.h>

@class AIWindowController;

@interface ESPurpleFileReceiveRequestController : NSObject {
}

+ (ESPurpleFileReceiveRequestController *)showFileReceiveWindowWithDict:(NSDictionary *)inDict;

@end

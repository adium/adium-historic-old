//
//  AIFlexibleLink.h
//  Adium
//
//  Created by Adam Iser on Mon Apr 07 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AIFlexibleLink : NSObject {
    NSString		*url;

    NSRect		trackingRect;
    NSTrackingRectTag	trackingTag;
}

- (id)initWithTrackingRect:(NSRect)inTrackingRect url:(NSString *)inURL;
- (NSRect)trackingRect;
- (void)setTrackingTag:(NSTrackingRectTag)inTrackingTag;
- (NSTrackingRectTag)trackingTag;
- (NSString *)url;
@end


//
//  ESUserIconHandlingPlugin.m
//  Adium XCode
//
//  Created by Evan Schoenberg on Fri Feb 20 2004.
//

#import "ESUserIconHandlingPlugin.h"

@implementation ESUserIconHandlingPlugin

- (void)installPlugin
{
    [[adium contactController] registerListObjectObserver:self];
}

- (void)uninstallPlugin
{
    [[adium contactController] unregisterListObjectObserver:self];
}

- (NSArray *)updateListObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys silent:(BOOL)silent
{    
    if(inModifiedKeys == nil ||
	   [inModifiedKeys containsObject:@"UserIcon"]){
		
		//		if([inObject isKindOfClass:[AIListContact class]]){
		NSImage *image = [inObject statusObjectForKey:@"UserIcon"];
		
		//Apply the image at medium priority
		[[inObject displayArrayForKey:@"UserIcon"] setObject:image 
												   withOwner:self
											   priorityLevel:Medium_Priority];
		//Notify
		[[adium contactController] listObjectAttributesChanged:inObject
												  modifiedKeys:[NSArray arrayWithObject:@"UserIcon"]];
		//		}
	}
	
	return(nil);
}


@end

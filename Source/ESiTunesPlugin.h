//
//  ESiTunesPlugin.h
//  Adium
//
//  Created by Evan Schoenberg on 6/11/05.

#import <Adium/AIPlugin.h>

@protocol AIContentFilter;

@interface ESiTunesPlugin : AIPlugin <AIContentFilter> {
	NSDictionary	*iTunesCurrentInfo;
}

@end

//
//  SUSpeaker.h
//
//  Created by raf on Sun Jan 28 2001.
//  Based on SpeechUtilities framework by Raphael Sebbe.
//  Revised by Evan Schoenberg on Tue Sep 30 2003.
//  Optimized and expanded by Evan Schoenberg.

#import <Foundation/Foundation.h>
#import <Carbon/Carbon.h>

@interface SUSpeaker : NSObject 
{
    SpeechChannel _speechChannel;
    id _delegate;
    NSPort *_port;
    
    BOOL _usePort;
    unsigned int _reserved1;
    unsigned int _reserved2;
}

+(NSArray*) voiceNames;
//+(NSString*) defaultVoiceName;
-(void) setPitch:(float)pitch;
-(void) setRate:(int)rate;
-(void) setVoice:(int)index;
-(void) speakText:(NSString*)text;
-(void) stopSpeaking;
-(void) resetToDefaults;
-(int) pitch;
-(int) rate;

-(void) setDelegate:(id)delegate;
-(id) delegate;

@end


@interface NSObject (SUSpeakerDelegate)
-(void) didFinishSpeaking:(SUSpeaker*)speaker;
-(void) willSpeakWord:(SUSpeaker*)speaker at:(int)where length:(int)length;
@end
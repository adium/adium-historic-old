//
//  SUSpeaker.m
//
//  Created by raf on Sun Jan 28 2001.
//  Based on SpeechUtilities framework by Raphael Sebbe.
//  Revised by Evan Schoenberg on Tue Sep 30 2003.
//  Optimized and expanded by Evan Schoenberg.
//  $Id: SUSpeaker.m,v 1.7 2004/03/10 22:49:34 evands Exp $


#import "SUSpeaker.h"
#include <unistd.h>
#include <pthread.h>

void MySpeechDoneCallback(SpeechChannel chan,SInt32 refCon);
void MySpeechWordCallback (SpeechChannel chan, SInt32 refCon, UInt32 wordPos, 
    UInt16 wordLen);

@interface SUSpeaker (Private)
-(void)setCallbacks;
-(NSPort*) port;
-(void)setReserved1:(unsigned int)r;
-(void)setReserved2:(unsigned int)r;
-(BOOL) usesPort;
-(void)handleMessage:(unsigned)msgid;
@end

@implementation SUSpeaker

-init
{
    NSRunLoop *loop = [NSRunLoop currentRunLoop];
    [super init];

    // we have 2 options here : we use a port or we don't.
    // using a port means delegate message are invoked from the main 
    // thread (runloop in which this object is created), otherwise, those message 
    // are asynchronous.
    if(loop != nil) {
        _port = [[NSPort port] retain];
        // we use a port so that the speech manager callbacks can talk to the main thread.
        // That way, we can safely access interface elements from the delegate methods
        
        [_port setDelegate:self];
        [loop addPort:_port forMode:NSDefaultRunLoopMode];
        _usePort = YES;
    }
    else _usePort = NO;
    
    NewSpeechChannel(NULL, &_speechChannel); // NULL voice is default voice
    [self setCallbacks];
    return self;
}
-(void)dealloc
{

    [_port release];
    if(_speechChannel != NULL) {
        DisposeSpeechChannel(_speechChannel);
    }
    
    [super dealloc];
}

-(void)resetToDefaults
{
    if(_speechChannel != NULL) {
        StopSpeech(_speechChannel);
        SetSpeechInfo(_speechChannel, soReset, NULL);
    }
}

//---Pitch
/* "Sets the pitch. Pitch is given in Hertz and should be comprised between 80 and 500, depending on the voice.
Note that extreme value can make your app crash..." */
-(void)setPitch:(float)pitch
{
    int fixedPitch;
    
    pitch = (pitch-90.0)/(300.0-90.0)*(65.0 - 30.0) + 30.0;  //conversion from hertz
    /* I don't know what Apple means with pitch between 30 and 65, so I convert that range to [90, 300].
		I did not test frequencies correspond, though. */
    
    fixedPitch = (int)pitch;
    
    fixedPitch = fixedPitch << 16; // fixed point
    
    if(_speechChannel != NULL) {
        SetSpeechPitch (_speechChannel, fixedPitch);
    }
}
//float vs. int?
-(int)pitch
{
    int fixedPitch;
    
    fixedPitch = fixedPitch << 16; // fixed point
    
    GetSpeechInfo(_speechChannel, soPitchBase, &fixedPitch);
    
    fixedPitch = fixedPitch >> 16; // fixed point to int (float?)
    
    fixedPitch = (fixedPitch - 30.0)*(210.0/35.0) + 90.0; //perform needed conversion to reasonable numbers
     
    return ( fixedPitch );
}

//---Rate
//normal is 150 to 220
-(void)setRate:(int)rate
{
    int fixedRate;
    fixedRate = (int)rate;

    fixedRate = fixedRate << 16; // fixed point
    
    if(_speechChannel != NULL) {
    SetSpeechRate(_speechChannel, fixedRate);
    }
}
//float vs. int?
-(int)rate
{
    int fixedRate;
    
    fixedRate = fixedRate << 16; // fixed point
    
    GetSpeechInfo(_speechChannel, soRate, &fixedRate);
    
    fixedRate = fixedRate >> 16; // fixed point to int (float?)
    return ( fixedRate );
}

//---Voice
//set index=-1 for default voice
-(void)setVoice:(int)index
{
    VoiceSpec voice;
    OSErr error = noErr;
    
    if (index>=0)
    {
        error = GetIndVoice(index+1, &voice);
        if(error == noErr) {
            SetSpeechInfo(_speechChannel, soCurrentVoice, &voice);
        }
    }
}
/*"Returns the voice names in the same order as expected by setVoice:."*/
+(NSArray*)voiceNames
{
    NSMutableArray *voices = [NSMutableArray arrayWithCapacity:0];
    short voiceCount;
    OSErr error = noErr;
    int voiceIndex;
    
    error = CountVoices(&voiceCount);
    
    if(error != noErr) return voices;
    
    for(voiceIndex=0; voiceIndex<voiceCount; voiceIndex++)
    {
        VoiceSpec	voiceSpec;
        VoiceDescription voiceDescription;
        
        error = GetIndVoice(voiceIndex+1, &voiceSpec);
        if(error != noErr) return voices;
        error = GetVoiceDescription( &voiceSpec, &voiceDescription, sizeof(voiceDescription));
        if(error == noErr)
        {
            NSString *voiceName = [[[NSString alloc] initWithUTF8String:&(voiceDescription.name[1])] autorelease];
            
            [voices addObject:voiceName];
        }
        else return voices;
    }
    return voices;
}
/*
+(NSString*)defaultVoiceName
{
    NSString *voiceName;
    VoiceSpec	voiceSpec;
    VoiceDescription voiceDescription;
    
    GetIndVoice(NULL, &voiceSpec);
    GetVoiceDescription( &voiceSpec, &voiceDescription, sizeof(voiceDescription));
    voiceName = [[NSString alloc] initWithUTF8String:&(voiceDescription.name[1]) length:voiceDescription.name[0]];
    return voiceName;
}*/


//setVolume: SetSpeechInfo(_speechChannel, soCurrentVoice, ????);

//---Speech
-(void)speakText:(NSString*)text
{
    if(_speechChannel != NULL && text != nil) {
	/*FUNCTION SpeakText (chan: SpeechChannel; textBuf: Ptr;
textBytes: LongInt): OSErr;*/
	SpeakText(_speechChannel, [text UTF8String], [text length]);
    }
}
-(void)stopSpeaking
{
    if(_speechChannel != NULL) {
        StopSpeech(_speechChannel);
        if([_delegate respondsToSelector:@selector(didFinishSpeaking:)]) {
            [_delegate didFinishSpeaking:self];
        }
    }
}

//---Delegate
-(void)setDelegate:(id)delegate
{
    _delegate = delegate;
}
-(id) delegate
{
    return _delegate;
}


//--- Private ---
-(void)setCallbacks
{
    if(_speechChannel != NULL) {
        SetSpeechInfo(_speechChannel, soSpeechDoneCallBack, &MySpeechDoneCallback);
        SetSpeechInfo(_speechChannel, soWordCallBack, &MySpeechWordCallback);
        SetSpeechInfo(_speechChannel, soRefCon, (const void*)self);
    }
}
-(void)setReserved1:(unsigned int)r
{
    _reserved1 = r;
}
-(void)setReserved2:(unsigned int)r
{
    _reserved2 = r;
}
-(NSPort*) port
{
    return _port;
}
-(BOOL) usesPort
{
    return _usePort;
}
-(void)handleMessage:(unsigned)msgid
{
    if(msgid == 5) {
        if([_delegate respondsToSelector:@selector(willSpeakWord:at:length:)]) {
            if(_reserved1 >= 0 && _reserved2 >= 0)
                [_delegate willSpeakWord:self at:_reserved1 length:_reserved2];
            else
                [_delegate willSpeakWord:self at:0 length:0];
        }
    } else if(msgid == 8) {
        if([_delegate respondsToSelector:@selector(didFinishSpeaking:)]) {
            [_delegate didFinishSpeaking:self];
        }
    }
}
//--- NSPort delegate ---
- (void)handlePortMessage:(NSPortMessage *)portMessage
{
    int msg = [portMessage msgid];
    
    [self handleMessage:msg];
}

@end

void MySpeechDoneCallback(SpeechChannel chan,SInt32 refCon)
{
    SUSpeaker *speaker = (SUSpeaker*)refCon;
    unsigned msg = 8;
    
    if([speaker isKindOfClass:[SUSpeaker class]]) {
        if([speaker usesPort]) {
            NSPortMessage *message = [[NSPortMessage alloc] initWithSendPort:[speaker port]
                receivePort:[speaker port] components:nil];
        
            [message setMsgid:msg];
            [message sendBeforeDate:nil];
            [message release];
        } else {
            // short-circuit port
            [speaker handleMessage:msg];
        }
    } 
}
void MySpeechWordCallback(SpeechChannel chan, SInt32 refCon, UInt32 wordPos,UInt16 wordLen)
{
    SUSpeaker *speaker = (SUSpeaker*)refCon;
    unsigned msg = 5;

    if([speaker isKindOfClass:[SUSpeaker class]]) {
        [speaker setReserved1:wordPos];
        [speaker setReserved2:wordLen];
        
        if([speaker usesPort]) {
            NSPortMessage *message = [[NSPortMessage alloc] initWithSendPort:[speaker port]
                receivePort:[speaker port] components:nil];
        
            [message setMsgid:msg];
            [message sendBeforeDate:nil];
            [message release];
        } else {
            // short-circuit port
            [speaker handleMessage:msg];
        }
    } 
}

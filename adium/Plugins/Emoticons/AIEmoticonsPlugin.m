/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2003, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
| This program is free software; you can redistribute it and/or modify it under the terms of the GNU
| General Public License as published by the Free Software Foundation; either version 2 of the License,
| or (at your option) any later version.
|
| This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
| the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
| Public License for more details.
|
| You should have received a copy of the GNU General Public License along with this program; if not,
| write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
\------------------------------------------------------------------------------------------------------ */

#import "AIEmoticonsPlugin.h"
#import "AIEmoticon.h"
#import "AIAdium.h"
#import <AIUtilities/AIUtilities.h>

#define EMOTICON_DEFAULT_PREFS	@"EmoticonDefaults"
#define PATH_EMOTICONS		@"/Emoticons"

@interface AIEmoticonsPlugin (PRIVATE)
- (void)filterContentObject:(AIContentObject *)inObject;
- (NSMutableAttributedString *)convertSmiliesInMessage:(NSAttributedString *)inMessage;
- (void)setupForTesting;
- (void)updateQuickScanList;
@end

@implementation AIEmoticonsPlugin

- (void)installPlugin
{
    //init
    quickScanList = [[NSMutableArray alloc] init];
    emoticons = [[NSMutableArray alloc] init];

    replaceEmoticons = YES;
    [self setupForTesting];

    [self updateQuickScanList];

    //Register our content filter
    [[owner contentController] registerDisplayingContentFilter:self];
    //[[owner contentController] registerIncomingContentFilter:self];
}

- (void)filterContentObject:(AIContentObject *)inObject
{
    if(replaceEmoticons){
	if([[inObject type] compare:CONTENT_MESSAGE_TYPE] == 0){
	    BOOL			mayContainEmoticons = NO;
	    AIContentMessage		*contentMessage = (AIContentMessage *)inObject;
	    NSString			*messageString = [[contentMessage message] string];
	    NSMutableAttributedString	*replacementMessage = nil;

	    NSEnumerator		*enumerator = [quickScanList objectEnumerator];
	    NSString 			*currentChar = nil;

	    //First, we do a quick scan of the message for any substrings that might end up being emoticons
	    //This avoids having to do the slower, more complicated scan for the majority of messages.
	    while(currentChar = [enumerator nextObject]){
		if([messageString rangeOfString:currentChar].location != NSNotFound){
		    mayContainEmoticons = YES;
		    break;
		}
	    }

	    if (mayContainEmoticons){
		replacementMessage = [self convertSmiliesInMessage:[contentMessage message]];

		if(replacementMessage){
		    [contentMessage setMessage:replacementMessage];
		}
	    }
	}
    }
}

//most of this is ripped right from 1.x, YAY!
- (NSMutableAttributedString *)convertSmiliesInMessage:(NSAttributedString *)inMessage
{

    NSRange 		emoticonRange;
    NSRange		attributeRange;
    int			currentLocation = 0;

    NSEnumerator	*emoEnumerator = [emoticons objectEnumerator];
    NSEnumerator	*textEnumerator = nil;
    AIEmoticon		*currentEmo = nil;
    NSString		*currentEmoText = nil;

    NSMutableAttributedString	*tempMessage = [inMessage mutableCopy];
    BOOL			messageChanged = NO;

    while(currentEmo = [emoEnumerator nextObject]){
	textEnumerator = [currentEmo representedTextEnumerator];

	while(currentEmoText = [textEnumerator nextObject]){

	    //start at the beginning of the string
	    currentLocation = 0;

	    //--find emoticon--
	    emoticonRange = [[tempMessage string] rangeOfString:currentEmoText options:0 range:NSMakeRange(currentLocation,[tempMessage length] - currentLocation)];

	    while(emoticonRange.length != 0){ //if we found a emoticon
				       //--make sure this emoticon's not inside a link--
		if([tempMessage attribute:NSLinkAttributeName atIndex:emoticonRange.location effectiveRange:&attributeRange] == nil){

		    NSMutableAttributedString *replacement = [[currentEmo attributedEmoticon] mutableCopy];

		    [replacement addAttributes:[tempMessage attributesAtIndex:emoticonRange.location effectiveRange:nil] range:NSMakeRange(0,1)];

		    //--insert the emoticon--
		    [tempMessage replaceCharactersInRange:emoticonRange withAttributedString:[replacement copy]];

		    //shrink the emoticon range to 1 character (the multicharacter chunk has been replaced with a single character/emoticon)
		    emoticonRange.length = 1;

		    messageChanged = YES;
		}

		//--move our location--
		currentLocation = emoticonRange.location + emoticonRange.length;

		//--find the next emoticon--
		emoticonRange = [[tempMessage string] rangeOfString:currentEmoText options:0 range:NSMakeRange(currentLocation,[[tempMessage string] length] - currentLocation)];
	    }
        }
    }

    if(!messageChanged){
	tempMessage = nil;
    }

    return tempMessage;
}

- (void)updateQuickScanList
{
    int			loop = 0;
    NSEnumerator	*emoEnumerator = [emoticons objectEnumerator];
    NSEnumerator	*textEnumerator = nil;
    AIEmoticon		*currentEmo = nil;
    NSString		*currentEmoText = nil;
    NSString		*currentChar = nil;

    while(currentEmo = [emoEnumerator nextObject]){
	textEnumerator = [currentEmo representedTextEnumerator];

	while(currentEmoText = [textEnumerator nextObject]){
	    for(loop = 0; loop < [currentEmoText length]; loop++){
		currentChar = [NSString stringWithFormat:@"%C",[currentEmoText characterAtIndex:loop]];

		if(![quickScanList containsObject:currentChar]){
		    [quickScanList addObject:currentChar];
		}
	    }
	}
    }
}

- (void)setupForTesting
{
    AIEmoticon	*emo = nil;
    NSString	*defaultPath = [[[NSBundle bundleForClass:[self class]] bundlePath] stringByAppendingFormat:@"/Contents/Resources%@",PATH_EMOTICONS];

    emo = [[AIEmoticon alloc] initWithPath:[defaultPath stringByAppendingString:@"/Smiley00.png"] andText:@"O:-),O:),O=),o:-),o:),o=)"];
    [emoticons addObject:emo];

    emo = [[AIEmoticon alloc] initWithPath:[defaultPath stringByAppendingString:@"/Smiley01.png"] andText:@":-),:),=),:o)"];
    [emoticons addObject:emo];

    emo = [[AIEmoticon alloc] initWithPath:[defaultPath stringByAppendingString:@"/Smiley02.png"] andText:@":-(,:(,=(("];
    [emoticons addObject:emo];

    emo = [[AIEmoticon alloc] initWithPath:[defaultPath stringByAppendingString:@"/Smiley03.png"] andText:@";-),;)"];
    [emoticons addObject:emo];

    emo = [[AIEmoticon alloc] initWithPath:[defaultPath stringByAppendingString:@"/Smiley04.png"] andText:@":-P,:P,=P,:-p,:p,=p"];
    [emoticons addObject:emo];

    emo = [[AIEmoticon alloc] initWithPath:[defaultPath stringByAppendingString:@"/Smiley07.png"] andText:@">:o,>=o"];
    [emoticons addObject:emo];

    emo = [[AIEmoticon alloc] initWithPath:[defaultPath stringByAppendingString:@"/Smiley05.png"] andText:@"=-o,=-O,:-o,:o,=o"];
    [emoticons addObject:emo];

    emo = [[AIEmoticon alloc] initWithPath:[defaultPath stringByAppendingString:@"/Smiley06.png"] andText:@":-*,:*,=*"];
    [emoticons addObject:emo];

    emo = [[AIEmoticon alloc] initWithPath:[defaultPath stringByAppendingString:@"/Smiley08.png"] andText:@":-D,:D,=D"];
    [emoticons addObject:emo];

    emo = [[AIEmoticon alloc] initWithPath:[defaultPath stringByAppendingString:@"/Smiley09.png"] andText:@":-$,:$"];
    [emoticons addObject:emo];

    emo = [[AIEmoticon alloc] initWithPath:[defaultPath stringByAppendingString:@"/Smiley10.png"] andText:@":-!,:!"];
    [emoticons addObject:emo];

    emo = [[AIEmoticon alloc] initWithPath:[defaultPath stringByAppendingString:@"/Smiley11.png"] andText:@":-[,:[,=["];
    [emoticons addObject:emo];

    emo = [[AIEmoticon alloc] initWithPath:[defaultPath stringByAppendingString:@"/Smiley12.png"] andText:@":-\\,:\\,=\\,:-/,=/,:/"];
    [emoticons addObject:emo];

    emo = [[AIEmoticon alloc] initWithPath:[defaultPath stringByAppendingString:@"/Smiley13.png"] andText:@":'(,='("];
    [emoticons addObject:emo];

    emo = [[AIEmoticon alloc] initWithPath:[defaultPath stringByAppendingString:@"/Smiley14.png"] andText:@":-x,:x,=x,:-X,:X,=X"];
    [emoticons addObject:emo];

    emo = [[AIEmoticon alloc] initWithPath:[defaultPath stringByAppendingString:@"/Smiley15.png"] andText:@"8-),8)"];
    [emoticons addObject:emo];
}

@end

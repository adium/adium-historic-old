//
//  AIMXLaTeXPlugin.m
//  Adium
//
//  Created by Max Cantor on Wed Jun 18 2003.
//  Copyright (c) 2003 mxcantor technologies. All rights reserved.
//
/* | This program is free software; you can redistribute it and/or modify it under the terms of the GNU
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
#import "MXLaTeXPlugin.h"


@implementation MXLaTeXPlugin


- (void)installPlugin
{
    //I have disabled the LaTeX plugin for now, please update it.
    /*
     - Update to use the new AITextAttachmentExtensions to correct logging, and stop assertions.
     - Update as a Displaying Content Filter
     - Do a quick check for $$ in the messages before running through the bigger calculations
     - Don't launch the latex helper app until a latex message needs filtering
     * Fix the pasteboard related stack overflow crash on quit this plugin is causing.  To reproduce, simply send a message to yourself and then quit Adium with Cmd-Q.
     */

/*    [[owner notificationCenter] addObserver:self selector:@selector(latexifyIncomingString:) name:Content_WillReceiveContent object:nil];
    [[owner notificationCenter] addObserver:self selector:@selector(latexifyOutgoingString:) name:Content_WillSendContent object:nil];
    NSPerformService(@"Equation Service/Typeset in main ES window",[NSPasteboard generalPasteboard]);*/
    ////NSLog(@"MXLaTeX: installPlugin");
}
- (void)latexifyIncomingString:(NSNotification *)notification {
    [self latexifyString:notification isIncoming:YES];
}

- (void)latexifyOutgoingString:(NSNotification *)notification {
    [self latexifyString:notification isIncoming:NO];
}
- (void)latexifyString:(NSNotification *)notification isIncoming:(BOOL)isIncoming
{


          

   // id <AIContentObject> contObj = [[notification userInfo] objectForKey:@"Object"];
    AIContentMessage *contMsg;
    NSMutableAttributedString *newAttrStr;
    NSScanner *stringScanner;
    NSString *retStr;
    BOOL success;

    NSTextAttachment *tAttach;
    MXImageTextAttachmentCell *mxCell;
    NSArray *sendTypes, *returnTypes;
    //HACK - get the right constanct for this
    const unichar atchr = 0xfffc;


    //Hm, the def for AIContentObject went away.  but, I should put this check back in
   // if ([[contObj type] compare:CONTENT_MESSAGE_TYPE] != 0) {return;}
    contMsg = (AIContentMessage *)[[notification userInfo] objectForKey:@"Object"];
    newAttrStr = [[NSMutableAttributedString alloc] initWithAttributedString:
        [contMsg message]];

    sendTypes = [NSArray arrayWithObjects:NSStringPboardType, nil];

    returnTypes = [NSArray arrayWithObjects:NSPDFPboardType, NSStringPboardType, nil];
    //NSData *data;
    NSPasteboard *pb =[NSPasteboard pasteboardWithName:@"latexPboard"];
    [pb declareTypes:returnTypes owner:self];


    int i, removedChars = 0;
    stringScanner = [[NSScanner alloc] initWithString: [newAttrStr string]];
    //NSLog([stringScanner string]);
    while ([stringScanner isAtEnd] == NO) {
        [stringScanner scanUpToString:@"$$" intoString:nil] ;
        if ([stringScanner scanString:@"$$" intoString:nil] && ([stringScanner isAtEnd] == NO)) {
            i = [stringScanner scanLocation];
            [stringScanner scanUpToString:@"$$" intoString:&retStr];
            [stringScanner setScanLocation:([stringScanner scanLocation]+2)];
            [pb declareTypes:returnTypes owner:self];

            [pb setString:retStr forType:NSStringPboardType];
            //NSLog(@"About to perform service");
            success = NSPerformService(@"Equation Service/Typeset Equation",pb);
            //NSLog(@"performed with suc = %d",success);
            if (success) {
                tAttach = [[NSTextAttachment alloc] init];
                //   //NSLog(@"about to just alloc");
                //  mxCell = [MXImageTextAttachmentCell cellWithPasteboard:pb
                //                                            attachment:tAttach
                  //                                                flip:YES];
                //NSLog(@"about to alloc and init");
                mxCell = [[MXImageTextAttachmentCell alloc] initWithPasteboard:pb
                                                                    attachment:tAttach
                                                                          flip:YES];
                [mxCell autorelease];
                /*
                //NSLog(@"about to alloc the cell");
                mxCell = [MXImageTextAttachmentCell alloc];
                //NSLog(@"alloced about to init");
                [mxCell initWithPasteboard:pb
                                attachment:tAttach
                                      flip:YES];
*/
                //NSLog(@"about to set the cell");
                [tAttach setAttachmentCell:mxCell];
                //NSLog(@"About to begin editing");
                [newAttrStr beginEditing];
                if (isIncoming) {
                    [newAttrStr replaceCharactersInRange:NSMakeRange(i-2-removedChars, [retStr length]+4)
                                              withString:
                        [NSString stringWithCharacters:&atchr
                                                length:1]];
                    [newAttrStr addAttribute:NSAttachmentAttributeName
                                       value:tAttach
                                       range:NSMakeRange(i-2-removedChars,1)];
                    removedChars += [retStr length]+4;
                } else {
                    [newAttrStr replaceCharactersInRange:NSMakeRange(i-2-removedChars,0)
                                              withString:
                        [NSString stringWithCharacters:&atchr
                                                length:1]];
                    [newAttrStr addAttribute:NSAttachmentAttributeName
                                       value:tAttach
                                       range:NSMakeRange(i-2-removedChars,1)];
                    [newAttrStr addAttribute:NSFontAttributeName
                                       value:[NSFont userFontOfSize:0.0001]
                                       range:NSMakeRange(i-1-removedChars,[retStr length]+4)];

                }
                //NSLog(@"about to add attri with  idx=%d, len =%d",i-2-removedChars,1);
                
                [newAttrStr endEditing];
                //the number of characters deleted:
                //;
                //plus one for the the attachment char
                removedChars--;
            }
        }
    }
    [contMsg setMessage:newAttrStr];
    
}

@end

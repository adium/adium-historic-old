//
//  BZGenericViewCell.h
//  Adium
//
//  Created by Mac-arena the Bored Zo on Sun May 09 2004.
//

#import <Foundation/Foundation.h>

//based on sample code at http://www.cocoadev.com/index.pl?NSViewInNSTableView

@interface BZGenericViewCell : NSCell
{
	NSView	*embeddedView;
}

- (void)setEmbeddedView:(NSView *)inView;

@end

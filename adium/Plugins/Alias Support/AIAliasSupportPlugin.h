//
//  AIAliasSupportPlugin.h
//  Adium
//
//  Created by Adam Iser on Tue Dec 31 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Adium/Adium.h>

@interface AIAliasSupportPlugin : AIPlugin {
    IBOutlet    NSView		*view_contactAliasInfoView;

    AIContactInfoViewController		*contactView;
}

@end

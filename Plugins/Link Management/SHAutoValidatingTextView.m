/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "SHAutoValidatingTextView.h"

@implementation SHAutoValidatingTextView

- (id)initWithFrame:(NSRect)frameRect
{
    return([super initWithFrame:frameRect]);
}

- (id)initWithFrame:(NSRect)frameRect textContainer:(NSTextContainer *)aTextContainer
{
    return([super initWithFrame:frameRect textContainer:aTextContainer]);
}

- (void)dealloc
{
    [super dealloc];
}


//Set Validation Attribs -----------------------------------------------------------------------------------------------
#pragma mark Set Validation Attribs
- (void)setContiniousURLValidationEnabled:(BOOL)flag
{
    //set the validation BOOL, and immeditely reevaluate view
    continiousURLValidation = flag;
}

- (void)toggleContiniousURLValidationEnabled
{
    //toggle the validation BOOL, and immeditely re-evaluate view
    continiousURLValidation = !continiousURLValidation;
}

- (BOOL)isContiniousURLValidationEnabled
{
    return(continiousURLValidation);
}


//Get URL Verification Status ------------------------------------------------------------------------------------------
#pragma mark Get URL Verification Status
- (BOOL)isURLValid
{
    return(URLIsValid);
}
- (URI_VERIFICATION_STATUS)validationStatus
{
    return(validStatus);
}


//Evaluate URL ---------------------------------------------------------------------------------------------------------
#pragma mark Evaluate URL
//Catch the notification when the text in the view is edited
- (void)textDidChange:(NSNotification *)notification
{
    if(continiousURLValidation) {//call the URL validatation if set
        SHHyperlinkScanner  *laxScanner = [[SHHyperlinkScanner alloc] initWithStrictChecking:NO];
        
        URLIsValid = [laxScanner isStringValidURL:[[self textStorage] string]];
        validStatus = [laxScanner validationStatus];
		
		[laxScanner release];
    }
}

@end

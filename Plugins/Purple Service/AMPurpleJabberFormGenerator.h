//
//  AMPurpleJabberFormGenerator.h
//  Adium
//
//  Created by Andreas Monitzer on 2007-06-26.
//  Copyright 2007 Andreas Monitzer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include "glib.h"
#include "xmlnode.h"

enum AMPurpleJabberFormType {
	form = 0,
	submit,
	cancel,
	result
};

@interface AMPurpleJabberFormField : NSObject {
	BOOL required;
	NSString *label;
	NSString *var;
	NSString *desc;
}
/* use -init for creating an empty field */
+ (AMPurpleJabberFormField*)fieldForXML:(xmlnode*)xml;

- (void)setRequired:(BOOL)_required;
- (BOOL)required;
- (void)setLabel:(NSString*)_label;
- (NSString*)label;
- (void)setVariable:(NSString*)_var;
- (NSString*)var;
- (void)setDescription:(NSString*)_desc;
- (NSString*)desc;

- (xmlnode*)xml;
@end

@interface AMPurpleJabberFormFieldBoolean : AMPurpleJabberFormField {
	BOOL value;
}

- (void)setBoolValue:(BOOL)_value;
- (BOOL)boolValue;

@end

@interface AMPurpleJabberFormFieldFixed : AMPurpleJabberFormField {
	NSString *value;
}

- (void)setStringValue:(NSString*)_value;
- (NSString*)stringValue;

@end

@interface AMPurpleJabberFormFieldHidden : AMPurpleJabberFormField {
	NSString *value;
}

- (void)setStringValue:(NSString*)_value;
- (NSString*)stringValue;

@end

@interface AMPurpleJabberFormFieldJidMulti : AMPurpleJabberFormField {
	NSArray *jids;
}

- (void)setJIDs:(NSArray*)_jids; // array of NSString*
- (NSArray*)jids;

@end

@interface AMPurpleJabberFormFieldJidSingle : AMPurpleJabberFormField {
	NSString *jid;
}

- (void)setJID:(NSString*)_jid;
- (NSString*)jid;

@end

@interface AMPurpleJabberFormFieldListMulti : AMPurpleJabberFormField {
	NSArray *options; // array of NSDictionary with Keys @"label" and @"value"
	NSArray *values;
}

- (void)setOptions:(NSArray*)_options; // array of NSString*
- (NSArray*)options;
- (void)setStringValues:(NSArray*)_values;
- (NSArray*)stringValues;

@end

@interface AMPurpleJabberFormFieldListSingle : AMPurpleJabberFormField {
	NSArray *options;
	NSString *value;
}

- (void)setOptions:(NSArray*)_options; // array of NSString*
- (NSArray*)options;
- (void)setStringValue:(NSString*)_value;
- (NSString*)stringValue;

@end

@interface AMPurpleJabberFormFieldTextMulti : AMPurpleJabberFormField {
	NSString *value;
}

- (void)setStringValue:(NSString*)_value;
- (NSString*)stringValue;

@end

@interface AMPurpleJabberFormFieldTextPrivate : AMPurpleJabberFormField {
	NSString *value;
}

- (void)setStringValue:(NSString*)_value;
- (NSString*)stringValue;

@end

@interface AMPurpleJabberFormFieldTextSingle : AMPurpleJabberFormField {
	NSString *value;
}

- (void)setStringValue:(NSString*)_value;
- (NSString*)stringValue;

@end

@interface AMPurpleJabberFormGenerator : NSObject {
	NSString *title;
	NSString *instructions;
	enum AMPurpleJabberFormType type;
	
	NSMutableArray *fields;
}

- (id)initWithType:(enum AMPurpleJabberFormType)_type;
- (id)initWithXML:(xmlnode*)xml;

- (void)setTitle:(NSString*)_title;
- (void)setInstructions:(NSString*)_instructions;

- (NSString*)title;
- (NSString*)instructions;
- (enum AMPurpleJabberFormType)type;

- (void)addField:(AMPurpleJabberFormField*)field;
- (void)removeField:(AMPurpleJabberFormField*)field;

- (NSArray*)fields;

- (xmlnode*)xml;

@end

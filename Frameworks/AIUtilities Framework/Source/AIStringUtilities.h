
//Localization
#ifndef AILocalizedString
#	define AILocalizedString(key, comment) NSLocalizedStringFromTableInBundle(key,nil,[NSBundle bundleForClass: [self class]],comment)
#	define AILocalizedStringFromTable(key, table, comment) NSLocalizedStringFromTableInBundle(key,table,[NSBundle bundleForClass: [self class]],comment)
#endif
 
//Static strings
#define DeclareString(var)			static NSString * (var) = nil;
#define InitString(var,string)		if (! (var) ) (var) = [(string) retain];
#define ReleaseString(var)			if ( (var) ) { [(var) release]; (var) = nil; } 

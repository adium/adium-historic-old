//Localization
#ifndef AILocalizedString
#	define AILocalizedString(key, comment) NSLocalizedStringFromTableInBundle(key, nil, [NSBundle bundleForClass:[self class]], comment)
#	define AILocalizedStringFromTable(key, table, comment) NSLocalizedStringFromTableInBundle(key, table, [NSBundle bundleForClass:[self class]], comment)
#endif

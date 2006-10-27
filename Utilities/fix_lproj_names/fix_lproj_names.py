#!/usr/bin/env python

"""Usage: fix_lproj_names [targets]

Converts old-style lproj names (e.g. "English.lproj") to ISO 639-1 names (e.g. "en.lproj").

"targets" are pathnames to directories to recursively search for .lproj directories. If no targets are specified, . is used.

Requires Python 2.3 or later.
"""

# http://developer.apple.com/documentation/MacOSX/Conceptual/BPInternational/Articles/LanguageDesignations.html
# http://loc.gov/standards/iso639-2/php/English_list.php
mappings = {
	'English':	'en',
	'French':	'fr',
	'German':	'de',
	'Italian':	'it',
	'Dutch':	'nl',
	'Swedish':	'sv',
	'Spanish':	'es',
	'Danish':	'da',
	'Portuguese':	'pt',
	'Norwegian':	'nb',
	'Hebrew':	'he',
	'Japanese':	'ja',
	'Arabic':	'ar',
	'Finnish':	'fi',
	'Greek':	'el',
	'Icelandic':	'is',
	'Maltese':	'mt',
	'Turkish':	'tr',
	'Croatian':	'hr',
	'Chinese':	'zh',
	'Urdu': 'ur',
	'Hindi':	'hi',
	'Thai': 'th',
	'Korean':	'ko',
	'Lithuanian':	'lt',
	'Polish':	'pl',
	'Hungarian':	'hu',
	'Estonian':	'et',
	'Latvian':	'lv',
	'Sami': 'se',
	'Faroese':	'fo',
	'Farsi':	'fa',
	'Russian':	'ru',
	'Chinese':	'zh',
	'Dutch':	'nl',
	'Irish':	'ga',
	'Albanian':	'sq',
	'Romanian':	'ro',
	'Czech':	'cs',
	'Slovak':	'sk',
	'Slovenian':	'sl',
	'Yiddish':	'yi',
	'Serbian':	'sr',
	'Macedonian':	'mk',
	'Bulgarian':	'bg',
	'Ukrainian':	'uk',
	'Byelorussian': 'be',
	'Uzbek':	'uz',
	'Kazakh':	'kk',
	'Azerbaijani':	'az',
	'Azerbaijani':	'az',
	'Armenian':	'hy',
	'Georgian':	'ka',
	'Moldavian':	'mo',
	'Kirghiz':	'ky',
	'Tajiki':	'tg',
	'Turkmen':	'tk',
	'Mongolian':	'mn',
	'Mongolian':	'mn',
	'Pashto':	'ps',
	'Kurdish':	'ku',
	'Kashmiri':	'ks',
	'Sindhi':	'sd',
	'Tibetan':	'bo',
	'Nepali':	'ne',
	'Sanskrit':	'sa',
	'Marathi':	'mr',
	'Bengali':	'bn',
	'Assamese':	'as',
	'Gujarati':	'gu',
	'Punjabi':	'pa',
	'Oriya':	'or',
	'Malayalam':	'ml',
	'Kannada':	'kn',
	'Tamil':	'ta',
	'Telugu':	'te',
	'Sinhalese':	'si',
	'Burmese':	'my',
	'Khmer':	'km',
	'Lao':	'lo',
	'Vietnamese':	'vi',
	'Indonesian':	'id',
	'Tagalog':	'tl',
	'Malay':	'ms',
	'Malay':	'ms',
	'Amharic':	'am',
	'Tigrinya':	'ti',
	'Oromo':	'om',
	'Somali':	'so',
	'Swahili':	'sw',
	'Kinyarwanda':	'rw',
	'Rundi':	'rn',
	'Nyanja':	'ny',
	'Malagasy':	'mg',
	'Esperanto':	'eo',
	'Welsh':	'cy',
	'Basque':	'eu',
	'Catalan':	'ca',
	'Latin':	'la',
	'Quechua':	'qu',
	'Guarani':	'gn',
	'Aymara':	'ay',
	'Tatar':	'tt',
	'Uighur':	'ug',
	'Dzongkha':	'dz',
	'Javanese':	'jv',
	'Sundanese':	'su',
	'Galician':	'gl',
	'Afrikaans':	'af',
	'Breton':	'br',
	'Inuktitut':	'iu',
	'Scottish':	'gd',
	'Manx': 'gv',
	'Irish':	'ga',
	'Tongan':	'to',
	'Greek':	'el',
	'Greenlandic':	'kl',
	'Azerbaijani':	'az',
	'Nynorsk':	'nn',
}
# These aren't Adium frameworks, and so they aren't our responsibility.
# Therefore we should not descend into these frameworks if spotted.
# (LMX could be considered an Adium framework by some definitions, but it has no lprojs in it, and therefore is not worth checking.)
exceptions = [
	'FriBidi.framework',
	'Growl-WithInstaller.framework',
	'LMX.framework',
	'OTR.framework',
	'PSMTabBarControl.framework'
	'ShortcutRecorder',
	'Sparkle.framework',
]

#-------------------------------------------------------------------------------

# Ahead of time, append .lproj to all of these.
lproj = '.lproj'
mappings_precached = dict((k + lproj, v + lproj) for k, v in mappings.iteritems())

import optparse
# Use our docstring as the --help.
parser = optparse.OptionParser(help=__doc__.replace('fix_lproj_name', '%prog'))
options, args = parser.parse_args()

if not args:
	args = ['.']

for target in args:
	# Walk each directory.
	# Remove known exceptions from the directories list.
	# For each item in mappings, rename it from (for example) "English.lproj" to "en.lproj".
	# Use svn mv if there is a .svn directory; otherwise, use plain mv.

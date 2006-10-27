#!/usr/bin/env python

"""Usage: fix_lproj_names [targets]

Converts old-style lproj names (e.g. "English.lproj") to ISO 639-1 names (e.g. "en.lproj").

"targets" are pathnames to directories to recursively search for .lproj directories. If no targets are specified, . is used.

Requires Python 2.3 or later.\
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
	'PSMTabBarControl.framework',
	'ShortcutRecorder',
	'Sparkle.framework',
]

#-------------------------------------------------------------------------------

# Things to do ahead of time to the settings above.
# Append .lproj to all of the keys and values in the mappings dict.
lproj = '.lproj'
mappings = dict((k + lproj, v + lproj) for k, v in mappings.iteritems())
# Create a set that we can use for set intersection with the list of lprojs in each subdirectory.
mappings_keys = set(mappings)
# Also convert the exceptions list to a set, so that we can do set differencing upon the dirnames list in the os.walk loop.
exceptions = set(exceptions)

import optparse
# Use our docstring as the --help.
parser = optparse.OptionParser(usage=__doc__.replace('fix_lproj_name', '%prog'))
options, args = parser.parse_args()

if not args:
	args = ['.']

# Get the utilities that we need. We do this up front rather than in the loop for obvious reasons.
import os
from os import path
from sys import stderr # For warning messages.
try:
	from glob import iglob as glob
except ImportError:
	# NO iglob FOR YOU! (You need Python 2.5 or later for that).
	from glob import glob
import fnmatch
dot_lproj_pattern = '*.lproj'
import subprocess

# Plain rename, for renaming in non-versioned directories.
def rename(old_name, new_name):
	old_cwd = os.getcwd()
	os.chdir(dirpath)
	os.rename(old_name, new_name)
	os.chdir(old_cwd)
# svn rename, for renaming in versioned directories.
def svn_rename(old_name, new_name):
	status = subprocess.call(['svn', 'mv', old_name, new_name])
	if status == 1:
		# Assume it's not versioned (dirpath is a WC, but old_name isn't versioned in it). Try plain rename.
		print >>stderr, 'svn mv returned exit status 1 for %r in %r; trying plain rename' % (old_name, dirpath)
		rename(old_name, new_name)

# THE RECURSION LOOP!

for topdir in args:
	for dirpath, dirnames, filenames in os.walk(topdir):
		# See if there's a .svn directory.
		# If there is, we should use svn mv, and we also shouldn't descend into that directory.
		# If there isn't, we should use regular mv, and we don't need to worry about descending into it.
		try:
			i = dirnames.index('.svn')
		except ValueError:
			versioned = False
		else:
			del dirnames[i]
			versioned = True

		# Remove the exceptions from the dirnames array. This not only keeps us from descending into them (which is the idea), but also saves fnmatch.filter some work.
		dirnames_set = set(dirnames)
		dirnames_set.difference_update(exceptions)
		dirnames[:] = dirnames_set

		# Map the old-style lprojs in this directory to new-style names.
		# A side effect of using set intersection rather than a simple glob is that existing new-style names are ignored for free.
		lprojs = set(dirnames)
		lprojs.intersection_update(mappings_keys)

		for old_name in lprojs:
			new_name = mappings[old_name]

			# Change old_name and new_name to be relative to cwd (or absolute), rather than relative to dirpath.
			old_name = path.join(dirpath, old_name)
			new_name = path.join(dirpath, new_name)

			if versioned:
				svn_rename(old_name, new_name)
			else:
				rename(old_name, new_name)

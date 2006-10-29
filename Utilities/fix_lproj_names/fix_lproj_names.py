#!/usr/bin/env python

"""Usage: fix_lproj_names [targets]

Converts old-style lproj names (e.g. "English.lproj") to ISO 639-1 names (e.g. "en.lproj").

"targets" are pathnames to directories to recursively search for .lproj directories. If no targets are specified, . is used.

Requires Python 2.3 or later.\
"""

# http://developer.apple.com/documentation/MacOSX/Conceptual/BPInternational/Articles/LanguageDesignations.html
# http://loc.gov/standards/iso639-2/php/English_list.php
mappings = {
	'Afrikaans':	'af',
	'Albanian':	'sq',
	'Amharic':	'am',
	'Arabic':	'ar',
	'Armenian':	'hy',
	'Assamese':	'as',
	'Aymara':	'ay',
	'Azerbaijani':	'az',
	'Basque':	'eu',
	'Bengali':	'bn',
	'Breton':	'br',
	'Bulgarian':	'bg',
	'Burmese':	'my',
	'Byelorussian': 'be',
	'Catalan':	'ca',
	'Chinese':	'zh',
	'Croatian':	'hr',
	'Czech':	'cs',
	'Danish':	'da',
	'Dutch':	'nl',
	'Dzongkha':	'dz',
	'English':	'en',
	'Esperanto':	'eo',
	'Estonian':	'et',
	'Faroese':	'fo',
	'Farsi':	'fa',
	'Finnish':	'fi',
	'French':	'fr',
	'Galician':	'gl',
	'Georgian':	'ka',
	'German':	'de',
	'Greek':	'el',
	'Greenlandic':	'kl',
	'Guarani':	'gn',
	'Gujarati':	'gu',
	'Hebrew':	'he',
	'Hindi':	'hi',
	'Hungarian':	'hu',
	'Icelandic':	'is',
	'Indonesian':	'id',
	'Inuktitut':	'iu',
	'Irish':	'ga',
	'Italian':	'it',
	'Japanese':	'ja',
	'Javanese':	'jv',
	'Kannada':	'kn',
	'Kashmiri':	'ks',
	'Kazakh':	'kk',
	'Khmer':	'km',
	'Kinyarwanda':	'rw',
	'Kirghiz':	'ky',
	'Korean':	'ko',
	'Kurdish':	'ku',
	'Lao':	'lo',
	'Latin':	'la',
	'Latvian':	'lv',
	'Lithuanian':	'lt',
	'Macedonian':	'mk',
	'Malagasy':	'mg',
	'Malay':	'ms',
	'Malayalam':	'ml',
	'Maltese':	'mt',
	'Manx': 'gv',
	'Marathi':	'mr',
	'Moldavian':	'mo',
	'Mongolian':	'mn',
	'Nepali':	'ne',
	'Norwegian':	'nb',
	'Nyanja':	'ny',
	'Nynorsk':	'nn',
	'Oriya':	'or',
	'Oromo':	'om',
	'Pashto':	'ps',
	'Polish':	'pl',
	'Portuguese':	'pt',
	'Punjabi':	'pa',
	'Quechua':	'qu',
	'Romanian':	'ro',
	'Rundi':	'rn',
	'Russian':	'ru',
	'Sami': 'se',
	'Sanskrit':	'sa',
	'Scottish':	'gd',
	'Serbian':	'sr',
	'Sindhi':	'sd',
	'Sinhalese':	'si',
	'Slovak':	'sk',
	'Slovenian':	'sl',
	'Somali':	'so',
	'Spanish':	'es',
	'Sundanese':	'su',
	'Swahili':	'sw',
	'Swedish':	'sv',
	'Tagalog':	'tl',
	'Tajiki':	'tg',
	'Tamil':	'ta',
	'Tatar':	'tt',
	'Telugu':	'te',
	'Thai': 'th',
	'Tibetan':	'bo',
	'Tigrinya':	'ti',
	'Tongan':	'to',
	'Turkish':	'tr',
	'Turkmen':	'tk',
	'Uighur':	'ug',
	'Ukrainian':	'uk',
	'Urdu': 'ur',
	'Uzbek':	'uz',
	'Vietnamese':	'vi',
	'Welsh':	'cy',
	'Yiddish':	'yi',
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

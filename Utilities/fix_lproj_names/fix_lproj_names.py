#!/usr/bin/env python

"""Usage: fix_lproj_names [targets]

Converts old-style lproj names (e.g. "English.lproj") to ISO 639-1 names (e.g. "en.lproj").

"targets" are pathnames to directories to recursively search for .lproj directories. If no targets are specified, . is used.

Requires Python 2.3 or later.
"""

# http://developer.apple.com/documentation/MacOSX/Conceptual/BPInternational/Articles/LanguageDesignations.html
# http://loc.gov/standards/iso639-2/php/English_list.php
mappings = {
	'Catalan':	'ca',
	'Chinese':	'zh',
	'English':	'en',
	'French':	'fr',
	'German':	'de',
	'Italian':	'it',
	'Japanese':	'ja',
	'Portuguese':	'pt',
	'Spanish':	'es',
	'Swedish':	'sv',
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

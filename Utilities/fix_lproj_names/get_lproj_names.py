#!/usr/bin/env python

import optparse
parser = optparse.OptionParser(usage='Generates a list of all lproj names in a given directory (including the entire tree below it). Returns every name once. Does not include the .lproj suffix.')
options, args = parser.parse_args()

if not args:
	args = ['/System']

lprojs = set()
import os
for topdir in args:
	for dirpath, dirnames, filenames in os.walk(topdir):
		# We don't expect an lproj to occur inside of another lproj, so we filter these out.
		not_lprojs = []
		for name in dirnames:
			if name.endswith('.lproj'):
				lprojs.add(name[:-6])
			else:
				not_lprojs.append(name)
		dirnames[:] = not_lprojs

lprojs_sorted = list(lprojs)
lprojs_sorted.sort()

for name in lprojs_sorted:
	print name

#!/usr/bin/env python

"""
listToHTML: convert The List from its normal format to HTML for easier (maybe) reading.

usage: listToHTML theList.txt theList.html

---
submitted by Mac-arena the Bored Zo.
part of Adium by Adam Iser.
/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2004, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
 | This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 | General Public License as published by the Free Software Foundation; either version 2 of the License,
 | or (at your option) any later version.
 |
 | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 | Public License for more details.
 |
 | You should have received a copy of the GNU General Public License along with this program; if not,
 | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 \------------------------------------------------------------------------------------------------------ */
"""

task_names = {
	'+': "change or addition",
	'-': "removal",
	'*': "bug-fix", 
	'#': "debatable",
	'=': "done",
}
task_colours = {
	'+': "#008800", #change or addition
	'-': "#8800FF", #removal
	'*': "#0000FF", #bug-fix
	'#': "#FF0000", #debatable
	'=': "#888888", #done
}
fallbacks = []

def genfallbacks(fallbacks):
	"""
	prepare to generate colours that aren't in the default dictionary, in case the legend changes.
	'fallbacks' must have an append method.
	"""

	increment = 0x11
	red, green, blue = (0,0,0)
	format = '#%x%x%x'
	defaults = task_colours.values()

	while red <= 0xFF and green <= 0xFF and blue <= 0xFF:
		color = format % (red, green, blue)
		if color not in defaults:
			fallbacks.append(color)
		if blue == 0xFF:
			if green == 0xFF:
				red += increment
				green = 0x00
			else:
				green += increment
			blue = 0x00
		else:
			blue += increment
	del increment, red, green, blue, format, defaults

def warn(warning):
	import sys
	print >>sys.stderr, warning

def CSSclass(instr):
	"given a string, turn it into something usable as a CSS class name."

	index = instr.find('(')
	if index >= 0:
		instr = instr[:index]

	instr = instr.strip()

	import re
	instr = re.sub("\s+", '_', instr)

	return instr

def HTMLescape(instr):
	"given a string, turn it into something usable inside an HTML file (by escaping '<>&' with entities."

	def HTMLentity(match):
		if match.group(0) == '&':
			return '&amp;'
		elif match.group(0) == '<':
			return '&lt;'
		elif match.group(0) == '>':
			return '&gt;'
		else:
			return match.group(0)

	import re
	return re.sub('[&<>]', HTMLentity, instr)

def listToHTML(infile, outfile):
	"the converter. pass an iterable (infile) and a flob that exports the 'write' method (outfile)."

	import re

	legendRE = re.compile("Legend", re.IGNORECASE)
	categories = []
	catsepRE = re.compile('^\s*(?P<BULLET>.) (?P<NAME>.+)\s*$')
	separatorRE = re.compile('^-+$')
	subheadingRE = re.compile("^(?P<WHITESPACE>\s*)(?P<NAME>.+):\s*$")
	taskRE = re.compile("^\s*(?P<BULLET>.) (?P<TASK>.+)$")

	mode = object()
	legendMode = object()
	headingMode = object()
	taskMode = object()
	inBody = False
	inTaskList = False
	inTask = False

	genfallbacks(fallbacks)

	reservoir = []

	legendFmt = '<dt>%(bullet)s</dt>\n\t<dd class="%(CSS name)s">%(name)s</dd>\n'
	taskStartFmt = '\t<li class="%(bullet name)s">%(task)s'
	ruleFmt = '\t.%(bullet name)s { color: %(color)s }\n'

	outfile.write(
		'<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">\n'
		"<html><head>\n"
		'<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">\n'
		"<title>The List&trade;</title>\n"
		'<style type="text/css">\n'
		'body { color: black; background-color: white }\n')

	for buf in infile:
#		buf = buf.strip()
		if legendRE.search(buf):
			mode = legendMode
		elif separatorRE.match(buf):
#			print 'separator: inBody %i inTask %i inTaskList %i mode %u legendMode %u headingMode %u' % (inBody, inTask, inTaskList, id(mode), id(legendMode), id(headingMode))
			if not inBody:
				outfile.write(
					"</style>\n"
					"</head>\n"
					"<body>\n")
				inBody = True
			if inTask:
				outfile.write("\t</li>\n")
				inTask = False
			if inTaskList:
				outfile.write(
					"</ul>\n"
					"<hr>\n")
				inTaskList = False
			if mode is legendMode:
				#starting separator.
				#write out the legend.
				outfile.write(
					"<h1>Legend</h1>\n"
					'<dl>\n')
				outfile.write(''.join(reservoir))
				outfile.write('</dl>\n<hr>\n')
				del reservoir[:]

			if mode is legendMode or mode is taskMode:
				#begin heading mode
				outfile.write("\n<h1>")
				mode = headingMode
			elif mode is headingMode:
				#ending separator.
				outfile.write(''.join(reservoir))
				del reservoir[:]
				outfile.write("</h1>\n")
				mode = taskMode
		else:
			if mode is legendMode:
				match = catsepRE.match(buf)
				if match:
					bullet, name = match.groups()
					if bullet not in task_colours:
						task_colours[bullet] = fallbacks.pop()
					task_names[bullet] = CSSname = CSSclass(name)
					#add the list pair for the legend section of the page.
					reservoir.append(legendFmt % {
						'bullet': bullet,
						'CSS name': CSSname,
						'name': HTMLescape(name),
						'color': task_colours[bullet],
						})
					#write the CSS rule.
					outfile.write(ruleFmt % {
						'bullet name': CSSname,
						'color': task_colours[bullet],
						})

			elif mode is headingMode:
				reservoir.append(buf)
			elif mode is taskMode:
				sbuf = buf.strip()
#				print 'found task "%s"' % sbuf
				match = taskRE.match(sbuf)
				if match:
#					print "starting task"
					if not inTaskList:
						outfile.write("<ul>\n")
						inTaskList = True
					bullet, taskStart = match.groups()
					bullet_name = task_names[bullet]
					if inTask:
						outfile.write("\t</li>\n")
					else:
						inTask = True
					outfile.write(taskStartFmt % {
						'bullet': bullet,
						'task': HTMLescape(taskStart)+'\n',
						'bullet name': bullet_name
						})
				else:
					match = subheadingRE.match(buf)
					if match:
#						print 'subheading'
						if inTask:
							outfile.write("\t</li>\n")
							inTask = False
						if inTaskList:
							outfile.write("</ul>\n")
						h_number = 2
						ws = match.group("WHITESPACE").replace('    ', '\t')
						h_number += len(ws)
#						print 'whitespace="%s" originally "%s" (%u chars); h_number = %u' % (ws, match.group("WHITESPACE"), len(ws), h_number)
						outfile.write("<h%u>" % h_number)
						outfile.write(HTMLescape(match.group("NAME")))
						outfile.write("</h%u>\n" % h_number)
						if inTaskList:
							outfile.write("<ul>\n")
					else:
#						print 'continuing task'
						#continue a task.
						if buf.strip():
							if not inTaskList:
								outfile.write("<ul>\n")
								inTaskList = True
							if not inTask:
								outfile.write("\t<li>\n")
								inTask = True
							outfile.write(HTMLescape(buf))
	if inTask:
		outfile.write("\t</li>\n")
	if inTaskList:
		outfile.write("</ul>\n")
	if inBody:
		outfile.write("</body>\n")
	outfile.write("</html>\n")

if __name__ == "__main__":
	import sys
	infile =  file(sys.argv[1], 'rU', 1)
	outfile = file(sys.argv[2], 'w',  1)
	listToHTML(infile, outfile)

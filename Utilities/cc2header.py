#!/usr/bin/python

import sys, xml.parsers.expat

if len(sys.argv) < 2:
	sys.exit(1)

currentLevel = 0
currentName = None

insideDict = False

lastKey = None
currentClass = None
currentHeader = None

def start_element(name, attrs):
	global currentLevel, currentName
	global insideDict

	currentLevel += 1
	currentName = name

	if currentLevel == 4 and name == 'dict':
		currentClass = None
		currentHeader = None
		insideDict = True

def end_element(name):
	global currentLevel, currentName
	global insideDict

	if currentLevel == 4 and name == 'dict':
		if (currentHeader):
			print '#include "%s"' % currentHeader
		else:
			print '#include "%s.h"' % currentClass
		insideDict = False

	currentName = name
	currentLevel -= 1

def char_data(data):
	global lastKey
	global currentClass, currentHeader
	if insideDict:
		if currentLevel == 5 and currentName == 'key':
			lastKey = data
		if currentLevel == 5 and currentName == 'string':
			if lastKey == 'Header':
				currentHeader = data
			if lastKey == 'Class':
				currentClass = data

parser = xml.parsers.expat.ParserCreate()
parser.StartElementHandler = start_element
parser.EndElementHandler = end_element
parser.CharacterDataHandler = char_data
parser.ParseFile(file(sys.argv[1]))

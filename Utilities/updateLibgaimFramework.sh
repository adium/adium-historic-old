#!/bin/sh
cvs add Libgaim.framework
cd Libgaim.framework
cvs add Versions
cd Versions
cvs add A
cd A
cvs add Libgaim
cvs add Headers
cvs add Resources
cvs add Headers/*
cvs add Resources/*
cd ../../..
cvs commit Libgaim.framework

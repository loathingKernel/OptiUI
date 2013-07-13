#!/bin/bash

filelist="ui"
filelist="${filelist} README.md"

archive="resourcesOptiUI.s2z"

zip -r -0 ${archive} ${filelist}

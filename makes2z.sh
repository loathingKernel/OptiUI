#!/bin/bash

filelist="ui"
filelist="${filelist} README.md"
filelist="${filelist} core"

archive="resourcesOptiUI.s2z"

zip -r -0 ${archive} ${filelist}

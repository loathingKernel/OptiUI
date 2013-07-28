#!/bin/bash

filelist="ui"
filelist="${filelist} README.md"

archive_name="resourcesOptiUI.zip"
s2z_name="resourcesOptiUI.s2z"

7z a ${archive_name} ${filelist}

mv ${archive_name} ${s2z_name}

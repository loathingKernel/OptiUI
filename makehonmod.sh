#!/bin/bash

filelist="ui"
filelist="${filelist} mod.xml"
filelist="${filelist} icon.png"
filelist="${filelist} README.md"

archive_name="OptiUI.zip"
honmod_name="OptiUI.honmod"

7z a ${archive_name} ${filelist}

mv ${archive_name} ${honmod_name}

#!/bin/bash

filelist="mod.xml"
filelist="${filelist} icon.png"

archive_name="OptiUI_100h.zip"
honmod_name="OptiUI_100h.honmod"

7z a ${archive_name} ${filelist}

mv ${archive_name} ${honmod_name}

#!/bin/bash

filelist="mod.xml"
filelist="${filelist} icon.png"
filelist="${filelist} ui"

archive_name="OptiUI_Shop.zip"
honmod_name="OptiUI_Shop.honmod"

7z a ${archive_name} ${filelist}

mv ${archive_name} ${honmod_name}

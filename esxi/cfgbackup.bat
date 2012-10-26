@echo off

:: Directory to VMware vSphere CLI bin dir
set CLI=C:\Program Files (x86)\VMware\VMware vSphere CLI\bin

:: File to save cfg to
set SAVE=C:\file.tgz

:: Server ip
set SERVER=localhost

perl "%CLI%\vicfg-cfgbackup.pl" --server %SERVER% -s "%SAVE%"


pause
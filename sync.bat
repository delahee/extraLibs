mdir %HAXEPATH%\extraLibs
xcopy /Y  *.* %HAXEPATH%extraLibs 

mdir %HAXEPATH%\extraLibs\ui
xcopy /Y /S ui %HAXEPATH%extraLibs\ui\

REM pause
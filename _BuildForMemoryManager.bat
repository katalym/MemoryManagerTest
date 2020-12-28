@echo off

set FILENAME=MemoryManagerTest_%1
set DCC32="%ProgramFiles(x86)%\Embarcadero\Studio\21.0\bin\dcc32.exe" -B -GD -$R+ -$Q+ -$O- -H+ -W+ -W-SYMBOL_PLATFORM -DMM_%1 -AGenerics.Collections=System.Generics.Collections;Generics.Defaults=System.Generics.Defaults;WinTypes=Winapi.Windows;WinProcs=Winapi.Windows;DbiTypes=BDE;DbiProcs=BDE;DbiErrs=BDE -NSSystem.Win;Data.Win;Datasnap.Win;Web.Win;Soap.Win;Xml.Win;Bde;System;Xml;Data;Datasnap;Web;Soap;Winapi;Vcl;Vcl.Imaging;Vcl.Touch;Vcl.Samples;Vcl.Shell; -uMadExcept\Win32 MemoryManagerTest.dpr
set DCC64="%ProgramFiles(x86)%\Embarcadero\Studio\21.0\bin\dcc64.exe" -B -GD -$R+ -$Q+ -$O- -H+ -W+ -W-SYMBOL_PLATFORM -DMM_%1 -AGenerics.Collections=System.Generics.Collections;Generics.Defaults=System.Generics.Defaults;WinTypes=Winapi.Windows;WinProcs=Winapi.Windows;DbiTypes=BDE;DbiProcs=BDE;DbiErrs=BDE -NSSystem.Win;Data.Win;Datasnap.Win;Web.Win;Soap.Win;Xml.Win;Bde;System;Xml;Data;Datasnap;Web;Soap;Winapi;Vcl;Vcl.Imaging;Vcl.Touch;Vcl.Samples;Vcl.Shell; -uMadExcept\Win64 MemoryManagerTest.dpr
echo Building %FILENAME% with Delphi 10.4 Rio 32 and 64 bit
rem echo %DCC32%
re, echo %DCC64%
%DCC32%
if %errorlevel% NEQ 0 goto errorexit
rem madExceptPatch.exe MemoryManagerTest.exe MemoryManagerTest.mes MemoryManagerTest.map 
rem if %errorlevel% NEQ 0 goto errorexit
move MemoryManagerTest.exe %1\Win32\%FILENAME%_32.exe
if %errorlevel% NEQ 0 goto errorexit
%DCC64%
if %errorlevel% NEQ 0 goto errorexit
rem madExceptPatch.exe MemoryManagerTest.exe MemoryManagerTest.mes MemoryManagerTest.map 
rem if %errorlevel% NEQ 0 goto errorexit
move MemoryManagerTest.exe %1\Win64\%FILENAME%_64.exe
if %errorlevel% NEQ 0 goto errorexit

exit /B 0

:errorexit
echo script failed with error: %errorlevel%
pause
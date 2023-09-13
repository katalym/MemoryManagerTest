@echo off

set FILENAME=MemoryManagerTest_%1
rem 20.0 - Delphi 10.3 Rio
rem 21.0 - Delphi 10.4 Sydney
rem 22.0 - Delphi 11
set "DelphiBinPath=%ProgramFiles(x86)%\Embarcadero\Studio\22.0\bin"
set DCC32="%DelphiBinPath%\dcc32.exe" -B -GD -$R+ -$Q+ -$O- -H+ -W+ -W-SYMBOL_PLATFORM -DMM_%1 -AGenerics.Collections=System.Generics.Collections;Generics.Defaults=System.Generics.Defaults;WinTypes=Winapi.Windows;WinProcs=Winapi.Windows;DbiTypes=BDE;DbiProcs=BDE;DbiErrs=BDE -NSSystem.Win;Data.Win;Datasnap.Win;Web.Win;Soap.Win;Xml.Win;Bde;System;Xml;Data;Datasnap;Web;Soap;Winapi;Vcl;Vcl.Imaging;Vcl.Touch;Vcl.Samples;Vcl.Shell; -NU%1\Win32 MemoryManagerTest.dpr
set DCC64="%DelphiBinPath%\dcc64.exe" -B -GD -$R+ -$Q+ -$O- -H+ -W+ -W-SYMBOL_PLATFORM -DMM_%1 -AGenerics.Collections=System.Generics.Collections;Generics.Defaults=System.Generics.Defaults;WinTypes=Winapi.Windows;WinProcs=Winapi.Windows;DbiTypes=BDE;DbiProcs=BDE;DbiErrs=BDE -NSSystem.Win;Data.Win;Datasnap.Win;Web.Win;Soap.Win;Xml.Win;Bde;System;Xml;Data;Datasnap;Web;Soap;Winapi;Vcl;Vcl.Imaging;Vcl.Touch;Vcl.Samples;Vcl.Shell; -NU%1\Win64 MemoryManagerTest.dpr
rem for madexcept
rem set DCC32="%DelphiBinPath%\dcc32.exe" -B -GD -$R+ -$Q+ -$O- -H+ -W+ -W-SYMBOL_PLATFORM -DMM_%1 -AGenerics.Collections=System.Generics.Collections;Generics.Defaults=System.Generics.Defaults;WinTypes=Winapi.Windows;WinProcs=Winapi.Windows;DbiTypes=BDE;DbiProcs=BDE;DbiErrs=BDE -NSSystem.Win;Data.Win;Datasnap.Win;Web.Win;Soap.Win;Xml.Win;Bde;System;Xml;Data;Datasnap;Web;Soap;Winapi;Vcl;Vcl.Imaging;Vcl.Touch;Vcl.Samples;Vcl.Shell; -uMadExcept\Win32 -NU%1\Win32 MemoryManagerTest.dpr
rem set DCC64="%DelphiBinPath%\dcc64.exe" -B -GD -$R+ -$Q+ -$O- -H+ -W+ -W-SYMBOL_PLATFORM -DMM_%1 -AGenerics.Collections=System.Generics.Collections;Generics.Defaults=System.Generics.Defaults;WinTypes=Winapi.Windows;WinProcs=Winapi.Windows;DbiTypes=BDE;DbiProcs=BDE;DbiErrs=BDE -NSSystem.Win;Data.Win;Datasnap.Win;Web.Win;Soap.Win;Xml.Win;Bde;System;Xml;Data;Datasnap;Web;Soap;Winapi;Vcl;Vcl.Imaging;Vcl.Touch;Vcl.Samples;Vcl.Shell; -uMadExcept\Win64 -NU%1\Win64 MemoryManagerTest.dpr
echo --------------------------------------------------------- %FILENAME% -------------------------------------------------------
echo Building %FILENAME% - 32 and 64 bit
rem echo %DCC32%
rem echo %DCC64%
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
echo script %0 failed with error: %errorlevel%
pause

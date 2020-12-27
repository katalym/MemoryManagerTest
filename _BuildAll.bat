@echo off

echo !!! Make sure there is no memory manader defined in MemoryManagerTest.inc !!!
pause

del MemoryManagerTest*.exe /q
del Win32\MemoryManagerTest*.exe /q
del Win64\MemoryManagerTest*.exe /q
echo ---------------------------------------------------------------

echo Building for SCALEMM2
call _BuildForMemoryManager.bat ScaleMM2 
if %errorlevel% NEQ 0 goto errorexit

echo Building for FASTMM4
call _BuildForMemoryManager.bat FastMM4 
if %errorlevel% NEQ 0 goto errorexit

echo Building for FASTMM5
call _BuildForMemoryManager.bat FastMM5 
if %errorlevel% NEQ 0 goto errorexit

echo Building for DEFAULT
call _BuildForMemoryManager.bat Default 
if %errorlevel% NEQ 0 goto errorexit

echo Building for BIGBRAIN
call _BuildForMemoryManager.bat BigBrain 
if %errorlevel% NEQ 0 goto errorexit

exit /B 0

:errorexit
echo script failed with error: %errorlevel%
pause

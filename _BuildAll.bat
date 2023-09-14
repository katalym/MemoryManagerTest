@echo off

echo copying  MemoryManagerTest.inc.for.BuildAll MemoryManagerTest.inc
copy MemoryManagerTest.inc.for.BuildAll MemoryManagerTest.inc

del MemoryManagerTest*.exe /q /s
echo ---------------------------------------------------------------

echo Building for DEFAULT
call _BuildForMemoryManager.bat Default
if %errorlevel% NEQ 0 goto errorexit

echo Building for SCALEMM2
call _BuildForMemoryManager.bat ScaleMM2
if %errorlevel% NEQ 0 goto errorexit

echo Building for TCMAlloc
call _BuildForMemoryManager.bat TCMAlloc
if %errorlevel% NEQ 0 goto errorexit

echo Building for FASTMM4
call _BuildForMemoryManager.bat FastMM4
if %errorlevel% NEQ 0 goto errorexit

echo Building for FASTMM4_FullDebug
call _BuildForMemoryManager.bat FastMM4_FullDebug
if %errorlevel% NEQ 0 goto errorexit

echo Building for FASTMM5
call _BuildForMemoryManager.bat FastMM5
if %errorlevel% NEQ 0 goto errorexit

echo Building for FASTMM5_FullDebug
call _BuildForMemoryManager.bat FastMM5_FullDebug
if %errorlevel% NEQ 0 goto errorexit

echo Building for BIGBRAIN
call _BuildForMemoryManager.bat BigBrain
if %errorlevel% NEQ 0 goto errorexit

echo Building for BrainMM
call _BuildForMemoryManager.bat BrainMM
if %errorlevel% NEQ 0 goto errorexit

exit /B 0

:errorexit
echo script %0 failed with error: %errorlevel%
pause

# Memory Manager Test for Delphi 10.3+
Test various memory managers for Delphi 10.3+ in 32/64 bit modes.

Available Memory managers are (see MemoryManagerTest.inc)
1. Default
2. BigBrain (on hold due to some test are never end)
3. FastMM4
4. FastMM5
5. ScaleMM2
6. TCMalloc
7. BrainMM

It is modified version of FastCode memory manager challenge - you can find the original project here (not sure is any of them are supported):
- http://fastcode.sourceforge.net/challenge_content/MemoryManager_v1.html
- http://fastcode.sourceforge.net/fastcodeproject/34.htm
- https://github.com/andremussche/scalemm

Project uses Dephi 10.4 - Berlin by default - modify \_BuildForMemoryManager.bat file to refer required compiller.

To build test executables run:
\_BuildAll.bat

Test Executables are built and placed into subfolder <MemoryManagerFolder>\Win32 for 32bit excexutable and <MemoryManagerFolder>\Win64 for 64bit one.

To Run all available test - execute \_TestAll.bat it runs every test executable, performs all default tests and save results into file MemoryManagerTest_<MemoryManagerName>_{32|64}.Results.csv at the same location excutable was run from. 
  
For example for ScaleMM2 32bit it will be:

executable:
  ScaleMM2\Win32\MemoryManagerTest_ScaleMM2_32.exe

results:
  ScaleMM2\Win32\MemoryManagerTest_ScaleMM2_32.Results.csv 

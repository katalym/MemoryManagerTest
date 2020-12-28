{

Fast Memory Manager: Options Include File

Set the default options for FastMM here.

}

{Enable to use faster fixed-size move routines when upsizing small blocks.
 These routines are much faster than the Borland RTL move procedure since they
 are optimized to move a fixed number of bytes. This option may be used
 together with the FastMove library for even better performance.}
{$define UseCustomFixedSizeMoveRoutines}

{Enable to always assume that the application is multithreaded. Enabling this
 option will cause a significant performance hit with single threaded
 applications. Enable if you are using multi-threaded third party tools that do
 not properly set the IsMultiThread variable. Also set this option if you are
 going to share this memory manager between a single threaded application and a
 multi-threaded DLL.}
{$define AssumeMultiThreaded}

{Enable this option to not call Sleep when a thread contention occurs. This
 option will improve performance if the ratio of the number of active threads
 to the number of CPU cores is low (typically < 2). With this option set a
 thread will usually enter a "busy waiting" loop instead of relinquishing its
 timeslice when a thread contention occurs, unless UseSwitchToThread is
 also defined (see below) in which case it will call SwitchToThread instead of
 Sleep.}
{$define NeverSleepOnThreadContention}

  {Set this option to call SwitchToThread instead of sitting in a "busy waiting"
   loop when a thread contention occurs. This is used in conjunction with the
   NeverSleepOnThreadContention option, and has no effect unless
   NeverSleepOnThreadContention is also defined. This option may improve
   performance with many CPU cores and/or threads of different priorities. Note
   that the SwitchToThread API call is only available on Windows 2000 and later.}
  {$define UseSwitchToThread}

{-----------------------------Debugging Options-------------------------------}

{Enable this option to suppress the generation of debug info for the
 FastMM5.pas unit. This will prevent the integrated debugger from stepping into
 the memory manager code.}
{$define NoDebugInfo}

{Set this option to use the assembly language version which is faster than the
 pascal version. Disable only for debugging purposes. Setting the
 CheckHeapForCorruption option automatically disables this option.}
{$define ASMVersion}

{FastMM always catches attempts to free the same memory block twice, however it
 can also check for corruption of the memory heap (typically due to the user
 program overwriting the bounds of allocated memory). These checks are
 expensive, and this option should thus only be used for debugging purposes.
 If this option is set then the ASMVersion option is automatically disabled.}
{$define CheckHeapForCorruption}

{Enable this option to catch attempts to perform MM operations after FastMM has
 been uninstalled. With this option set when FastMM is uninstalled it will not
 install the previous MM, but instead a dummy MM handler that throws an error
 if any MM operation is attempted. This will catch attempts to use the MM
 after FastMM has been uninstalled.}
{$define DetectMMOperationsAfterUninstall}

{Set the following option to do extensive checking of all memory blocks. All
 blocks are padded with both a header and trailer that are used to verify the
 integrity of the heap. Freed blocks are also cleared to to ensure that they
 cannot be reused after being freed. This option slows down memory operations
 dramatically and should only be used to debug an application that is
 overwriting memory or reusing freed pointers. Setting this option
 automatically enables CheckHeapForCorruption and disables ASMVersion.
 Very important: If you enable this option your application will require the
 FastMM_FullDebugMode.dll library. If this library is not available you will
 get an error on startup.}
{$define FullDebugMode}

  {Set this option to check for user code that uses an interface of a freed
   object. Note that this will disable the checking of blocks modified after
   being freed (the two are not compatible). This option has no effect if
   FullDebugMode is not also enabled.}
  {$define CatchUseOfFreedInterfaces}

  {Set this option to log all errors to a text file in the same folder as the
   application. Memory errors (with the FullDebugMode option set) will be
   appended to the log file. Has no effect if "FullDebugMode" is not set.}
  {$define LogErrorsToFile}

  {Set this option to log all memory leaks to a text file in the same folder as
   the application. Memory leak reports (with the FullDebugMode option set)
   will be appended to the log file. Has no effect if "LogErrorsToFile" and
   "FullDebugMode" are not also set. Note that usually all leaks are always
   logged, even if they are "expected" leaks registered through
   AddExpectedMemoryLeaks. Expected leaks registered by pointer may be excluded
   through the HideExpectedLeaksRegisteredByPointer option.}
  {$define LogMemoryLeakDetailToFile}

  {Deletes the error log file on startup. No effect if LogErrorsToFile is not
   also set.}
  {$define ClearLogFileOnStartup}

    {$define DoNotInstallIfDLLMissing}
    {If the FastMM_FullDebugMode.dll file is not available then FastMM will not
     install itself. No effect unless FullDebugMode and LoadDebugDLLDynamically
     are also defined.}

  {If FastMM encounters a problem with a memory block inside the FullDebugMode
   FreeMem handler then an "invalid pointer operation" exception will usually
   be raised. If the FreeMem occurs while another exception is being handled
   (perhaps in the try.. finally code) then the original exception will be
   lost. With this option set FastMM will ignore errors inside FreeMem when an
   exception is being handled, thus allowing the original exception to
   propagate.}
  {$define SuppressFreeMemErrorsInsideException}

{---------------------------Memory Leak Reporting-----------------------------}

{Set this option to enable reporting of memory leaks. Combine it with the two
 options below for further fine-tuning.}
{$define EnableMemoryLeakReporting}

  {Set this option to suppress the display and logging of expected memory leaks
   that were registered by pointer. Leaks registered by size or class are often
   ambiguous, so these expected leaks are always logged to file (in
   FullDebugMode with the LogMemoryLeakDetailToFile option set) and are never
   hidden from the leak display if there are more leaks than are expected.}
  {$define HideExpectedLeaksRegisteredByPointer}

{Allow sharing of the memory manager between a main application and DLLs that
 were also compiled with FastMM. This allows you to pass dynamic arrays and
 long strings to DLL functions provided both are compiled to use FastMM.
 Sharing will only work if the library that is supposed to share the memory
 manager was compiled with the "AttemptToUseSharedMM" option set. Note that if
 the main application is single threaded and the DLL is multi-threaded that you
 have to set the IsMultiThread variable in the main application to true or it
 will crash when a thread contention occurs. Note that statically linked DLL
 files are initialized before the main application, so the main application may
 well end up sharing a statically loaded DLL's memory manager and not the other
 way around. }
{$define ShareMM}

{Define this to attempt to share the MM of the main application or other loaded
 DLLs in the same process that were compiled with ShareMM set. When sharing a
 memory manager, memory leaks caused by the sharer will not be freed
 automatically. Take into account that statically linked DLLs are initialized
 before the main application, so set the sharing options accordingly.}
{$define AttemptToUseSharedMM}

{Define this to enable backward compatibility for the memory manager sharing
 mechanism used by Delphi 2006 and 2007, as well as older FastMM versions.}
{$define EnableBackwardCompatibleMMSharing}

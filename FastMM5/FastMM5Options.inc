{

Fast Memory Manager: Options Include File

Set the default options for FastMM here.

}

{---------------------------Miscellaneous Options-----------------------------}

{Enable to use faster fixed-size move routines when upsizing small blocks.
 These routines are much faster than the Borland RTL move procedure since they
 are optimized to move a fixed number of bytes. This option may be used
 together with the FastMove library for even better performance.}
{$define UseCustomFixedSizeMoveRoutines}

{-----------------------Concurrency Management Options------------------------}

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

  {If FastMM encounters a problem with a memory block inside the FullDebugMode
   FreeMem handler then an "invalid pointer operation" exception will usually
   be raised. If the FreeMem occurs while another exception is being handled
   (perhaps in the try.. finally code) then the original exception will be
   lost. With this option set FastMM will ignore errors inside FreeMem when an
   exception is being handled, thus allowing the original exception to
   propagate.}
  {$define SuppressFreeMemErrorsInsideException}

{-----------------------Memory Manager Sharing Options------------------------}

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

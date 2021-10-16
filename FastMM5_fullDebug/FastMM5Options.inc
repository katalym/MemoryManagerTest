{

Fast Memory Manager: Options Include File

Set the default options for FastMM here.

}

{---------------------------Miscellaneous Options-----------------------------}

{Enable this define to align all blocks on 16 byte boundaries so aligned SSE
 instructions can be used safely. If this option is disabled then some of the
 smallest block sizes will be 8-byte aligned instead which may result in a
 reduction in memory usage. Medium and large blocks are always 16-byte aligned
 irrespective of this setting.}
{.$define FastMM_Align16Bytes}

{Due to QC#14070 ("Delphi IDE attempts to free memory after the shutdown code
 of borlndmm.dll has been called"), FastMM cannot be uninstalled safely when
 used inside a replacement borlndmm.dll for the IDE. Setting this option will
 circumvent this problem by never uninstalling the memory manager.}
{.$define FastMM_NeverUninstall}

{-----------------------------Debugging Options-------------------------------}

{Enable this option to suppress the display of all message dialogs. This is
 useful in service applications that should not be interrupted.}
{.$define FastMM_NoMessageBoxes}

{Set the following option to do extensive checking of all memory blocks. All
 blocks are padded with both a header and trailer that are used to verify the
 integrity of the heap. Freed blocks are also cleared to to ensure that they
 cannot be reused after being freed. This option slows down memory operations
 dramatically and should only be used to debug an application that is
 overwriting memory or reusing freed pointers.
 Very important: If you enable this option your application will require the
 FastMM_FullDebugMode.dll library. If this library is not available you will
 get an error on startup.}
{$define FastMM_FullDebugMode}

  {Deletes the error log file on startup.}
  {$define FastMM_ClearLogFileOnStartup}

  {Loads the FASTMM_FullDebugMode.dll dynamically. If the DLL cannot be found
   then stack traces will not be available. Note that this may cause problems
   due to a changed DLL unload order when sharing the memory manager. Use with
   care.}
  {.$define FastMM_DebugLibraryDynamicLoading}

{---------------------------Memory Leak Reporting-----------------------------}

{Set this option to enable reporting of memory leaks. Combine it with the two
 options below for further fine-tuning.}
{$define FastMM_EnableMemoryLeakReporting}

  {Set this option to require the program to be run inside the IDE debugger to
   report memory leaks. This option has no effect if the option
   "FastMM_EnableMemoryLeakReporting" is not also set. Note that this option does not 
   work with libraries, only EXE projects.}
  {.$define FastMM_RequireDebuggerPresenceForLeakReporting}

{-----------------------Memory Manager Sharing Options------------------------}

{Allow sharing of the memory manager between a main application and DLLs that
 were also compiled with FastMM. This allows you to pass dynamic arrays and
 long strings to DLL functions provided both are compiled to use FastMM.
 Sharing will only work if the library that is supposed to share the memory
 manager was compiled with the "FastMM_AttemptToUseSharedMM" option set. Note that if
 the main application is single threaded and the DLL is multi-threaded that you
 have to set the IsMultiThread variable in the main application to true or it
 will crash when a thread contention occurs. Note that statically linked DLL
 files are initialized before the main application, so the main application may
 well end up sharing a statically loaded DLL's memory manager and not the other
 way around. }
{$define FastMM_ShareMM}

  {Allow sharing of the memory manager by a DLL with other DLLs (or the main
   application if this is a statically loaded DLL) that were also compiled with
   FastMM. Set this option with care in dynamically loaded DLLs, because if the
   DLL that is sharing its MM is unloaded and any other DLL is still sharing
   the MM then the application will crash. This setting is only relevant for
   DLL libraries and requires FastMM_ShareMM to also be set to have any effect.
   Sharing will only work if the library that is supposed to share the memory
   manager was compiled with the "FastMM_AttemptToUseSharedMM" option set. Note that
   if DLLs are statically linked then they will be initialized before the main
   application and then the DLL will in fact share its MM with the main
   application. This option has no effect unless FastMM_ShareMM is also set.}
  {.$define FastMM_ShareMMIfLibrary}

{Define this to attempt to share the MM of the main application or other loaded
 DLLs in the same process that were compiled with FastMM_ShareMM set. When sharing a
 memory manager, memory leaks caused by the sharer will not be freed
 automatically. Take into account that statically linked DLLs are initialized
 before the main application, so set the sharing options accordingly.}
{$define FastMM_AttemptToUseSharedMM}

{--------------------------------Option Grouping------------------------------}

{Combines the FastMM_FullDebugMode, FastMM_DebugLibraryDynamicLoading. Consequently FastMM will only be installed
 (In FastMM_FullDebugMode) when the FastMM_FullDebugMode.dll file is available. This
 is useful when the same executable will be distributed for both debugging as
 well as deployment.}
{.$define FastMM_FullDebugModeWhenDLLAvailable}

{.$define FastMM_DebugLibraryStaticDependency}
{.$define FastMM_DisableAutomaticInstall}
{

Memory Manager Usage Logger.

Description:
 Logs all memory manager operations to a file. This may then be used to extract
 statistics about the application's memory ussage.

Usage:
 Place this unit as the very first unit under the "uses" section in your
 project's .dpr file. The output file will be stored in c:\MMUsage.Log.

License:
 This work is copyright Professional Software Development / Pierre le Riche and
 is distributed under the LGPL licence.

Notes:
 If you use this please e-mail me your comments - good and bad.
 My e-mail address is pleriche@psd.co.za.

Change log:
 Version 1.00 (15 November 2004):
  Initial version.
}

unit MMUsageLogger;

interface

const
  // The name of the usage log file
  LogFileName = 'D:\git\bvsextra\Memory Manager Test\UsageLogger\MMUsageLogger_Test.MemoryManager.Usage';

implementation

uses
  Windows, MMUsageLogger_MemotyOperationRecordUnit;

function LoggedFreeMem(APointer: Pointer): Integer; forward;
function LoggedGetMem(ASize: NativeInt): Pointer; forward;
function LoggedReallocMem(APointer: Pointer; ASize: NativeInt): Pointer; forward;
procedure LogOperation(aOldPointerNumber, aRequestedSize, aNewPointerNumber: Cardinal); forward;

var
  // The address of the usage buffer
  OperationBuffer: PMMOperationArray;
  // The number of used entries in the buffer
  OperationBufferUsageCount: Cardinal = 0;
  // The number of pointers used
  PointerNumber: Cardinal = 1;
  // Is the logger locked?
  LoggerLocked: boolean;
  // Hexadecimal characters
  LHexTable: ShortString = '0123456789ABCDEF';
  // The memory manager that was replaced
  OldMemoryManager: TMemoryManager;
  // The replacement memory manager
  NewMemoryManager: TMemoryManager;
  // A string uniquely identifying the current process (for sharing memory managers)
  UniqueProcessIDString: ShortString = '????????_PID_MMUsageLogger'#0;
  // The handle of the MM window
  MMWindow: HWND;
  // Is the MM in place a shared memory manager?
  OwnsMMWindow: Boolean;
  // The log file handle
  LogFileHandle: THandle;

// Flushes the buffer to disk
procedure FlushBuffer;
var
  LBytesWritten: Cardinal;
begin
  // Append to the logfile
  WriteFile(LogFilehandle, OperationBuffer^, OperationBufferUsageCount * SizeOf(TMMOperation), LBytesWritten, nil);
  // Reset buffer size
  OperationBufferUsageCount := 0;
end;

// Sets up and installs the memory manager
procedure InstallMemoryManager;
var
  i, LCurrentProcessID: Cardinal;
begin
  // Build a string identifying the current process
  LCurrentProcessID := GetCurrentProcessId;
  for i := 0 to 7 do
  begin
    UniqueProcessIDString[8 - i] :=
      LHexTable[1 + ((LCurrentProcessID shr (i * 4)) and $F)];
  end;
  // Is the replacement memory manager already installed for this process?
  MMWindow := FindWindow('STATIC', PChar(@UniqueProcessIDString[1]));
  if MMWindow = 0 then
  begin
    // No memory manager installed yet - create the invisible window
    MMWindow := CreateWindow('STATIC',
      PChar(@UniqueProcessIDString[1]),
      WS_POPUP, 0, 0, 0, 0,
      0, 0, LCurrentProcessID, nil);
    // The window data is a pointer to this memory manager
    SetWindowLong(MMWindow, GWL_USERDATA, Integer(@NewMemoryManager));
    // We will be using this memory manager
    NewMemoryManager.GetMem := LoggedGetMem;
    NewMemoryManager.FreeMem := LoggedFreeMem;
    NewMemoryManager.ReallocMem := LoggedReallocMem;
    // Owns the MMWindow
    OwnsMMWindow := True;
    // Allocate the buffer
    OperationBuffer := VirtualAlloc(nil, SizeOf(TMMOperationArray), MEM_COMMIT, PAGE_READWRITE);
    // Create the log file
    LogFileHandle := CreateFile(LogFileName, GENERIC_READ or GENERIC_WRITE, 0, nil, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
    if LogFileHandle = INVALID_HANDLE_VALUE then
      System.Error(reAssertionFailed);
  end
  else
  begin
    // Get the address of the shared memory manager
    NewMemoryManager := PMemoryManager(GetWindowLong(MMWindow, GWL_USERDATA))^;
    // The MMWindow is owned by the main program (not this DLL)
    OwnsMMWindow := False;
  end;
  // Save the old memory manager
  GetMemoryManager(OldMemoryManager);
  // Replace the memory manager with either this one or the shared one.
  SetMemoryManager(NewMemoryManager);
end;

// Locks the logger so only this thread can access it
procedure LockLogger;
asm
@LockLoop:
  xor al, al
  mov dl, 1
  // Attempt to lock the batches
  lock cmpxchg LoggerLocked, dl
  jz @Done
  // Couldn't lock the batches - sleep and try again
  push 0
  call sleep
  // Try again
  jmp @LockLoop
@Done:
end;

// Replacement for SysFreeMem
function LoggedFreeMem(APointer: Pointer): Integer;
begin
  LockLogger;
  // Decrement the pointer
  Dec(PByte(APointer), 4);
  // Log the operation
  LogOperation(PCardinal(APointer)^, 0, 0);
  // Call the old freemem
  Result := OldMemoryManager.FreeMem(APointer);
  // Unlock the logger
  LoggerLocked := False;
end;

// Replacement for SysGetMem
function LoggedGetMem(ASize: NativeInt): Pointer;
begin
  LockLogger;
  // Call the old getmem
  Result := OldMemoryManager.GetMem(ASize + 4);
  // Log the operation
  LogOperation(0, ASize, PointerNumber);
  // Store the pointer number before the memory block
  PCardinal(Result)^ := PointerNumber;
  // Advance the pointer
  Inc(PByte(Result), 4);
  // Increment the pointer number
  Inc(PointerNumber);
  // Unlock the logger
  LoggerLocked := False;
end;

// Replacement for SysReallocMem
function LoggedReallocMem(APointer: Pointer; ASize: NativeInt): Pointer;
var
  LOldPointerNumber: integer;
begin
  LockLogger;
  // Decrement the pointer
  Dec(PByte(APointer), 4);
  // Get the old pointer number
  LOldPointerNumber := PCardinal(APointer)^;
  // Call the old reallocmem
  Result := OldMemoryManager.ReallocMem(APointer, ASize + 4);
  // Store the pointer number before the memory block
  PCardinal(Result)^ := LOldPointerNumber;
  // Advance the pointer
  Inc(PByte(Result), 4);
  // Log the operation
  LogOperation(LOldPointerNumber, ASize, LOldPointerNumber);
  // Unlock the logger
  LoggerLocked := False;
end;

// Logs an operation
procedure LogOperation(aOldPointerNumber, aRequestedSize, aNewPointerNumber: Cardinal);
begin
  // Log the operation
  with OperationBuffer[OperationBufferUsageCount] do
  begin
    FOldPointerNumber := aOldPointerNumber;
    FRequestedSize := aRequestedSize;
    FNewPointerNumber := aNewPointerNumber;
    FThreadID := GetCurrentThreadId;
    if FThreadID = MainThreadID then
      FThreadID := 0;
    FTicks := GetTickCount;
  end;
  // Increment the operation count
  Inc(OperationBufferUsageCount);
  // Buffer full?
  if OperationBufferUsageCount = BufferCount then
    FlushBuffer;
end;

procedure UninstallMemoryManager;
begin
  // Restore the old memory manager
  SetMemoryManager(OldMemoryManager);
  // Is this the owner of the shared MM window?
  if OwnsMMWindow then
  begin
    DestroyWindow(MMWindow);
    // Flush the buffer
    FlushBuffer;
    // Close the file
    CloseHandle(LogFileHandle);
    // Free the buffer
    VirtualFree(OperationBuffer, 0, MEM_RELEASE);
  end;
end;

initialization

{Has the Borland MM been used? If so, this file is not the first unit in the
   uses clause of the project's .dpr file.}
if GetHeapStatus.TotalAllocated <> 0 then
  System.Error(reInvalidPtr);
  // Install the memory manager
InstallMemoryManager;

finalization

// Restore the old memory manager
UninstallMemoryManager;

end.

// A MemTest replaying the allocations/deallocations performed by a user's application

unit ReplayMemTestUnit;

interface

uses
  Windows, SysUtils, Classes, VCL.Dialogs, MemTestClassUnit, Math, MMUsageLogger_MemotyOperationRecordUnit, System.Generics.Defaults,
  System.Generics.Collections;

type
  // The single-thread replay MemTest ancestor
  TReplayMemTest = class(TMemTest)
  protected
    // The operations
    FOperations: PMMOperationArray;
    FPointers: TDictionary<Cardinal, pointer>;
  public
    class function GetMemTestDescription: string; override;
    class function GetMemTestName: string; override;
    class function GetCategory: TMemTestCategory; override;
    procedure PrepareMemTestForRun(const aUsageFileToReplay: string =''); override;
    // repeat count for replay log
    class function RepeatCount: Integer; virtual;
    procedure RunMemTest; override;
    class function RunByDefault: boolean; override;
    procedure RunReplay; virtual;
  end;

  // The multi-threaded replay MemTest ancestor
  TMultiThreadReplayMemTest = class(TReplayMemTest)
  public
    class function GetMemTestName: string; override;
    class function GetCategory: TMemTestCategory; override;
    class function RunByDefault: boolean; override;
    // number of simultaneously running threads
    class function RunningThreads: Integer;
    procedure RunReplay; override;
    // total number of threads running
    class function ThreadCount: Integer;
  end;

implementation

uses
  MemTestUtilities, System.UITypes, CPU_Usage_Unit, bvDataTypes;

type
  // The replay thread used in multi-threaded replay MemTests
  TReplayThread = class(TThread)
  private
    FMemTest: TMemTest;
    FOperations: string;
    FRepeatCount: Integer;
    procedure ExecuteReplay;
  public
    constructor Create(ASuspended: boolean; AMemTest: TMemTest; RepeatCount: Integer);
    procedure Execute; override;
    property Operations: string read FOperations write FOperations;
  end;

//// Reads a file in its entirety and returns the contents as a string. Returns a blank string on error.
//function TReplayMemTest.LoadFile_Full(const AFileName: string): string;
//const
//  INVALID_SET_FILE_POINTER = DWORD( - 1);
//var
//  // LFileInfo: OFSTRUCT;
//  LHandle: THandle;
//  LFileSize: Cardinal;
//  LBytesRead: Cardinal;
//begin
//  // Default to empty string (file not found)
//  Result := '';
//  // Try to open the file
//  LHandle := CreateFile(PChar(AFileName), GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, 0, 0);
//  if LHandle <> HFILE_ERROR then
//  begin
//    try
//      // Find the FileSize
//      LFileSize := SetFilePointer(LHandle, 0, nil, FILE_END);
//      // Read the file
//      if (LFileSize > 0) and (LFileSize <> INVALID_SET_FILE_POINTER) then
//      begin
//        // Allocate the buffer
//        SetLength(Result, LFileSize);
//        // Go back to the start of the file
//        if SetFilePointer(LHandle, 0, nil, FILE_BEGIN) = 0 then
//        begin
//          // Read the file
//          LBytesRead := 0;
//          Windows.ReadFile(LHandle, Result[1], LFileSize, LBytesRead, nil);
//          // Was all the data read?
//          if LBytesRead <> LFileSize then
//            Result := '';
//        end;
//      end;
//    finally
//      // Close the file
//      CloseHandle(LHandle);
//    end;
//  end;
//end;

class function TReplayMemTest.GetMemTestDescription: string;
begin
  Result := 'Plays back the memory operations of another application as '
    + 'recorded by the MMUsageLogger utility. To record and replay the '
    + 'operations performed by your application:'#13#10
    + '1. Place MMUsageLogger.pas as the first unit in the .dpr of your app'#13#10
    + '2. In MMUsageLogger.pas specidy LogFileName = ... to file where memory operations to be stored'#13#10
    + '3. Run the application (a file <LogFileName> with all memory operations performed will be created)'#13#10
    + '4. Specify this <LogFileName> file in the Usage file to replay'#13#10
    + '5. Select this MemTest and run it'#13#10
    + '6. The Application tool will replay the exact sequence of '
    + 'allocations/deallocations/reallocations of your application, giving you a '
    + 'good idea of how your app will perform with the given memory manager.';
end;

class function TReplayMemTest.GetMemTestName: string;
begin
  Result := 'Usage Replay';
end;

class function TReplayMemTest.GetCategory: TMemTestCategory;
begin
  Result := bmSingleThreadReplay;
end;

procedure TReplayMemTest.PrepareMemTestForRun(const aUsageFileToReplay: string);
begin
  inherited;
  gUsageReplayFileName := aUsageFileToReplay;

//  // Try to load the usage log
//  if FileExists(gUsageReplayFileName) then
//  begin
//    // descendant has specified usage log file
//    FOperations := LoadFile_Full(gUsageReplayFileName);
//    if FOperations = '' then
//      FCanRunMemTest := False;
//  end else
//    raise Exception.CreateFmt('Usage Ffile to replay "%s" not exists', [gUsageReplayFileName]);
//  // Set the list of pointers
//  SetLength(FPointers, length(FOperations) div SizeOf(TMMOperation));
//  Sleep(20); // RH let system relax after big file load... seems to be useful to get consistent results
end;

class function TReplayMemTest.RepeatCount: Integer;
begin
  Result := 1;
end;

procedure TReplayMemTest.RunMemTest;
var
  i: Integer;
begin
  inherited;

  if FileExists(MemTestClassUnit.gUsageReplayFileName) then
  begin
    for i := 1 to RepeatCount do
      RunReplay;
  end;
end;

class function TReplayMemTest.RunByDefault: boolean;
begin
  Result := FileExists(MemTestClassUnit.gUsageReplayFileName);
end;

procedure TReplayMemTest.RunReplay;

  procedure DoRunReplay(aArraySize: int64);
  var
    vOperation: PMMOperation;
    i, vOperations, vOffset: Cardinal;
    UintOfs: NativeUInt;
    p: pointer;
  begin
    // Get a pointer to the first operation
    vOperation := pointer(FOperations);
    // Get the number of operations to perform
    vOperations := bvInt64ToCardinal(aArraySize div SizeOf(TMMOperation));

    // Perform all the operations
    for i := 0 to vOperations - 1 do
    begin
      // Perform the operation
      if vOperation^.FNewPointerNumber > 0 then
      begin
        if vOperation^.FOldPointerNumber <> vOperation^.FNewPointerNumber then
        begin
          // GetMem
          GetMem(p, vOperation^.FRequestedSize);
          FPointers.AddOrSetValue(vOperation^.FNewPointerNumber, p);
        end
        else
        begin
          // ReallocMem
          p := FPointers[vOperation^.FOldPointerNumber];
          ReallocMem(p, vOperation^.FRequestedSize);
          FPointers[vOperation^.FOldPointerNumber] := p;
        end;
        // Touch every 4K page
        vOffset := 0;
        while vOffset < vOperation^.FRequestedSize do
        begin
          UintOfs := vOffset;
          PByte(NativeUInt(FPointers[vOperation^.FNewPointerNumber]) + UintOfs)^ := 1;
          Inc(vOffset, 4096);
        end;
        // Touch the last byte
        if vOperation^.FRequestedSize > 2 then
        begin
          UintOfs := vOperation^.FRequestedSize;
          Dec(UintOfs);
          PByte(NativeUInt(FPointers[vOperation^.FNewPointerNumber]) + UintOfs)^ := 1;
        end;
      end
      else
      begin
        // FreeMem
        FreeMem(FPointers[vOperation^.FOldPointerNumber]);
//        FPointers[vOperation^.FOldPointerNumber] := nil;
        FPointers.Remove(vOperation^.FOldPointerNumber);
      end;
      // Next operation
      Inc(vOperation);
    end;
  end;

var
  UsageFile: file;
  vNumRead: Integer;
  vStartCPUUsage: Int64;
  vStartTicks: Cardinal;
  p: pointer;
begin

  FPointers := TDictionary<Cardinal, pointer>.Create(1024*1024);
  try
    FOperations := VirtualAlloc(nil, SizeOf(TMMOperationArray), MEM_COMMIT, PAGE_READWRITE);
    try

      AssignFile(UsageFile, MemTestClassUnit.gUsageReplayFileName);
      Reset(UsageFile, 1);
      repeat
        vStartCPUUsage := CPU_Usage_Unit.GetCpuUsage_Total;
        vStartTicks := GetTickCount;
        // read next block of operations
        System.BlockRead(UsageFile, FOperations^, SizeOf(TMMOperationArray), vNumRead);
        FExcludeThisCPUUsage := FExcludeThisCPUUsage + CPU_Usage_Unit.GetCpuUsage_Total - vStartCPUUsage;
        FExcludeThisTicks := FExcludeThisTicks + GetTickCount - vStartTicks;
        // perform test for operations read
        if vNumRead > 0 then
        begin
          DoRunReplay(vNumRead);
          vStartCPUUsage := CPU_Usage_Unit.GetCpuUsage_Total;
          vStartTicks := GetTickCount;
          FPointers.TrimExcess;
          FExcludeThisCPUUsage := FExcludeThisCPUUsage + CPU_Usage_Unit.GetCpuUsage_Total - vStartCPUUsage;
          FExcludeThisTicks := FExcludeThisTicks + GetTickCount - vStartTicks;
        end;
      until (vNumRead = 0);
      // Use CloseFile rather than Close; Close is provided for backward compatibility.
      CloseFile(UsageFile);

    finally
      VirtualFree(FOperations, 0, MEM_RELEASE);
    end;

  finally
    // Make sure all memory is released to avoid memory leaks in MemTest
    for p in FPointers.Values do begin
      if p <> nil then
        FreeMem(p);
    end;
    FreeAndNil(FPointers);
  end;

  UpdateUsageStatistics;

end;

constructor TReplayThread.Create(ASuspended: boolean; AMemTest: TMemTest; RepeatCount: Integer);
begin
  inherited Create(ASuspended);
  FreeOnTerminate := False;
  Priority := tpNormal;
  FMemTest := AMemTest;
  FRepeatCount := RepeatCount;
end;

procedure TReplayThread.Execute;
var
  i: Integer;
begin
  // Repeat the replay log RepeatCount times
  for i := 1 to FRepeatCount do
    ExecuteReplay;
end;

procedure TReplayThread.ExecuteReplay;
var
  vOperation: PMMOperation;
  i, vOperations, vOffset: Cardinal;
  FPointers: array of pointer;
  UintOfs: NativeUInt;
begin
  // Set the list of pointers
  SetLength(FPointers, length(FOperations) div SizeOf(TMMOperation));
  // Get a pointer to the first operation
  vOperation := pointer(FOperations);
  // Get the number of operations to perform
  vOperations := bvInt64ToCardinal(length(FPointers));
  // Perform all the operations
  for i := 0 to vOperations - 1 do
  begin
    // Perform the operation
    if vOperation^.FNewPointerNumber > 0 then
    begin
      if vOperation^.FOldPointerNumber <> vOperation^.FNewPointerNumber then
      begin
        // GetMem
        GetMem(FPointers[vOperation^.FNewPointerNumber], vOperation^.FRequestedSize);
      end
      else
      begin
        // ReallocMem
        ReallocMem(FPointers[vOperation^.FOldPointerNumber], vOperation^.FRequestedSize);
      end;
      // Touch every 4K page
      vOffset := 0;
      while vOffset < vOperation^.FRequestedSize do
      begin
        UintOfs := vOffset;
        PByte(NativeUInt(FPointers[vOperation^.FNewPointerNumber]) + UintOfs)^ := 1;
        Inc(vOffset, 4096);
      end;
      // Touch the last byte
      if vOperation^.FRequestedSize > 2 then
      begin
        UintOfs := vOperation^.FRequestedSize;
        Dec(UintOfs);
        PByte(NativeUInt(FPointers[vOperation^.FNewPointerNumber]) + UintOfs)^ := 1;
      end;
    end
    else
    begin
      // FreeMem
      FreeMem(FPointers[vOperation^.FOldPointerNumber]);
      FPointers[vOperation^.FOldPointerNumber] := nil;
    end;
    // Next operation
    Inc(vOperation);
    // Log peak usage every 1024 operations
    if i and $3FF = 0 then
      FMemTest.UpdateUsageStatistics;
    // the replay is probably running about 10 to 50 times faster than reality
    // force thread switch every 8192 operations to prevent whole MemTest from running in a single time-slice
    if i and $1FFF = 0 then
      Sleep(0);
  end;
  // Make sure all memory is released to avoid memory leaks in MemTest
  for i := 0 to bvInt64ToCardinal(high(FPointers)) do
    if FPointers[i] <> nil then
      FreeMem(FPointers[i]);
end;

// add your replay MemTests below...

class function TMultiThreadReplayMemTest.GetMemTestName: string;
begin
  Result := 'Usage Replay ' + RunningThreads.ToString + ' threads';
end;

class function TMultiThreadReplayMemTest.GetCategory: TMemTestCategory;
begin
  Result := bmMultiThreadReplay;
end;

class function TMultiThreadReplayMemTest.RunByDefault: boolean;
begin
  Result := False;
end;

class function TMultiThreadReplayMemTest.RunningThreads: Integer;
begin
  Result := 4;
end;

procedure TMultiThreadReplayMemTest.RunReplay;
//var
//  i, rc, slot: Integer;
//  WT: TReplayThread;
//  ThreadArray: array [0 .. 63] of TReplayThread;
//  HandleArray: TWOHandleArray;
begin
  inherited;

//  Assert(RunningThreads <= 64, 'Maximum 64 simultaneously running threads in TMultiThreadReplayMemTest');
//  // create threads to start with
//  for i := 0 to RunningThreads - 1 do
//  begin
//    WT := TReplayThread.Create(True, Self, RepeatCount);
//    WT.Operations := FOperations;
//    HandleArray[i] := WT.Handle;
//    ThreadArray[i] := WT;
//  end;
//  // start threads...
//  for i := 0 to RunningThreads - 1 do
//  begin
//    ThreadArray[i].Suspended := False;
//  end;
//  // loop to replace terminated threads
//  for i := RunningThreads + 1 to ThreadCount do
//  begin
//    rc := WaitForMultipleObjects(RunningThreads, @HandleArray, False, INFINITE);
//    slot := rc - WAIT_OBJECT_0;
//    if (slot < 0) or (slot >= RunningThreads) then
//    begin
//      MessageDlg(SysErrorMessage(GetLastError), mtError, [mbOK], 0);
//      Exit;
//    end;
//    ThreadArray[slot].Free;
//    WT := TReplayThread.Create(True, Self, RepeatCount);
//    WT.Operations := FOperations;
//    HandleArray[slot] := WT.Handle;
//    ThreadArray[slot] := WT;
//    WT.Suspended := False;
//  end;
//  rc := WaitForMultipleObjects(RunningThreads, @HandleArray, True, INFINITE);
//  for i := 0 to RunningThreads - 1 do
//    ThreadArray[i].Free;
//  if rc < WAIT_OBJECT_0 then
//    MessageDlg(SysErrorMessage(GetLastError), mtError, [mbOK], 0);
end;

class function TMultiThreadReplayMemTest.ThreadCount: Integer;
begin
  Result := 100;
end;

end.

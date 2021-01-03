// A benchmark replaying the allocations/deallocations performed by a user's application

unit ReplayBenchmarkUnit;

interface

uses
  Windows, SysUtils, Classes, VCL.Dialogs, BenchmarkClassUnit, Math, MMUsageLogger_MemotyOperationRecordUnit, System.Generics.Defaults,
  System.Generics.Collections;

type
  // The single-thread replay benchmark ancestor
  TReplayBenchmark = class(TMMBenchmark)
  protected
    // The operations
    FOperations: PMMOperationArray;
    FPointers: TDictionary<integer, pointer>;
  public
    class function GetBenchmarkDescription: string; override;
    class function GetBenchmarkName: string; override;
    class function GetCategory: TBenchmarkCategory; override;
    procedure PrepareBenchmarkForRun(const aUsageFileToReplay: string =''); override;
    // repeat count for replay log
    class function RepeatCount: Integer; virtual;
    procedure RunBenchmark; override;
    class function RunByDefault: boolean; override;
    procedure RunReplay; virtual;
  end;

  // The multi-threaded replay benchmark ancestor
  TMultiThreadReplayBenchmark = class(TReplayBenchmark)
  public
    class function GetBenchmarkName: string; override;
    class function GetCategory: TBenchmarkCategory; override;
    class function RunByDefault: boolean; override;
    // number of simultaneously running threads
    class function RunningThreads: Integer;
    procedure RunReplay; override;
    // total number of threads running
    class function ThreadCount: Integer;
  end;

implementation

uses
  BenchmarkUtilities, System.UITypes, CPU_Usage_Unit;

type
  // The replay thread used in multi-threaded replay benchmarks
  TReplayThread = class(TThread)
  private
    FBenchmark: TMMBenchmark;
    FOperations: string;
    FRepeatCount: Integer;
    procedure ExecuteReplay;
  public
    constructor Create(ASuspended: boolean; ABenchmark: TMMBenchmark; RepeatCount: Integer);
    procedure Execute; override;
    property Operations: string read FOperations write FOperations;
  end;

//// Reads a file in its entirety and returns the contents as a string. Returns a blank string on error.
//function TReplayBenchmark.LoadFile_Full(const AFileName: string): string;
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

class function TReplayBenchmark.GetBenchmarkDescription: string;
begin
  Result := 'Plays back the memory operations of another application as '
    + 'recorded by the MMUsageLogger utility. To record and replay the '
    + 'operations performed by your application:'#13#10
    + '1. Place MMUsageLogger.pas as the first unit in the .dpr of your app'#13#10
    + '2. In MMUsageLogger.pas specidy LogFileName = ... to file where memory operations to be stored'#13#10
    + '3. Run the application (a file <LogFileName> with all memory operations performed will be created)'#13#10
    + '4. Specify this <LogFileName> file in the Usage file to replay'#13#10
    + '5. Select this benchmark and run it'#13#10
    + '6. The Application tool will replay the exact sequence of '
    + 'allocations/deallocations/reallocations of your application, giving you a '
    + 'good idea of how your app will perform with the given memory manager.';
end;

class function TReplayBenchmark.GetBenchmarkName: string;
begin
  Result := 'Usage Replay';
end;

class function TReplayBenchmark.GetCategory: TBenchmarkCategory;
begin
  Result := bmSingleThreadReplay;
end;

procedure TReplayBenchmark.PrepareBenchmarkForRun(const aUsageFileToReplay: string);
begin
  inherited;
  gUsageReplayFileName := aUsageFileToReplay;

//  // Try to load the usage log
//  if FileExists(gUsageReplayFileName) then
//  begin
//    // descendant has specified usage log file
//    FOperations := LoadFile_Full(gUsageReplayFileName);
//    if FOperations = '' then
//      FCanRunBenchmark := False;
//  end else
//    raise Exception.CreateFmt('Usage Ffile to replay "%s" not exists', [gUsageReplayFileName]);
//  // Set the list of pointers
//  SetLength(FPointers, length(FOperations) div SizeOf(TMMOperation));
//  Sleep(20); // RH let system relax after big file load... seems to be useful to get consistent results
end;

class function TReplayBenchmark.RepeatCount: Integer;
begin
  Result := 1;
end;

procedure TReplayBenchmark.RunBenchmark;
var
  i: Integer;
begin
  inherited;

  if FileExists(BenchmarkClassUnit.gUsageReplayFileName) then
  begin
    for i := 1 to RepeatCount do
      RunReplay;
  end;
end;

class function TReplayBenchmark.RunByDefault: boolean;
begin
  Result := FileExists(BenchmarkClassUnit.gUsageReplayFileName);
end;

procedure TReplayBenchmark.RunReplay;

  procedure DoRunReplay(aArraySize: int64);
  var
    LPOperation: PMMOperation;
    LInd, LOperationCount, LOffset: Integer;
    UintOfs: NativeUInt;
    p: pointer;
  begin
    // Get a pointer to the first operation
    LPOperation := pointer(FOperations);
    // Get the number of operations to perform
    LOperationCount := aArraySize div SizeOf(TMMOperation);

    // Perform all the operations
    for LInd := 0 to LOperationCount - 1 do
    begin
      // Perform the operation
      if LPOperation^.FNewPointerNumber >= 0 then
      begin
        if LPOperation^.FOldPointerNumber <> LPOperation^.FNewPointerNumber then
        begin
          // GetMem
          GetMem(p, LPOperation^.FRequestedSize);
          FPointers.AddOrSetValue(LPOperation^.FNewPointerNumber, p);
        end
        else
        begin
          // ReallocMem
          p := FPointers[LPOperation^.FOldPointerNumber];
          ReallocMem(p, LPOperation^.FRequestedSize);
          FPointers[LPOperation^.FOldPointerNumber] := p;
        end;
        // Touch every 4K page
        LOffset := 0;
        while LOffset < LPOperation^.FRequestedSize do
        begin
          UintOfs := LOffset;
          PByte(NativeUInt(FPointers[LPOperation^.FNewPointerNumber]) + UintOfs)^ := 1;
          Inc(LOffset, 4096);
        end;
        // Touch the last byte
        if LPOperation^.FRequestedSize > 2 then
        begin
          UintOfs := LPOperation^.FRequestedSize;
          Dec(UintOfs);
          PByte(NativeUInt(FPointers[LPOperation^.FNewPointerNumber]) + UintOfs)^ := 1;
        end;
      end
      else
      begin
        // FreeMem
        FreeMem(FPointers[LPOperation^.FOldPointerNumber]);
//        FPointers[LPOperation^.FOldPointerNumber] := nil;
        FPointers.Remove(LPOperation^.FOldPointerNumber);
      end;
      // Next operation
      Inc(LPOperation);
    end;
  end;

var
  UsageFile: file;
  vNumRead: Integer;
  vStartCPUUsage: Int64;
  vStartTicks: Cardinal;
  p: pointer;
begin

  FPointers := TDictionary<integer, pointer>.Create(1024*1024);
  try
    FOperations := VirtualAlloc(nil, SizeOf(TMMOperationArray), MEM_COMMIT, PAGE_READWRITE);
    try

      AssignFile(UsageFile, BenchmarkClassUnit.gUsageReplayFileName);
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
    // Make sure all memory is released to avoid memory leaks in benchmark
    for p in FPointers.Values do begin
      if p <> nil then
        FreeMem(p);
    end;
    FreeAndNil(FPointers);
  end;

  UpdateUsageStatistics;

end;

constructor TReplayThread.Create(ASuspended: boolean; ABenchmark: TMMBenchmark; RepeatCount: Integer);
begin
  inherited Create(ASuspended);
  FreeOnTerminate := False;
  Priority := tpNormal;
  FBenchmark := ABenchmark;
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
  LPOperation: PMMOperation;
  LInd, LOperationCount, LOffset: Integer;
  FPointers: array of pointer;
  UintOfs: NativeUInt;
begin
  // Set the list of pointers
  SetLength(FPointers, length(FOperations) div SizeOf(TMMOperation));
  // Get a pointer to the first operation
  LPOperation := pointer(FOperations);
  // Get the number of operations to perform
  LOperationCount := length(FPointers);
  // Perform all the operations
  for LInd := 0 to LOperationCount - 1 do
  begin
    // Perform the operation
    if LPOperation^.FNewPointerNumber >= 0 then
    begin
      if LPOperation^.FOldPointerNumber <> LPOperation^.FNewPointerNumber then
      begin
        // GetMem
        GetMem(FPointers[LPOperation^.FNewPointerNumber], LPOperation^.FRequestedSize);
      end
      else
      begin
        // ReallocMem
        ReallocMem(FPointers[LPOperation^.FOldPointerNumber], LPOperation^.FRequestedSize);
      end;
      // Touch every 4K page
      LOffset := 0;
      while LOffset < LPOperation^.FRequestedSize do
      begin
        UintOfs := LOffset;
        PByte(NativeUInt(FPointers[LPOperation^.FNewPointerNumber]) + UintOfs)^ := 1;
        Inc(LOffset, 4096);
      end;
      // Touch the last byte
      if LPOperation^.FRequestedSize > 2 then
      begin
        UintOfs := LPOperation^.FRequestedSize;
        Dec(UintOfs);
        PByte(NativeUInt(FPointers[LPOperation^.FNewPointerNumber]) + UintOfs)^ := 1;
      end;
    end
    else
    begin
      // FreeMem
      FreeMem(FPointers[LPOperation^.FOldPointerNumber]);
      FPointers[LPOperation^.FOldPointerNumber] := nil;
    end;
    // Next operation
    Inc(LPOperation);
    // Log peak usage every 1024 operations
    if LInd and $3FF = 0 then
      FBenchmark.UpdateUsageStatistics;
    // the replay is probably running about 10 to 50 times faster than reality
    // force thread switch every 8192 operations to prevent whole benchmark from running in a single time-slice
    if LInd and $1FFF = 0 then
      Sleep(0);
  end;
  // Make sure all memory is released to avoid memory leaks in benchmark
  for LInd := 0 to high(FPointers) do
    if FPointers[LInd] <> nil then
      FreeMem(FPointers[LInd]);
end;

// add your replay benchmarks below...

class function TMultiThreadReplayBenchmark.GetBenchmarkName: string;
begin
  Result := 'Usage Replay ' + RunningThreads.ToString + ' threads';
end;

class function TMultiThreadReplayBenchmark.GetCategory: TBenchmarkCategory;
begin
  Result := bmMultiThreadReplay;
end;

class function TMultiThreadReplayBenchmark.RunByDefault: boolean;
begin
  Result := False;
end;

class function TMultiThreadReplayBenchmark.RunningThreads: Integer;
begin
  Result := 4;
end;

procedure TMultiThreadReplayBenchmark.RunReplay;
//var
//  i, rc, slot: Integer;
//  WT: TReplayThread;
//  ThreadArray: array [0 .. 63] of TReplayThread;
//  HandleArray: TWOHandleArray;
begin
  inherited;

//  Assert(RunningThreads <= 64, 'Maximum 64 simultaneously running threads in TMultiThreadReplayBenchmark');
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

class function TMultiThreadReplayBenchmark.ThreadCount: Integer;
begin
  Result := 100;
end;

end.

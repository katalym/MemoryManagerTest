{****************************************************************************************

   StringTestBenchMark & ManyThreadsTestBenchMark v1.0

   By Ivo Tops for FastCode Memory Manager BenchMark & Validation

****************************************************************************************}
unit StringThreadTestUnit;

interface

{$I MemoryManagerTest.inc}

uses BenchmarkClassUnit;

type

   TStringThreadTestAbstract = class(TMMBenchmark)
   public
     class function GetBenchmarkDescription: string; override;
     class function GetBenchmarkName: string; override;
     class function GetCategory: TBenchmarkCategory; override;
     class function IsThreadedSpecial: Boolean; override;
     class function NumThreads: Integer; virtual; abstract;
     procedure RunBenchmark; override;
   end;

   TStringThreadTest2 = class(TStringThreadTestAbstract)
     class function NumThreads: Integer; override;
   end;

   TStringThreadTest4 = class(TStringThreadTestAbstract)
     class function NumThreads: Integer; override;
   end;

   TStringThreadTest8 = class(TStringThreadTestAbstract)
     class function NumThreads: Integer; override;
   end;

   TStringThreadTest12 = class(TStringThreadTestAbstract)
     class function NumThreads: Integer; override;
   end;

   TStringThreadTest16 = class(TStringThreadTestAbstract)
     class function NumThreads: Integer; override;
   end;

   TStringThreadTest31 = class(TStringThreadTestAbstract)
     class function NumThreads: Integer; override;
   end;

   TStringThreadTest64 = class(TStringThreadTestAbstract)
     class function NumThreads: Integer; override;
   end;

   TManyThreadsTest = class(TMMBenchmark)
   public
     class function GetBenchmarkDescription: string; override;
     class function GetBenchmarkName: string; override;
     class function GetCategory: TBenchmarkCategory; override;
     procedure RunBenchmark; override;
   end;

procedure DecRunningThreads;

// Counters for thread running
procedure IncRunningThreads;

procedure NotifyThreadError;

procedure NotifyValidationError;

implementation

uses
  Math, StringThread, windows, sysutils, Classes, PrimeNumbers;

var
  RunningThreads: Integer;
  ThreadError, ValidationError, ThreadMaxReached, ZeroThreadsReached: Boolean;

procedure DecRunningThreads;
var
   RT: Integer;
begin
   RT := InterlockedExchangeAdd({$IFDEF WIN32}@{$ENDIF} RunningThreads, -1);
   ThreadMaxReached := RT > 1250;
   ZeroThreadsReached := RT = 1; // Old value is 1, so new value is zero
end;

procedure ExitTest;
begin
   // If Thread had error raise exception
   if ThreadError then raise Exception.Create('TestThread failed with an Error');
   // If Thread had validate raise exception
   if ValidationError then raise Exception.Create('TestThread failed Validation');
end;

procedure IncRunningThreads;
var
   RT: Integer;
begin
   RT := InterlockedExchangeAdd({$IFDEF WIN32}@{$ENDIF} RunningThreads, 1);
   ZeroThreadsReached := False;
   ThreadMaxReached := RT > 1250;
end;

procedure InitTest;
begin
   RunningThreads := 0;
   ZeroThreadsReached := False;
   ThreadMaxReached := False;
   ThreadError := False;
end;

procedure NotifyThreadError;
begin
   ThreadError := True;
end;

procedure NotifyValidationError;
begin
   ValidationError := True;
end;

class function TStringThreadTestAbstract.GetBenchmarkDescription: string;
begin
   Result := 'A benchmark that does string manipulations concurrently in '+IntToStr(NumThreads)+' different threads';
end;

class function TStringThreadTestAbstract.GetBenchmarkName: string;
begin
   Result := 'String ' + NumThreads.ToString.PadLeft(2, ' ') + ' Thread Test';;
end;

class function TStringThreadTestAbstract.GetCategory: TBenchmarkCategory;
begin
  Result := bmMultiThreadRealloc;
end;

class function TStringThreadTestAbstract.IsThreadedSpecial: Boolean;
begin
  Result := True;
end;

procedure TStringThreadTestAbstract.RunBenchmark;
const
// full debug mode is used to detect memory leaks - not for actual performance test
// value is decreased to avoid Out of Memory in fuul debug mode
{$IFDEF MM_FASTMM4_FullDebug}
  CIterations = 1000;
{$ELSE}
{$IFDEF MM_FASTMM5_FullDebug}
  CIterations = 1000;
{$ELSE}
  CIterations = 5000;
{$ENDIF}
{$ENDIF}
var
  vtc, vic, i, bPrimeIndex: Integer;
  vThreads: TList;
  vThread: TStringThreadEx;
  vHandles: PWOHandleArray;
  wr, wrc: Cardinal;
begin
   inherited;
   InitTest;
   bPrimeIndex := Low(VeryGoodPrimes);
   New(vHandles);
   vtc := NumThreads;
   vic := (CIterations div vtc)+1;
   vThreads := TList.Create;
   for i := 1 to vtc do // Create a loose new thread that does stringactions
   begin
     vThread := TStringThreadEx.Create(vic, 2000, 4096, False);
     vThread.FPrime := VeryGoodPrimes[bPrimeIndex];
     Inc(bPrimeIndex);
     if bPrimeIndex > High(VeryGoodPrimes) then
     begin
       bPrimeIndex := Low(VeryGoodPrimes);
     end;

     vThreads.Add(vThread);
   end;

   for i := 0 to vThreads.Count-1 do
   begin
     vThread := TStringThreadEx(vThreads[i]);
     vHandles^[i] := vThread.Handle;
   end;

   for i := 0 to vThreads.Count-1 do
   begin
     vThread := TStringThreadEx(vThreads[i]);
     vThread.Suspended := False;
   end;

   wr := WaitForMultipleObjects(vThreads.Count, vHandles, True, INFINITE);
   wrc := WAIT_OBJECT_0+vThreads.Count;
{$WARN COMPARISON_FALSE OFF}
   if (wr < WAIT_OBJECT_0) or (wr > wrc) then
   begin
     raise Exception.Create('WaitForMultipleObjects failed on TStringThreadTestAbstract.RunBenchmark');
   end;
{$WARN COMPARISON_FALSE ON}

   {Update the peak address space usage}
   UpdateUsageStatistics;
   Dispose(vHandles);

   for i := 0 to vThreads.Count-1 do
   begin
     vThread := TStringThreadEx(vThreads[i]);
     vThread.Terminate;
   end;

   for i := 0 to vThreads.Count-1 do
   begin
     vThread := TStringThreadEx(vThreads[i]);
     vThread.WaitFor;
   end;

   for i := 0 to vThreads.Count-1 do
   begin
     vThread := TStringThreadEx(vThreads[i]);
     vThread.Free;
   end;

   vThreads.Clear;
   FreeAndnil(vThreads);
   // Done
   ExitTest;
end;

class function TManyThreadsTest.GetBenchmarkDescription: string;
begin
   Result := 'A benchmark that has many temporary threads, each doing a little string processing. ';
   Result := Result + 'This test exposes possible multithreading issues in a memory manager and large per-thread ';
   Result := Result + 'memory requirements.';
end;

class function TManyThreadsTest.GetBenchmarkName: string;
begin
   Result := 'Many Short Lived Threads';
end;

class function TManyThreadsTest.GetCategory: TBenchmarkCategory;
begin
  Result := bmMultiThreadRealloc;
end;

procedure TManyThreadsTest.RunBenchmark;
var
  i, vPrimeIdx: Integer;
  vHandle: THandle;
  vThreadList: TList;

  procedure AddThread(T: TStringThreadEx);
  begin
    T.FPrime := VeryGoodPrimes[vPrimeIdx];
    T.FEventHandle := vHandle;
    Inc(vPrimeIdx);
    if vPrimeIdx > High(VeryGoodPrimes) then
    begin
      vPrimeIdx := Low(VeryGoodPrimes);
    end;
    vThreadList.Add(T);
  end;

var
  vThread: TStringThreadEx;
  vResult: Cardinal;
begin
   inherited;
   InitTest;
   vPrimeIdx := Low(VeryGoodPrimes);
   vThreadList := TList.Create;
   try
     vHandle := CreateEvent(nil, False, False, nil);
     // Launch a lot of threads
     for i := 1 to 30 do
     begin
       AddThread(TStringThreadEx.Create(1000, 10, 512, False));
       AddThread(TStringThreadEx.Create(10, 2, 4096, False));
       AddThread(TStringThreadEx.Create(10, 2, 1024*1024, False));
     end;
     // Launch a lot of threads keeping threadmax in account
     for i := 1 to 30 do
     begin
       AddThread(TStringThreadEx.Create(100, 1, 512, False));
       AddThread(TStringThreadEx.Create(100, 100, 512, False));
       AddThread(TStringThreadEx.Create(100, 1, 512, False));
     end;
     for i := 0 to vThreadList.Count-1 do
     begin
       vThread := TStringThreadEx(vThreadList[i]);
       vThread.Suspended := False;
     end;
     repeat
       vResult := WaitForSingleObject(vHandle, INFINITE);
       if vResult = WAIT_OBJECT_0 then
       begin
         for i := vThreadList.Count-1 downto 0 do
         begin
           vThread := TStringThreadEx(vThreadList[i]);
           if vThread.IsTerminated then
           begin
             vThread.WaitFor;
             vThread.Free;
             vThreadList[i] := nil;
           end;
         end;
         vThreadList.Pack;
       end else
       begin
         //raise Exception.Create('TManyThreadsTest.RunBenchmark -- failed');
       end;
     until vThreadList.Count = 0;
     CloseHandle(vHandle);

   finally
     FreeAndNil(vThreadList);
   end;
     {Update the peak address space usage}
   UpdateUsageStatistics;
   // Done
   ExitTest;
end;

class function TStringThreadTest8.NumThreads: Integer;
begin
  Result := 8;
end;

class function TStringThreadTest2.NumThreads: Integer;
begin
  Result := 2;
end;

class function TStringThreadTest4.NumThreads: Integer;
begin
  Result := 4;
end;

class function TStringThreadTest12.NumThreads: Integer;
begin
  Result := 12;
end;

class function TStringThreadTest16.NumThreads: Integer;
begin
  Result := 16;
end;

class function TStringThreadTest31.NumThreads: Integer;
begin
  Result := 31;
end;

class function TStringThreadTest64.NumThreads: Integer;
begin
  Result := 64;
end;

end.

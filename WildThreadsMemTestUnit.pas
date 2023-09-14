{A MemTest that tests many short-lived threads with many transient small objects.}

unit WildThreadsMemTestUnit;

interface

{$I MemoryManagerTest.inc}

uses Windows, MemTestClassUnit, Classes, Math;

type

  TWildThreads = class(TMemTest)
  public
    class function GetMemTestDescription: string; override;
    class function GetMemTestName: string; override;
    class function GetCategory: TMemTestCategory; override;
    procedure RunMemTest; override;
  end;

implementation

uses
  SysUtils;

const
  cNumThreads = 96;

var
  ReadyThreadsCount: Integer;
  CS: TRTLCriticalSection;

type
  TAWildThread = class(TThread)
    e, m: THandle;
    f: Boolean;
    procedure Execute; override;
  end;

procedure TAWildThread.Execute;
const
{$IFDEF FullDebug}
  IterationsCount = 6;
  REPEATCOUNT     = 3;
{$ELSE}
  IterationsCount = 100000;
  REPEATCOUNT     = 3;
{$ENDIF}
var
  i, j, k, n: Integer;
  p: array [1 .. 151] of Pointer;
begin
  EnterCriticalSection(CS);
  Inc(ReadyThreadsCount);
  LeaveCriticalSection(CS);
  SetEvent(m);
  WaitForSingleObject(e, INFINITE);
  for j := 1 to REPEATCOUNT do
  begin
    // 151 is a prime number, so no trivial cyclicity with 256 (the size)
    for i := low(p) to high(p) do
      GetMem(p[i], i);
    k := low(p);
    for i := 1 to IterationsCount do begin
      n := (i and 255) + 1;
      FreeMem(p[k]);
      GetMem(p[k], n);
      // use memory
      if n > 5 then
        PAnsiChar(p[k])[n - 1] := #0;
      PAnsiChar(p[k])[0] := #0;
      Inc(k);
      if k > high(p) then
        k := low(p);
    end;
    for i := low(p) to high(p) do
      FreeMem(p[i]);
  end;
  f := True;
  SetEvent(m);
end;

class function TWildThreads.GetMemTestDescription: string;
begin
  Result := 'A MemTest that tests many short-lived threads (' + IntToStr(cNumThreads) + ') with many '
    + 'transient small objects. For meaningful results, do not run this '
    + 'MemTest in the Delphi IDE. MemTest submitted by Eric Grange.';
end;

class function TWildThreads.GetMemTestName: string;
begin
  Result := 'Transient threaded objects (' + IntToStr(cNumThreads) + ' threads)';
end;

class function TWildThreads.GetCategory: TMemTestCategory;
begin
  Result := bmMultiThreadAllocAndFree;
end;

procedure TWildThreads.RunMemTest;
const
  LowestPriority = tpLowest;
var
  e, m: THandle;
  c, n: Integer;
  wild: TAWildThread;
  threads: TList;
{$WARN SYMBOL_PLATFORM OFF}
  CurPriority: TThreadPriority;
{$WARN SYMBOL_PLATFORM ON}
begin
  inherited;
  UpdateUsageStatistics;
  ReadyThreadsCount := 0;
  InitializeCriticalSection(CS);
  e := CreateEvent(nil, True, False, nil);
  m := CreateEvent(nil, False, False, nil);
  CurPriority := tpLowest;
  threads := TList.Create;
  // create threads - would be a thread pool in RealWorld (tm)
  for n := 1 to cNumThreads do
  begin
    wild := TAWildThread.Create(True);
    wild.FreeOnTerminate := False;
    wild.Priority := CurPriority;
    if CurPriority = (tpHigher) then
    begin
      CurPriority := tpLowest;
    end else begin
      {$WARN SYMBOL_PLATFORM OFF}
      CurPriority := TThreadPriority(Ord(CurPriority) + 1);
      {$WARN SYMBOL_PLATFORM ON}
    end;
    wild.e := e;
    wild.m := m;
    wild.f := False;
    threads.Add(wild);
  end;

  for n := 0 to threads.Count - 1 do
  begin
    wild := TAWildThread(threads.Items[n]);
    wild.Suspended := False;
  end;

  repeat
    if WaitForSingleObject(m, INFINITE) <> WAIT_OBJECT_0 then
      raise Exception.Create('!WAIT_OBJECT_0');
    EnterCriticalSection(CS);
    c := ReadyThreadsCount;
    LeaveCriticalSection(CS);
  until c = cNumThreads;

  UpdateUsageStatistics;

  SetThreadPriority(GetCurrentThread, THREAD_PRIORITY_TIME_CRITICAL);

  SetEvent(e);

  repeat
    if WaitForSingleObject(m, INFINITE) <> WAIT_OBJECT_0 then
      raise Exception.Create('!WAIT_OBJECT_0');
    for n := 0 to threads.Count - 1 do
    begin
      wild := TAWildThread(threads.Items[n]);
      if wild <> nil then
      begin
        if wild.f then
        begin
          wild.WaitFor;
          // wc := 'Thread exit, priority was = '+IntToStr(Ord(wild.Priority));
          // OutputDebugString(PWideChar(wc));
          wild.Free;
          threads.Items[n] := nil;
        end;
      end;
    end;
    threads.pack;
  until threads.Count = 0;

  SetThreadPriority(GetCurrentThread, THREAD_PRIORITY_NORMAL);

  threads.Free;
  CloseHandle(e);
  CloseHandle(m);
  UpdateUsageStatistics;
  DeleteCriticalSection(CS);
end;

end.

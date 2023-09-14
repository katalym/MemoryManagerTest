// A MemTest to measure raw performance and fragmentation resistance.
// Alternates large number of small string and small number of large string allocations.
// Pure GetMem / FreeMem MemTest without reallocations, similar to WildThreads MemTest.
// 8-thread version that has approx. same memory footprint and CPU load as single-thread version.

unit RawPerformanceMultiThread;

{$I MemoryManagerTest.inc}

interface

uses
  Windows, MemTestClassUnit, Classes, Math;

type
  TRawPerformanceMultiThreadAbstract = class(TMemTest)
  public
    procedure RunMemTest; override;
    class function GetMemTestName: string; override;
    class function GetMemTestDescription: string; override;
    class function GetCategory: TMemTestCategory; override;
    class function IsThreadedSpecial: Boolean; override;
    class function NumThreads: Integer; virtual; abstract;
  end;

  TRawPerformanceMultiThread2 = class(TRawPerformanceMultiThreadAbstract)
    class function NumThreads: Integer; override;
  end;

  TRawPerformanceMultiThread4 = class(TRawPerformanceMultiThreadAbstract)
    class function NumThreads: Integer; override;
  end;

  TRawPerformanceMultiThread8 = class(TRawPerformanceMultiThreadAbstract)
    class function NumThreads: Integer; override;
  end;

  TRawPerformanceMultiThread12 = class(TRawPerformanceMultiThreadAbstract)
    class function NumThreads: Integer; override;
  end;

  TRawPerformanceMultiThread16 = class(TRawPerformanceMultiThreadAbstract)
    class function NumThreads: Integer; override;
  end;

  TRawPerformanceMultiThread31 = class(TRawPerformanceMultiThreadAbstract)
    class function NumThreads: Integer; override;
  end;

  TRawPerformanceMultiThread64 = class(TRawPerformanceMultiThreadAbstract)
    class function NumThreads: Integer; override;
  end;

implementation

uses
  SysUtils, bvDataTypes;

type
  TRawPerformanceThread = class(TThread)
  public
    FThreadCount: Integer;
    FMemTest: TMemTest;
    procedure Execute; override;
  end;

procedure TRawPerformanceThread.Execute;
const
  MAXCHUNK = 1024; // take power of 2
  // full debug mode is used to detect memory leaks - not for actual performance test
  // value is decreased to avoid Out of Memory in fuul debug mode
{$IFDEF FullDebug}
  REPEATS  = 3;
  CHUNCKS  = 32 * 1024;
  POINTERS = 151; // take prime just below 2048  (scaled down 8x from single-thread)
{$ELSE}
  REPEATS  = 25;
  CHUNCKS  = 1024 * 1024;
  POINTERS = 2039; // take prime just below 2048  (scaled down 8x from single-thread)
{$ENDIF}
var
  vToJ, i, j, n, vSize, vIndex: Cardinal;
  vStrings: array [0 .. POINTERS - 1] of string;
begin
  vToJ := bvIntToCardinal((REPEATS div FThreadCount) + 1);
  for j := 1 to vToJ do
  begin
    n := low(vStrings);
    for i := 1 to CHUNCKS do begin
      if i and $FF < $F0 then // 240 times out of 256 ==> chunk < 1 kB
        vSize := (4 * i) and (MAXCHUNK - 1) + 1
      else if i and $FF <> $FF then // 15 times out of 256 ==> chunk < 32 kB
        vSize := 16 * n + 1
      else // 1 time  out of 256 ==> chunk < 256 kB
        vSize := 128 * n + 1;
      vStrings[n] := '';
      SetLength(vStrings[n], vSize);
      // start and end of string are already assigned, access every 4K page in the middle
      vIndex := 1;
      while vIndex <= vSize do
      begin
        vStrings[n][vIndex] := #1;
        Inc(vIndex, 4096);
      end;
      Inc(n);
      if n > high(vStrings) then
        n := low(vStrings);
    end;
    FMemTest.UpdateUsageStatistics;
    for n := low(vStrings) to high(vStrings) do
      vStrings[n] := '';
  end;
end;

class function TRawPerformanceMultiThreadAbstract.GetMemTestDescription: string;
begin
  Result := 'A MemTest to measure raw performance and fragmentation resistance. ' +
    'Allocates large number of small strings (< 1 kB) and small number of larger ' +
    '(< 32 kB) to very large (< 256 kB) strings. ' + IntToStr(NumThreads) + '-thread version.';
end;

class function TRawPerformanceMultiThreadAbstract.GetMemTestName: string;
begin
  Result := 'Raw Performance ' + NumThreads.ToString.PadLeft(2, ' ') + ' threads';
end;

class function TRawPerformanceMultiThreadAbstract.GetCategory: TMemTestCategory;
begin
  Result := bmMultiThreadAllocAndFree;
end;

class function TRawPerformanceMultiThreadAbstract.IsThreadedSpecial: Boolean;
begin
  Result := True;
end;

procedure TRawPerformanceMultiThreadAbstract.RunMemTest;
var
  vThreadsCount: Integer;
  vThreads: array of TRawPerformanceThread;
  i: Integer;
begin
  inherited;
  vThreadsCount := NumThreads;
  SetLength(vThreads, vThreadsCount);
  for i := 0 to vThreadsCount - 1 do
  begin
    vThreads[i] := TRawPerformanceThread.Create(True);
    vThreads[i].FreeOnTerminate := False;
    vThreads[i].FMemTest := Self;
    vThreads[i].FThreadCount := vThreadsCount;
    vThreads[i].Priority := tpLower;
  end;
  for i := 0 to vThreadsCount - 1 do
  begin
    vThreads[i].Suspended := False;
  end;
  for i := 0 to vThreadsCount - 1 do
  begin
    vThreads[i].WaitFor;
  end;
  for i := 0 to vThreadsCount - 1 do
  begin
    vThreads[i].Free;
    vThreads[i] := nil;
  end;
  SetLength(vThreads, 0);
  Finalize(vThreads);
end;

class function TRawPerformanceMultiThread8.NumThreads: Integer;
begin
  Result := 8;
end;

class function TRawPerformanceMultiThread64.NumThreads: Integer;
begin
  Result := 64;
end;

class function TRawPerformanceMultiThread2.NumThreads: Integer;
begin
  Result := 2;
end;

class function TRawPerformanceMultiThread4.NumThreads: Integer;
begin
  Result := 4;
end;

class function TRawPerformanceMultiThread12.NumThreads: Integer;
begin
  Result := 12;
end;

class function TRawPerformanceMultiThread16.NumThreads: Integer;
begin
  Result := 16;
end;

class function TRawPerformanceMultiThread31.NumThreads: Integer;
begin
  Result := 32;
end;

end.

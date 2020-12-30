// A benchmark to measure raw performance and fragmentation resistance.
// Alternates large number of small string and small number of large string allocations.
// Pure GetMem / FreeMem benchmark without reallocations, similar to WildThreads Benchmark.
// Single-thread version.

unit RawPerformanceSingleThread;

{$I MemoryManagerTest.inc}

interface

uses
  Windows, BenchmarkClassUnit, Classes, Math;

type
  TRawPerformanceSingleThread = class(TMMBenchmark)
  private
    procedure Execute;
  public
    class function GetBenchmarkDescription: string; override;
    class function GetBenchmarkName: string; override;
    class function GetCategory: TBenchmarkCategory; override;
    procedure RunBenchmark(const aUsageFileToReplay: string =''); override;
  end;

implementation

uses
  SysUtils;

procedure TRawPerformanceSingleThread.Execute;
const
  MAXCHUNK = 1024; // take power of 2
  // full debug mode is used to detect memory leaks - not for actual performance test
  // value is decreased to avoid Out of Memory in fuul debug mode
{$IFDEF FullDebug}
  IterationCount = 1;
  CHUNCKS        = 32 * 1024;
  POINTERS       = 151; // take prime just below 2048  (scaled down 8x from single-thread)
{$ELSE}
  IterationCount = 3;
  CHUNCKS        = 8 * 1024 * 1024;
  POINTERS       = 16361; // take prime just below 2048  (scaled down 8x from single-thread)
{$ENDIF}
var
  i, n, k, vSize, vIndex: Cardinal;
  vStrings: array [0 .. POINTERS - 1] of string;
begin
  for k := 1 to IterationCount do
  begin
    n := low(vStrings);
    for i := 1 to CHUNCKS do
    begin
      if i and $FF < $F0 then // 240 times out of 256 ==> chunk < 1 kB
        vSize := (4 * i) and (MAXCHUNK - 1) + 1
      else if i and $FF <> $FF then // 15 times out of 256 ==> chunk < 32 kB
        vSize := 2 * n + 1
      else // 1 time  out of 256 ==> chunk < 256 kB
        vSize := 16 * n + 1;
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
    UpdateUsageStatistics;
    for n := low(vStrings) to high(vStrings) do
      vStrings[n] := '';
  end;
  UpdateUsageStatistics;
end;

class function TRawPerformanceSingleThread.GetBenchmarkDescription: string;
begin
  Result := 'A benchmark to measure raw performance and fragmentation resistance. ' +
    'Allocates large number of small strings (< 1 kB) and small number of larger ' +
    '(< 32 kB) to very large (< 256 kB) strings. Single-thread version.';
end;

class function TRawPerformanceSingleThread.GetBenchmarkName: string;
begin
  Result := 'Raw Performance  1 thread';
end;

class function TRawPerformanceSingleThread.GetCategory: TBenchmarkCategory;
begin
  Result := bmSingleThreadAllocAndFree;
end;

procedure TRawPerformanceSingleThread.RunBenchmark;
begin
  inherited;
  Execute;
end;

end.

{A benchmark that creates and frees many objects in a multi-threaded environment}

unit SingleThreadedAllocAndFree;

interface

{$I MemoryManagerTest.inc}

uses
  Windows, BenchmarkClassUnit, Classes, Math;

type

  TSingleThreadAllocateAndFreeBenchmark = class(TMMBenchmark)
  public
    class function GetBenchmarkDescription: string; override;
    class function GetBenchmarkName: string; override;
    class function GetCategory: TBenchmarkCategory; override;
    procedure RunBenchmark; override;
  end;

implementation

class function TSingleThreadAllocateAndFreeBenchmark.GetBenchmarkDescription: string;
begin
  Result := 'A single-threaded benchmark that allocates and frees memory blocks. '
    + 'The usage of different block sizes approximates real-world usage as seen '
    + 'in various replays. Allocated memory is actually "used", i.e. written to '
    + 'and read.  '
    + 'Benchmark submitted by Pierre le Riche.';
end;

class function TSingleThreadAllocateAndFreeBenchmark.GetBenchmarkName: string;
begin
  Result := 'Single-threaded allocate, use and free';
end;

class function TSingleThreadAllocateAndFreeBenchmark.GetCategory: TBenchmarkCategory;
begin
  Result := bmSingleThreadAllocAndFree;
end;

procedure TSingleThreadAllocateAndFreeBenchmark.RunBenchmark;
const
  Prime = 13;
{$IFDEF FullDebug}
  RepeatCount  = 50;
  PointerCount = 6100;
{$ELSE}
  RepeatCount  = 100;
  PointerCount = 610000;
{$ENDIF}
type
  PPointers = ^TPointers;
  TPointers = array [0 .. PointerCount - 1] of Pointer;
var
  i, j, vMax, vSize, vSum: Integer;
  vCalc: NativeUInt;
  vLoop: Cardinal;
  vValue: Int64;
  vPointers: PPointers;
begin
  inherited;
  {We want predictable results}
  vValue := Prime;
  New(vPointers);
  {Allocate the initial pointers}
  for i := 0 to PointerCount - 1 do
  begin
    {Rough breakdown: 50% of pointers are <=64 bytes, 95% < 1K, 99% < 4K, rest < 256K}
    if i and 1 <> 0 then
      vMax := 64
    else
      if i and 15 <> 0 then
      vMax := 1024
    else
      if i and 255 <> 0 then
      vMax := 4 * 1024
    else
      vMax := 256 * 1024;
    {Get the size, minimum 1}
    vSize := (vValue mod vMax) + 1;
    Inc(vValue, Prime);
    {Get the pointer}
    GetMem(vPointers^[i], vSize);
  end;
  {Free and allocate in a loop}
  for j := 1 to RepeatCount do
  begin
    {Update usage statistics}
    UpdateUsageStatistics;
    for i := 0 to PointerCount - 1 do
    begin
      {Free the pointer}
      FreeMem(vPointers^[i]);
      vPointers^[i] := nil;
      {Rough breakdown: 50% of pointers are <=64 bytes, 95% < 1K, 99% < 4K, rest < 256K}
      if i and 1 <> 0 then
        vMax := 64
      else
        if i and 15 <> 0 then
        vMax := 1024
      else
        if i and 255 <> 0 then
        vMax := 4 * 1024
      else
        vMax := 256 * 1024;
      {Get the size, minimum 1}
      vSize := (vValue mod vMax) + 1;
      Inc(vValue, Prime);
      {Get the pointer}
      GetMem(vPointers^[i], vSize);
      {Write the memory}
      for vLoop := 0 to (vSize - 1) div 32 do
      begin
        vCalc := vLoop;
        PByte(NativeUInt(vPointers^[i]) + vCalc * 32)^ := byte(i);
      end;
      {Read the memory}
      vSum := 0;
      if vSize > 15 then
      begin
        for vLoop := 0 to (vSize - 16) div 32 do
        begin
          vCalc := vLoop;
          Inc(vSum, PShortInt(NativeUInt(vPointers^[i]) + vCalc * 32 + 15)^);
        end;
      end;
      {"Use" the sum to suppress the compiler warning}
      if vSum > 0 then;
    end;
  end;
  {Free all the objects}
  for i := 0 to PointerCount - 1 do
  begin
    FreeMem(vPointers^[i]);
    vPointers^[i] := nil;
  end;
  Dispose(vPointers);
end;

end.

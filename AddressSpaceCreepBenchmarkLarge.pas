unit AddressSpaceCreepBenchmarkLarge;

interface

{$I MemoryManagerTest.inc}

uses
  BenchmarkClassUnit, Math;

const
  // full debug mode is used to detect memory leaks - not for actual performance test
  // value is decreased to avoid Out of Memory in fuul debug mode
{$IFDEF FullDebug}
  NumPointers = 200;
{$ELSE}
  NumPointers = 20000;
{$ENDIF}
  {The maximum block size}
  MaxBlockSize = 70000;

type

  TAddressSpaceCreepBenchLarge = class(TMMBenchmark)
  protected
    FPointers: array [0 .. NumPointers - 1] of PAnsiChar;
  public
    constructor CreateBenchmark; override;
    destructor Destroy; override;
    procedure RunBenchmark; override;
    class function GetBenchmarkName: string; override;
    class function GetBenchmarkDescription: string; override;
    class function GetCategory: TBenchmarkCategory; override;
  end;

implementation

constructor TAddressSpaceCreepBenchLarge.CreateBenchmark;
begin
  inherited;
end;

destructor TAddressSpaceCreepBenchLarge.Destroy;
begin
  inherited;
end;

class function TAddressSpaceCreepBenchLarge.GetBenchmarkDescription: string;
begin
  Result := 'Allocates and deallocates thousands of large pointers in a loop, '
    + 'checking that the MM address space usage does not grow unbounded.  '
    + 'Benchmark submitted by Pierre le Riche.';
end;

class function TAddressSpaceCreepBenchLarge.GetBenchmarkName: string;
begin
  Result := 'Address space creep (larger blocks)';
end;

class function TAddressSpaceCreepBenchLarge.GetCategory: TBenchmarkCategory;
begin
  Result := bmSingleThreadAllocAndFree;
end;

procedure TAddressSpaceCreepBenchLarge.RunBenchmark;
const
  Prime = 43;
var
  i, j, LSize, LOffset: integer;
  NextValue {, vTotal} : Int64;
begin
  {Call the inherited handler}
  inherited;
  NextValue := Prime;
  // vTotal := 0;
  {Allocate the pointers}
  for i := low(FPointers) to high(FPointers) do begin
    {Get an initial size}
    LSize := 1 + (MaxBlockSize + NextValue) mod MaxBlockSize;
    Inc(NextValue, Prime); // a prime number
    // if vTotal + LSize > 1600000000 then
    // begin
    // vTotal := vTotal;
    // Break;
    // end;
    {Allocate the pointer}
    GetMem(FPointers[i], LSize);
    // Inc(vTotal, LSize);
    {Touch the memory}
    FPointers[i][0] := AnsiChar(byte(i mod 255));
    FPointers[i][LSize - 1] := AnsiChar(byte(i mod 255));
  end;
  {Free and get new pointers in a loop}
  for j := 1 to 400 do begin
    // vTotal := 0;
    for i := low(FPointers) to high(FPointers) do begin
      {Free the pointer}
      FreeMem(FPointers[i]);
      {Get the new size}
      LSize := 1 + (MaxBlockSize + NextValue) mod MaxBlockSize;
      Inc(NextValue, Prime); // a prime number
      // if vTotal + LSize > 1600000000 then
      // begin
      // vTotal := vTotal;
      // Break;
      // end;
      {Allocate the pointer}
      GetMem(FPointers[i], LSize);
      // Inc(vTotal, LSize);
      {Touch every page of the allocated memory}
      LOffset := 0;
      while LOffset < LSize do
      begin
        FPointers[i][LOffset] := AnsiChar(byte(LOffset mod 255));
        Inc(LOffset, 4096);
      end;
      {Touch the last byte}
      FPointers[i][LSize - 1] := AnsiChar(byte(i mod 255));
    end;
  end;
  {What we end with should be close to the peak usage}
  UpdateUsageStatistics;
  {Free the pointers}
  for i := 0 to high(FPointers) do
    FreeMem(FPointers[i], 1);
end;

end.

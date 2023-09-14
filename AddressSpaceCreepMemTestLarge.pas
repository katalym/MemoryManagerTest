unit AddressSpaceCreepMemTestLarge;

interface

{$I MemoryManagerTest.inc}

uses
  MemTestClassUnit, Math;

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

  TAddressSpaceCreepBenchLarge = class(TMemTest)
  protected
    FPointers: array [0 .. NumPointers - 1] of PAnsiChar;
  public
    constructor CreateMemTest; override;
    destructor Destroy; override;
    procedure RunMemTest; override;
    class function GetMemTestName: string; override;
    class function GetMemTestDescription: string; override;
    class function GetCategory: TMemTestCategory; override;
  end;

implementation

uses
  bvDataTypes, System.SysUtils;

constructor TAddressSpaceCreepBenchLarge.CreateMemTest;
begin
  inherited;
end;

destructor TAddressSpaceCreepBenchLarge.Destroy;
begin
  inherited;
end;

class function TAddressSpaceCreepBenchLarge.GetMemTestDescription: string;
begin
  Result := 'Allocates and deallocates thousands of large pointers in a loop, '
    + 'checking that the MM address space usage does not grow unbounded.  '
    + 'MemTest submitted by Pierre le Riche.';
end;

class function TAddressSpaceCreepBenchLarge.GetMemTestName: string;
begin
  Result := 'Address space creep (larger blocks)';
end;

class function TAddressSpaceCreepBenchLarge.GetCategory: TMemTestCategory;
begin
  Result := bmSingleThreadAllocAndFree;
end;

procedure TAddressSpaceCreepBenchLarge.RunMemTest;
const
  Prime = 43;
var
  i, j: integer;
  LSize, LOffset: NativeInt;
  NextValue {, vTotal} : Int64;
begin
  {Call the inherited handler}
  inherited;
  NextValue := Prime;
  // vTotal := 0;
  {Allocate the pointers}
  for i := low(FPointers) to high(FPointers) do begin
    {Get an initial size}
    LSize := bvInt64ToNativeInt(1 + (MaxBlockSize + NextValue) mod MaxBlockSize);
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
      LSize := bvInt64ToInt(1 + (MaxBlockSize + NextValue) mod MaxBlockSize);
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

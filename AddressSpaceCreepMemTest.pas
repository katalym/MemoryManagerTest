unit AddressSpaceCreepMemTest;

interface

{$I MemoryManagerTest.inc}

uses
  MemTestClassUnit;

const
  // full debug mode is used to detect memory leaks - not for actual performance test
  // value is decreased to avoid Out of Memory in full debug mode
{$IFDEF FullDebug}
  NumPointers = 15000;
{$ELSE}
  NumPointers = 3000000;
{$ENDIF}
  // The maximum block size
  MaxBlockSize = 256;

type

  TAddressSpaceCreepBench = class(TMemTest)
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

const
  IterationsCount = 36;

constructor TAddressSpaceCreepBench.CreateMemTest;
begin
  inherited;
end;

destructor TAddressSpaceCreepBench.Destroy;
begin
  inherited;
end;

class function TAddressSpaceCreepBench.GetMemTestDescription: string;
begin
  Result := 'Allocates and deallocates millions of pointers in a loop, '
    + 'checking that the MM address space usage does not grow unbounded.  '
    + 'MemTest submitted by Pierre le Riche.';
end;

class function TAddressSpaceCreepBench.GetMemTestName: string;
begin
  Result := 'Address space creep';
end;

class function TAddressSpaceCreepBench.GetCategory: TMemTestCategory;
begin
  Result := bmSingleThreadAllocAndFree;
end;

procedure TAddressSpaceCreepBench.RunMemTest;
const
  Prime = 3;
var
  i, j, LSize: integer;
  NextValue: Int64;
begin
  // Call the inherited handler
  inherited;
  // Allocate the pointers
  NextValue := Prime;
  for i := 0 to high(FPointers) do
  begin
    // Get an initial size
    LSize := bvInt64ToInt(1 + (MaxBlockSize + NextValue) mod MaxBlockSize);
    Inc(NextValue, Prime);
    // Allocate the pointer
    GetMem(FPointers[i], LSize);
    // Touch the memory
    FPointers[i][0] := AnsiChar(byte(i));
    if LSize > 2 then
    begin
      FPointers[i][LSize - 1] := AnsiChar(byte(i));
    end;
  end;
  // Free and get new pointers in a loop
  for j := 1 to IterationsCount do
  begin
    for i := 0 to high(FPointers) do
    begin
      // Free the pointer
      FreeMem(FPointers[i]);
      FPointers[i] := nil;
      // Get the new size
      LSize := bvInt64ToInt(1 + (MaxBlockSize + NextValue) mod MaxBlockSize);
      Inc(NextValue, Prime);
      // Allocate the pointer
      GetMem(FPointers[i], LSize);
      // Touch the memory
      FPointers[i][0] := AnsiChar(byte(i));
      if LSize > 2 then
      begin
        FPointers[i][LSize - 1] := AnsiChar(byte(i));
      end;
    end;
  end;
  // What we end with should be close to the peak usage
  UpdateUsageStatistics;
  // Free the pointers
  for i := 0 to high(FPointers) do
  begin
    FreeMem(FPointers[i]);
    FPointers[i] := nil;
  end;
end;

end.

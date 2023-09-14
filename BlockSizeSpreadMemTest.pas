unit BlockSizeSpreadMemTest;

interface

{$I MemoryManagerTest.inc}

uses
  MemTestClassUnit, Math;

const
  {The maximum block size}
  MaxBlockSize = 25;

const
  // full debug mode is used to detect memory leaks - not for actual performance test
  // value is decreased to avoid Out of Memory in fuul debug mode
{$IFDEF FullDebug}
  IterationsCount = 5;
  NumPointers     = 30000;
{$ELSE}
  IterationsCount = 20;
  NumPointers     = 3000000;
{$ENDIF}

type

  TBlockSizeSpreadBench = class(TMemTest)
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

constructor TBlockSizeSpreadBench.CreateMemTest;
begin
  inherited;
end;

destructor TBlockSizeSpreadBench.Destroy;
begin
  inherited;
end;

class function TBlockSizeSpreadBench.GetMemTestDescription: string;
begin
  Result := 'Allocates millions of small objects, checking that the MM '
    + 'has a decent block size spread.  '
    + 'MemTest submitted by Pierre le Riche.';
end;

class function TBlockSizeSpreadBench.GetMemTestName: string;
begin
  Result := 'Block size spread';
end;

class function TBlockSizeSpreadBench.GetCategory: TMemTestCategory;
begin
  Result := bmSingleThreadAllocAndFree;
end;

procedure TBlockSizeSpreadBench.RunMemTest;
const
  Prime = 17;
var
  i, n, LSize: integer;
  NextValue: Int64;
begin
  {Call the inherited handler}
  inherited;
  NextValue := Prime;
  for n := 1 to IterationsCount do // loop added to have more than 1000 MTicks for this MemTest
  begin
    {Do the MemTest}
    for i := 0 to high(FPointers) do
    begin
      {Get the initial block size, assume object sizes are 4-byte aligned}
      LSize := bvInt64ToInt((1 + (MaxBlockSize + NextValue) mod NextValue) * 4);
      Inc(NextValue, Prime);
      GetMem(FPointers[i], LSize);
      FPointers[i][0] := #13;
      if LSize > 2 then
      begin
        FPointers[i][LSize - 1] := #13;
      end;
    end;
    {What we end with should be close to the peak usage}
    UpdateUsageStatistics;
    {Free the pointers}
    for i := 0 to high(FPointers) do
    begin
      FreeMem(FPointers[i]);
      FPointers[i] := nil;
    end;
  end;
end;

end.

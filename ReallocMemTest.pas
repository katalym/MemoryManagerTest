{A simple MemTest with lots of reallocmem calls}

unit ReallocMemTest;

interface

{$I MemoryManagerTest.inc}

uses
  MemTestClassUnit;

type
  PReallocMemMemTestBlockSizesArray = ^TReallocMemMemTestBlockSizesArray;
  PReallocMemMemTestPointerArray = ^TReallocMemMemTestPointerArray;

  TReallocMemMemTestPointerArray = packed array [0 .. MaxInt div SizeOf(Pointer) - 1] of Pointer;
  TReallocMemMemTestBlockSizesArray = packed array [0 .. MaxInt div SizeOf(Pointer) - 1] of Integer;

  TReallocBenchAbstract = class(TMemTest)
  protected
    BlockSizes: PReallocMemMemTestBlockSizesArray;
    Pointers: PReallocMemMemTestPointerArray;
  public
    constructor CreateMemTest; override;
    destructor Destroy; override;
    class function GetMemTestDescription: string; override;
    class function GetBlockSizeDelta: Integer; virtual; abstract;
    class function GetCategory: TMemTestCategory; override;
    class function GetIterationCount: Integer; virtual; abstract;
    class function GetNumPointers: Integer; virtual; abstract;
    procedure RunMemTest; override;
  end;

  TReallocBenchLarge = class(TReallocBenchAbstract)
    class function GetMemTestName: string; override;
    class function GetBlockSizeDelta: Integer; override;
    class function GetIterationCount: Integer; override;
    class function GetNumPointers: Integer; override;
  end;

  TReallocBenchMedium = class(TReallocBenchAbstract)
    class function GetMemTestName: string; override;
    class function GetBlockSizeDelta: Integer; override;
    class function GetIterationCount: Integer; override;
    class function GetNumPointers: Integer; override;
  end;

  TReallocBenchTiny = class(TReallocBenchAbstract)
    class function GetMemTestName: string; override;
    class function GetBlockSizeDelta: Integer; override;
    class function GetIterationCount: Integer; override;
    class function GetNumPointers: Integer; override;
  end;

implementation

uses
  bvDataTypes, System.SysUtils;

constructor TReallocBenchAbstract.CreateMemTest;
var
  np: Integer;
begin
  inherited;

  np := GetNumPointers;

  GetMem(Pointers, np * SizeOf(Pointer));
  {Clear all the pointers}
  FillChar(Pointers^, np * SizeOf(Pointer), 0);

  GetMem(BlockSizes, np * SizeOf(Integer));
  {Clear all the block sizes}
  FillChar(BlockSizes^, np * SizeOf(Integer), 0);
end;

destructor TReallocBenchAbstract.Destroy;
var
  np, i: Integer;
begin
  np := GetNumPointers;

  {Free all residual pointers}
  for i := 0 to np - 1 do
  begin
    System.ReallocMem(Pointers^[i], 0);
  end;

  FreeMem(Pointers, np * SizeOf(Pointer));
  Pointers := nil;
  FreeMem(BlockSizes, np * SizeOf(Integer));
  BlockSizes := nil;

  inherited;
end;

class function TReallocBenchAbstract.GetMemTestDescription: string;
begin
  Result := 'Allocates lots of pointers of arbitrary sizes and continues to '
    + 'grow/shrink them arbitrarily in a loop.  '
    + 'MemTest submitted by Pierre le Riche.';
end;

class function TReallocBenchAbstract.GetCategory: TMemTestCategory;
begin
  Result := bmSingleThreadRealloc;
end;

procedure TReallocBenchAbstract.RunMemTest;
const
  Prime = 10513;
var
  sz, i, FIterCount, NumPointers, BlockSizeDelta, MaxBlockSize, MinBlockSize: Integer;
  CurValue, LPointerNumber: Int64;
  P: PAnsiChar;
begin
  {Call the inherited handler}
  inherited;
  MaxBlockSize := 0;
  MinBlockSize := MaxInt;
  CurValue := Prime;
  NumPointers := GetNumPointers;
  BlockSizeDelta := GetBlockSizeDelta;
  {Do the MemTest}
  FIterCount := GetIterationCount;
  for i := 1 to FIterCount do
  begin
    {Get an arbitarry pointer number}
    LPointerNumber := CurValue mod NumPointers;
    Inc(CurValue, Prime);
    {Adjust the current block size up or down by up to BlockSizeDelta}
    BlockSizes^[LPointerNumber] := bvInt64ToInt(abs(BlockSizes^[LPointerNumber] + (CurValue mod BlockSizeDelta) - (BlockSizeDelta shr 1) - ((i and 7) mod BlockSizeDelta)));
    Inc(CurValue, Prime);
    {Reallocate the pointer}
    if MaxBlockSize < BlockSizes^[LPointerNumber] then
      MaxBlockSize := BlockSizes^[LPointerNumber];
    if (BlockSizes^[LPointerNumber] > 0) and (MinBlockSize > BlockSizes^[LPointerNumber]) then
      MinBlockSize := BlockSizes^[LPointerNumber];
    System.ReallocMem(Pointers^[LPointerNumber], BlockSizes^[LPointerNumber]);
    {Touch the memory}
    sz := BlockSizes^[LPointerNumber];
    if sz > 0 then
    begin
      P := Pointers^[LPointerNumber];
      P[0] := #1;
      if sz > 1 then
      begin
        P[sz - 1] := #2;
      end;
    end;
  end;
  {What we end with should be close to the peak usage}
  UpdateUsageStatistics;
end;

class function TReallocBenchMedium.GetMemTestName: string;
begin
  Result := 'ReallocMem Medium (1-4039b)';
end;

class function TReallocBenchMedium.GetBlockSizeDelta: Integer;
begin
  {The maximum change in a block size per iteration}
  Result := 2039 {prime};
end;

class function TReallocBenchMedium.GetIterationCount: Integer;
begin
  // full debug mode is used to detect memory leaks - not for actual performance test
  // value is decreased to avoid Out of Memory in fuul debug mode
{$IFDEF FullDebug}
  Result := 250000;
{$ELSE}
  Result := 25000000;
{$ENDIF}
end;

class function TReallocBenchMedium.GetNumPointers: Integer;
begin
  // full debug mode is used to detect memory leaks - not for actual performance test
  // value is decreased to avoid Out of Memory in fuul debug mode
{$IFDEF FullDebug}
  Result := 5 {prime};
{$ELSE}
  Result := 521 {prime};
{$ENDIF}
end;

class function TReallocBenchTiny.GetMemTestName: string;
begin
  Result := 'ReallocMem Small (1-555b)';
end;

class function TReallocBenchTiny.GetBlockSizeDelta: Integer;
begin
  {The maximum change in a block size per iteration}
  Result := 257 {prime};
end;

class function TReallocBenchTiny.GetIterationCount: Integer;
begin
  // full debug mode is used to detect memory leaks - not for actual performance test
  // value is decreased to avoid Out of Memory in fuul debug mode
{$IFDEF FullDebug}
  Result := 300000;
{$ELSE}
  Result := 30000000;
{$ENDIF}
end;

class function TReallocBenchTiny.GetNumPointers: Integer;
begin
  // full debug mode is used to detect memory leaks - not for actual performance test
  // value is decreased to avoid Out of Memory in fuul debug mode
{$IFDEF FullDebug}
  Result := 5 {prime}; // to fit in the cache better
{$ELSE}
  Result := 521 {prime}; // to fit in the cache better
{$ENDIF}
end;

class function TReallocBenchLarge.GetMemTestName: string;
begin
  Result := 'ReallocMem Large (1-952224b)';
end;

class function TReallocBenchLarge.GetBlockSizeDelta: Integer;
begin
  Result := 555029 {prime};
end;

class function TReallocBenchLarge.GetIterationCount: Integer;
begin
  // full debug mode is used to detect memory leaks - not for actual performance test
  // value is decreased to avoid Out of Memory in fuul debug mode
{$IFDEF FullDebug}
  Result := 2650;
{$ELSE}
  Result := 265000;
{$ENDIF}
end;

class function TReallocBenchLarge.GetNumPointers: Integer;
begin
  // full debug mode is used to detect memory leaks - not for actual performance test
  // value is decreased to avoid Out of Memory in fuul debug mode
{$IFDEF FullDebug}
  Result := 5 {prime};
{$ELSE}
  Result := 2153 {prime};
{$ENDIF}
end;

end.

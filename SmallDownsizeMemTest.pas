unit SmallDownsizeMemTest;

interface

{$I MemoryManagerTest.inc}

uses
  MemTestClassUnit, Math;

type

  TSmallDownsizeBenchAbstract = class(TMemTest)
  protected
    FPointers: array of PAnsiChar;
  public
    constructor CreateMemTest; override;
    destructor Destroy; override;
    class function GetBlockSizeBytes: Integer; virtual; abstract;
    class function GetCategory: TMemTestCategory; override;
    class function GetIterationsCount: Integer; virtual; abstract;
    function GetNumPointers: Integer; virtual;
    procedure RunMemTest; override;
  end;

  TTinyDownsizeBench = class(TSmallDownsizeBenchAbstract)
    class function GetMemTestDescription: string; override;
    class function GetMemTestName: string; override;
    class function GetBlockSizeBytes: Integer; override;
    class function GetIterationsCount: Integer; override;
    function GetNumPointers: Integer; override;
  end;

  TVerySmallDownsizeBench = class(TSmallDownsizeBenchAbstract)
    class function GetMemTestDescription: string; override;
    class function GetMemTestName: string; override;
    class function GetBlockSizeBytes: Integer; override;
    class function GetIterationsCount: Integer; override;
    function GetNumPointers: Integer; override;
  end;

implementation

uses
  bvDataTypes, System.SysUtils;

constructor TSmallDownsizeBenchAbstract.CreateMemTest;
begin
  inherited;
  SetLength(FPointers, GetNumPointers);
end;

destructor TSmallDownsizeBenchAbstract.Destroy;
begin
  SetLength(FPointers, 0);
  inherited;
end;

class function TSmallDownsizeBenchAbstract.GetCategory: TMemTestCategory;
begin
  Result := bmSingleThreadRealloc;
end;

function TSmallDownsizeBenchAbstract.GetNumPointers: Integer;
begin
  Result := 900000; // OK
end;

procedure TSmallDownsizeBenchAbstract.RunMemTest;
const
  Prime = 41;
var
  i, j, LSize, IterationsCount, MaxBlockSize: Integer;
  CurValue {, vTotal} : Int64;
  k: Integer;
begin
  {Call the inherited handler}
  inherited;
  CurValue := Prime;
  {Do the MemTest}
  IterationsCount := GetIterationsCount;
  MaxBlockSize := GetBlockSizeBytes;
  // vTotal := 0;
  for k := 1 to IterationsCount do
  begin
    for i := bvNativeIntToInt(low(FPointers)) to bvNativeIntToInt(high(FPointers)) do
    begin
      {Get the initial block size}
      LSize := bvInt64ToInt(MaxBlockSize + (CurValue mod (3 * MaxBlockSize)));
      // if vTotal + LSize > 1600000000 then
      // begin
      // vTotal := vTotal;
      // Break;
      // end;
      Inc(CurValue, Prime);
      GetMem(FPointers[i], LSize);
      // Inc(vTotal, LSize);
      FPointers[i][0] := #13;
      if LSize > 5 then
        FPointers[i][LSize - 1] := #13;
      {Reallocate it a few times}
      for j := 1 to 5 do
      begin
        LSize := bvInt64ToInt(Max(1, LSize - (CurValue mod MaxBlockSize)));
        Inc(CurValue, Prime);
        ReallocMem(FPointers[i], LSize);
        FPointers[i][0] := #13;
        if LSize > 5 then
          FPointers[i][LSize - 1] := #13;
      end;
    end;
    for i := bvNativeIntToInt(low(FPointers)) to bvNativeIntToInt(high(FPointers)) do
    begin
      FreeMem(FPointers[i]);
      FPointers[i] := nil;
    end;
  end;
  {What we end with should be close to the peak usage}
  UpdateUsageStatistics;
  {Free the pointers}
end;

class function TTinyDownsizeBench.GetMemTestDescription: string;
begin
  Result := 'Allocates a tiny block (up to 64 bytes) and immediately resizes it to a smaller size. This checks '
    + ' that the block downsizing behaviour of the MM is acceptable.  '
    + 'MemTest submitted by Pierre le Riche.';
end;

class function TTinyDownsizeBench.GetMemTestName: string;
begin
  Result := 'Tiny downsize';
end;

class function TTinyDownsizeBench.GetBlockSizeBytes: Integer;
begin
  Result := 64;
end;

class function TTinyDownsizeBench.GetIterationsCount: Integer;
begin
{$IFDEF FullDebug}
  Result := 1;
{$ELSE}
  Result := 15;
{$ENDIF}
end;

function TTinyDownsizeBench.GetNumPointers: Integer;
begin
{$IFDEF FullDebug}
  Result := 90000;
{$ELSE}
  Result := 900000;
{$ENDIF}
end;

class function TVerySmallDownsizeBench.GetMemTestDescription: string;
begin
  Result := 'Allocates a very small block (up to 200 bytes) and immediately resizes it to a smaller size. This checks '
    + ' that the block downsizing behaviour of the MM is acceptable.  '
    + 'MemTest submitted by Pierre le Riche.';
end;

class function TVerySmallDownsizeBench.GetMemTestName: string;
begin
  Result := 'VerySmall downsize';
end;

class function TVerySmallDownsizeBench.GetBlockSizeBytes: Integer;
begin
  Result := 200;
end;

class function TVerySmallDownsizeBench.GetIterationsCount: Integer;
begin
  Result := 5;
end;

function TVerySmallDownsizeBench.GetNumPointers: Integer;
begin
  Result := 400000; // OK
end;

end.

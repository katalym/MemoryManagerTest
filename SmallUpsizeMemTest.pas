unit SmallUpsizeBenchmark;

interface

{$I MemoryManagerTest.inc}

uses
  BenchmarkClassUnit;

const
{$IFDEF FullDebug}
  NumPointers     = 8000;
  IterationsCount = 5;
{$ELSE}
  NumPointers     = 2000000;
  IterationsCount = 15;
{$ENDIF}
  {The maximum block size}
  MaxBlockSize = 32;

type

  TSmallUpsizeBench = class(TMMBenchmark)
  protected
    FPointers: array [0 .. NumPointers - 1] of PAnsiChar;
  public
    constructor CreateBenchmark; override;
    destructor Destroy; override;
    class function GetBenchmarkDescription: string; override;
    class function GetBenchmarkName: string; override;
    class function GetCategory: TBenchmarkCategory; override;
    procedure RunBenchmark; override;
  end;

implementation

uses
  bvDataTypes, System.SysUtils;

constructor TSmallUpsizeBench.CreateBenchmark;
begin
  inherited;
end;

destructor TSmallUpsizeBench.Destroy;
begin
  inherited;
end;

class function TSmallUpsizeBench.GetBenchmarkDescription: string;
begin
  Result := 'Allocates a small block and immediately resizes it to a slightly bigger size. This checks '
    + ' that the block upsizing behaviour of the MM is acceptable.  '
    + 'Benchmark submitted by Pierre le Riche.';
end;

class function TSmallUpsizeBench.GetBenchmarkName: string;
begin
  Result := 'Small upsize';
end;

class function TSmallUpsizeBench.GetCategory: TBenchmarkCategory;
begin
  Result := bmSingleThreadRealloc;
end;

procedure TSmallUpsizeBench.RunBenchmark;
const
  Prime = 43;
var
  i, j, k, LSize: integer;
  CurValue: Int64;
begin
  {Call the inherited handler}
  inherited;
  CurValue := Prime;
  {Do the benchmark}
  for k := 1 to IterationsCount do
  begin
    for i := low(FPointers) to high(FPointers) do
    begin
      FPointers[i] := nil;
    end;
    for i := low(FPointers) to high(FPointers) do
    begin
      {Get the initial block size}
      LSize := bvInt64ToInt(1 + (CurValue mod MaxBlockSize));
      Inc(CurValue, Prime);
      ReallocMem(FPointers[i], LSize);
      FPointers[i][0] := #13;
      if LSize > 2 then
      begin
        FPointers[i][LSize - 1] := #13;
      end;
      {Reallocate it a few times}
      for j := 1 to 3 do
      begin
        LSize := bvInt64ToInt(LSize + (CurValue mod MaxBlockSize));
        Inc(CurValue, Prime);
        ReallocMem(FPointers[i], LSize);
        if LSize > 2 then
        begin
          FPointers[i][LSize - 1] := #13;
        end;
      end;
    end;
    {Free the pointers}
    for i := low(FPointers) to high(FPointers) do
    begin
      ReallocMem(FPointers[i], 0);
    end;
  end;
  {What we end with should be close to the peak usage}
  UpdateUsageStatistics;
end;

end.

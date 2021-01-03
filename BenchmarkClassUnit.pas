unit BenchmarkClassUnit;

interface

{$I MemoryManagerTest.inc}

uses
  Windows, System.Generics.Collections;

type
  TBenchmarkCategory = (
    bmSingleThreadRealloc, bmMultiThreadRealloc, bmSingleThreadAllocAndFree,
    bmMultiThreadAllocAndFree, bmSingleThreadReplay, bmMultiThreadReplay,
    bmMemoryAccessSpeed);
  TBenchmarkCategorySet = set of TBenchmarkCategory;

  TMMBenchmark = class(TObject)
  protected
    {Indicates whether the benchmark can be run - or if a problem was
      discovered, possibly during create}
    FCanRunBenchmark: Boolean;
    // The peak address space usage measured
    FPeakAddressSpaceUsage: Int64;
    // Gets the memory overhead of the benchmark that should be subtracted
    function GetBenchmarkOverhead: NativeUInt; virtual;
  public
    FExcludeThisCPUUsage: Int64;
    FExcludeThisTicks: Cardinal;
    constructor CreateBenchmark; virtual;
    // A description for the benchmark
    class function GetBenchmarkDescription: string; virtual;
    // The name of the benchmark
    class function GetBenchmarkName: string; virtual;
    // Benchmark Category
    class function GetCategory: TBenchmarkCategory; virtual;
    class function IsThreadedSpecial: Boolean; virtual;
    procedure PrepareBenchmarkForRun(const aUsageFileToReplay: string =''); virtual;
    // Resets the peak usage measurement
    procedure ResetUsageStatistics;
    // The tests - should return true if implemented
    procedure RunBenchmark; virtual;
    // Should this benchmark be run by default?
    class function RunByDefault: Boolean; virtual;
    {Measures the address space usage and updates the peak value if the current
      usage is greater}
    procedure UpdateUsageStatistics;
    {Indicates whether the benchmark can be run - or if a problem was
      discovered, possibly during create}
    property CanRunBenchmark: Boolean read FCanRunBenchmark;
    // The peak usage measured since the last reset
    property PeakAddressSpaceUsage: Int64 read FPeakAddressSpaceUsage;
  end;

  TMMBenchmarkClass = class of TMMBenchmark;

const
  // Benchmark category names
  BenchmarkCategoryNames: array [TBenchmarkCategory] of string = (
    'Single Thread ReallocMem', 'Multi-threaded ReallocMem',
    'Single Thread GetMem and FreeMem',
    'Multi-threaded GetMem and FreeMem',
    'Single Thread Replay',
    'Multi-threaded Replay',
    'Memory Access Speed');

  AllCategories: TBenchmarkCategorySet = [low(TBenchmarkCategory) .. high(TBenchmarkCategory)];

var
  gUsageReplayFileName: string;
  // All the benchmarks
  Benchmarks: TList<TMMBenchmarkClass>;

  // Get the list of benchmarks
procedure DefineBenchmarks;

implementation

uses
  FragmentationTestUnit, ReallocMemBenchmark, DownsizeTestUnit,
  SmallUpsizeBenchmark, AddressSpaceCreepBenchmark,
  ArrayUpsizeSingleThread, BlockSizeSpreadBenchmark,
  LargeBlockSpreadBenchmark, NexusDBBenchmarkUnit,
  RawPerformanceMultiThread, RawPerformanceSingleThread,
  ReplayBenchmarkUnit, SmallDownsizeBenchmark, StringThreadTestUnit,
  WildThreadsBenchmarkUnit, AddressSpaceCreepBenchmarkLarge,
  DoubleFPBenchmark1Unit, DoubleFPBenchmark2Unit, DoubleFPBenchmark3Unit,
  MoveBenchmark1Unit, MoveBenchmark2Unit,
  SingleFPBenchmark1Unit, SingleFPBenchmark2Unit,
  LinkedListBenchmark, BenchmarkUtilities, MemFreeBenchmark1Unit,
  MemFreeBenchmark2Unit, FillCharMultiThreadBenchmark1Unit,
  SortIntArrayBenchmark1Unit, SortExtendedArrayBenchmark1Unit,
  MultiThreadedAllocAndFree, MultiThreadedReallocate,
  SingleThreadedAllocAndFree, SingleThreadedReallocate,
  SortIntArrayBenchmark2Unit, SortExtendedArrayBenchmark2Unit,
  SingleThreadedAllocMem, SingleThreadedTinyReloc, System.Generics.Defaults, System.SysUtils;

constructor TMMBenchmark.CreateBenchmark;
begin
  inherited;
  FCanRunBenchmark := True;
  FExcludeThisCPUUsage := 0;
  FExcludeThisTicks := 0;
end;

class function TMMBenchmark.GetBenchmarkDescription: string;
begin
  Result := '';
end;

class function TMMBenchmark.GetBenchmarkName: string;
begin
  Result := '(Unnamed)';
end;

function TMMBenchmark.GetBenchmarkOverhead: NativeUInt;
begin
  // Return the address space usage on startup
  Result := InitialAddressSpaceUsed;
end;

class function TMMBenchmark.GetCategory: TBenchmarkCategory;
begin
  Result := bmMemoryAccessSpeed;
end;

class function TMMBenchmark.IsThreadedSpecial: Boolean;
begin
  Result := False;
end;

procedure TMMBenchmark.PrepareBenchmarkForRun(const aUsageFileToReplay: string);
begin

end;

procedure TMMBenchmark.ResetUsageStatistics;
begin
  FPeakAddressSpaceUsage := 0;
end;

procedure TMMBenchmark.RunBenchmark;
begin
  // Reset the peak usage statistic
  ResetUsageStatistics;
end;

class function TMMBenchmark.RunByDefault: Boolean;
begin
  Result := True;
end;

procedure TMMBenchmark.UpdateUsageStatistics;
var
  LCurrentUsage, LBenchmarkOverhead: NativeUInt;
begin
  {Get the usage less the usage at program startup (before the MM was started).
    The assumption here is that any static lookup tables used by the MM will be
    small.}
  LCurrentUsage := GetAddressSpaceUsed;
  LBenchmarkOverhead := GetBenchmarkOverhead;
  if LBenchmarkOverhead >= LCurrentUsage then
    LCurrentUsage := 0
  else
    LCurrentUsage := LCurrentUsage - LBenchmarkOverhead;
  // Update the peak usage
  if LCurrentUsage > FPeakAddressSpaceUsage then
    FPeakAddressSpaceUsage := LCurrentUsage;
end;

procedure AddBenchMark(ABenchmarkClass: TMMBenchmarkClass);
begin
  if not Benchmarks.Contains(ABenchmarkClass) then
    Benchmarks.Add(ABenchmarkClass);
end;

procedure DefineBenchmarks;
begin
  // first all single-thread benchmarks that execute in the application's main thread...
  AddBenchMark(TFragmentationTest);
  AddBenchMark(TReallocBenchTiny);
  AddBenchMark(TReallocBenchMedium);
  AddBenchMark(TReallocBenchLarge);
  AddBenchMark(TDownsizeTest);
  AddBenchMark(TSmallUpsizeBench);
  AddBenchMark(TTinyDownsizeBench);
  AddBenchMark(TVerySmallDownsizeBench);
  AddBenchMark(TBlockSizeSpreadBench);
  AddBenchMark(TRawPerformanceSingleThread);
  AddBenchMark(TAddressSpaceCreepBench);
  AddBenchMark(TLargeBlockSpreadBench);
  AddBenchMark(TArrayUpsizeSingleThread);
  AddBenchMark(TAddressSpaceCreepBenchLarge);
  AddBenchMark(TSingleThreadReallocateVariousBlocksBenchmark);
  AddBenchMark(TSingleThreadedTinyRelocBenchmark);
  AddBenchMark(TSingleThreadAllocateAndFreeBenchmark);
  // ...then all the benchmarks that create TThread descendants
  AddBenchMark(TSingleFPThreads);
  AddBenchMark(TSingleFPThreads2);
  AddBenchMark(TDoubleFPThreads1);
  AddBenchMark(TDoubleFPThreads2);
  AddBenchMark(TDoubleFPThreads3);
  AddBenchMark(TMoveThreads1);
  AddBenchMark(TMoveThreads2);
  AddBenchMark(TFillCharThreads);
  AddBenchMark(TSortIntArrayThreads);
  AddBenchMark(TStandardSortExtendedArrayThreads);
  AddBenchMark(TMemFreeThreads1);
  AddBenchMark(TMemFreeThreads2);
  AddBenchMark(TLinkedListBench);
  AddBenchMark(TMultiThreadAllocateAndFreeBenchmark2);
  AddBenchMark(TMultiThreadAllocateAndFreeBenchmark4);
  AddBenchMark(TMultiThreadAllocateAndFreeBenchmark8);
  AddBenchMark(TMultiThreadAllocateAndFreeBenchmark12);
  AddBenchMark(TMultiThreadAllocateAndFreeBenchmark16);
  AddBenchMark(TMultiThreadAllocateAndFreeBenchmark31);
  AddBenchMark(TMultiThreadAllocateAndFreeBenchmark64);
  AddBenchMark(TMultiThreadReallocateBenchmark2);
  AddBenchMark(TMultiThreadReallocateBenchmark4);
  AddBenchMark(TMultiThreadReallocateBenchmark8);
  AddBenchMark(TMultiThreadReallocateBenchmark12);
  AddBenchMark(TMultiThreadReallocateBenchmark16);
  AddBenchMark(TMultiThreadReallocateBenchmark31);
  AddBenchMark(TMultiThreadReallocateBenchmark64);
  AddBenchMark(TQuickSortIntArrayThreads);
  AddBenchMark(TQuickSortExtendedArrayThreads);
  AddBenchMark(TNexusBenchmark1Thread);
  AddBenchMark(TNexusBenchmark2Threads);
  AddBenchMark(TNexusBenchmark4Threads);
  AddBenchMark(TNexusBenchmark8Threads);
  AddBenchMark(TNexusBenchmark12Threads);
  AddBenchMark(TNexusBenchmark16Threads);
  AddBenchMark(TNexusBenchmark31Threads);
  AddBenchMark(TNexusBenchmark64Threads);
{$IFDEF NEXUS_UP_TO_512}
  AddBenchMark(TNexusBenchmark128Threads);
  AddBenchMark(TNexusBenchmark256Threads);
  AddBenchMark(TNexusBenchmark512Threads);
{$ENDIF}
  AddBenchMark(TWildThreads);
  AddBenchMark(TRawPerformanceMultiThread2);
  AddBenchMark(TRawPerformanceMultiThread4);
  AddBenchMark(TRawPerformanceMultiThread8);
  AddBenchMark(TRawPerformanceMultiThread12);
  AddBenchMark(TRawPerformanceMultiThread16);
  AddBenchMark(TRawPerformanceMultiThread31);
  AddBenchMark(TRawPerformanceMultiThread64);
  AddBenchMark(TManyThreadsTest);
  AddBenchMark(TStringThreadTest2);
  AddBenchMark(TStringThreadTest4);
  AddBenchMark(TStringThreadTest8);
  AddBenchMark(TStringThreadTest12);
  AddBenchMark(TStringThreadTest16);
  AddBenchMark(TStringThreadTest31);
  AddBenchMark(TStringThreadTest64);
  // End of benchmark list
  AddBenchMark(TMultiThreadReplayBenchmark);
  AddBenchMark(TReplayBenchmark); // not active by default, added so you can run your own replays

  // now sort them by name

  Benchmarks.Sort(
    TComparer<TMMBenchmarkClass>.Construct(
    function(const A, B: TMMBenchmarkClass): Integer
    begin
      Result := System.SysUtils.CompareText(A.GetBenchmarkName, B.GetBenchmarkName);
    end));

end;

initialization

Benchmarks := TList<TMMBenchmarkClass>.Create;
// Get the list of benchmarks
DefineBenchmarks;

finalization

FreeAndNil(Benchmarks);

end.

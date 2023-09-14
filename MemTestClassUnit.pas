unit MemTestClassUnit;

interface

{$I MemoryManagerTest.inc}

uses
  Windows, System.Generics.Collections;

type
  TMemTestCategory = (
    bmSingleThreadRealloc, bmMultiThreadRealloc, bmSingleThreadAllocAndFree,
    bmMultiThreadAllocAndFree, bmSingleThreadReplay, bmMultiThreadReplay,
    bmMemoryAccessSpeed);
  TMemTestCategorySet = set of TMemTestCategory;

  TMemTest = class(TObject)
  protected
    {Indicates whether the MemTest can be run - or if a problem was
      discovered, possibly during create}
    FCanRunMemTest: Boolean;
    // The peak address space usage measured
    FPeakAddressSpaceUsage: NativeUInt;
    // Gets the memory overhead of the MemTest that should be subtracted
    function GetMemTestOverhead: NativeUInt; virtual;
  public
    FExcludeThisCPUUsage: Int64;
    FExcludeThisTicks: Cardinal;
    constructor CreateMemTest; virtual;
    // A description for the MemTest
    class function GetMemTestDescription: string; virtual;
    // The name of the MemTest
    class function GetMemTestName: string; virtual;
    // MemTest Category
    class function GetCategory: TMemTestCategory; virtual;
    class function IsThreadedSpecial: Boolean; virtual;
    procedure PrepareMemTestForRun(const aUsageFileToReplay: string =''); virtual;
    // Resets the peak usage measurement
    procedure ResetUsageStatistics;
    // The tests - should return true if implemented
    procedure RunMemTest; virtual;
    // Should this MemTest be run by default?
    class function RunByDefault: Boolean; virtual;
    {Measures the address space usage and updates the peak value if the current
      usage is greater}
    procedure UpdateUsageStatistics;
    {Indicates whether the MemTest can be run - or if a problem was
      discovered, possibly during create}
    property CanRunMemTest: Boolean read FCanRunMemTest;
    // The peak usage measured since the last reset
    property PeakAddressSpaceUsage: NativeUInt read FPeakAddressSpaceUsage;
  end;

  TMemTestClass = class of TMemTest;

const
  // MemTest category names
  MemTestCategoryNames: array [TMemTestCategory] of string = (
    'Single Thread ReallocMem', 'Multi-threaded ReallocMem',
    'Single Thread GetMem and FreeMem',
    'Multi-threaded GetMem and FreeMem',
    'Single Thread Replay',
    'Multi-threaded Replay',
    'Memory Access Speed');

  AllCategories: TMemTestCategorySet = [low(TMemTestCategory) .. high(TMemTestCategory)];

var
  gUsageReplayFileName: string;
  // All the MemTests
  MemTests: TList<TMemTestClass>;

  // Get the list of MemTests
procedure DefineMemTests;

implementation

uses
  FragmentationTestUnit, ReallocMemTest, DownsizeTestUnit,
  SmallUpsizeMemTest, AddressSpaceCreepMemTest,
  ArrayUpsizeSingleThread, BlockSizeSpreadMemTest,
  LargeBlockSpreadMemTest, NexusDBMemTestUnit,
  RawPerformanceMultiThread, RawPerformanceSingleThread,
  ReplayMemTestUnit, SmallDownsizeMemTest, StringThreadTestUnit,
  WildThreadsMemTestUnit, AddressSpaceCreepMemTestLarge,
  DoubleFPMemTest1Unit, DoubleFPMemTest2Unit, DoubleFPMemTest3Unit,
  MoveMemTest1Unit, MoveMemTest2Unit,
  SingleFPMemTest1Unit, SingleFPMemTest2Unit,
  LinkedListMemTest, MemTestUtilities, MemFreeMemTest1Unit,
  MemFreeMemTest2Unit, FillCharMultiThreadMemTest1Unit,
  SortIntArrayMemTest1Unit, SortExtendedArrayMemTest1Unit,
  MultiThreadedAllocAndFree, MultiThreadedReallocate,
  SingleThreadedAllocAndFree, SingleThreadedReallocate,
  SortIntArrayMemTest2Unit, SortExtendedArrayMemTest2Unit,
  SingleThreadedAllocMem, SingleThreadedTinyReloc, System.Generics.Defaults, System.SysUtils;

constructor TMemTest.CreateMemTest;
begin
  inherited;
  FCanRunMemTest := True;
  FExcludeThisCPUUsage := 0;
  FExcludeThisTicks := 0;
end;

class function TMemTest.GetMemTestDescription: string;
begin
  Result := '';
end;

class function TMemTest.GetMemTestName: string;
begin
  Result := '(Unnamed)';
end;

function TMemTest.GetMemTestOverhead: NativeUInt;
begin
  // Return the address space usage on startup
  Result := InitialAddressSpaceUsed;
end;

class function TMemTest.GetCategory: TMemTestCategory;
begin
  Result := bmMemoryAccessSpeed;
end;

class function TMemTest.IsThreadedSpecial: Boolean;
begin
  Result := False;
end;

procedure TMemTest.PrepareMemTestForRun(const aUsageFileToReplay: string);
begin

end;

procedure TMemTest.ResetUsageStatistics;
begin
  FPeakAddressSpaceUsage := 0;
end;

procedure TMemTest.RunMemTest;
begin
  // Reset the peak usage statistic
  ResetUsageStatistics;
end;

class function TMemTest.RunByDefault: Boolean;
begin
  Result := True;
end;

procedure TMemTest.UpdateUsageStatistics;
var
  LCurrentUsage, LMemTestOverhead: NativeUInt;
begin
  {Get the usage less the usage at program startup (before the MM was started).
    The assumption here is that any static lookup tables used by the MM will be
    small.}
  LCurrentUsage := GetAddressSpaceUsed;
  LMemTestOverhead := GetMemTestOverhead;
  if LMemTestOverhead >= LCurrentUsage then
    LCurrentUsage := 0
  else
    LCurrentUsage := LCurrentUsage - LMemTestOverhead;
  // Update the peak usage
  if LCurrentUsage > FPeakAddressSpaceUsage then
    FPeakAddressSpaceUsage := LCurrentUsage;
end;

procedure AddMemTest(AMemTestClass: TMemTestClass);
begin
  if not MemTests.Contains(AMemTestClass) then
    MemTests.Add(AMemTestClass);
end;

procedure DefineMemTests;
begin
  // first all single-thread MemTests that execute in the application's main thread...
  AddMemTest(TFragmentationTest);
  AddMemTest(TReallocBenchTiny);
  AddMemTest(TReallocBenchMedium);
  AddMemTest(TReallocBenchLarge);
  AddMemTest(TDownsizeTest);
  AddMemTest(TSmallUpsizeBench);
  AddMemTest(TTinyDownsizeBench);
  AddMemTest(TVerySmallDownsizeBench);
  AddMemTest(TBlockSizeSpreadBench);
  AddMemTest(TRawPerformanceSingleThread);
  AddMemTest(TAddressSpaceCreepBench);
  AddMemTest(TLargeBlockSpreadBench);
  AddMemTest(TArrayUpsizeSingleThread);
  AddMemTest(TAddressSpaceCreepBenchLarge);
  AddMemTest(TSingleThreadReallocateVariousBlocksMemTest);
  AddMemTest(TSingleThreadedTinyRelocMemTest);
  AddMemTest(TSingleThreadAllocateAndFreeMemTest);
  // ...then all the MemTests that create TThread descendants
  AddMemTest(TSingleFPThreads);
  AddMemTest(TSingleFPThreads2);
  AddMemTest(TDoubleFPThreads1);
  AddMemTest(TDoubleFPThreads2);
  AddMemTest(TDoubleFPThreads3);
  AddMemTest(TMoveThreads1);
  AddMemTest(TMoveThreads2);
  AddMemTest(TFillCharThreads);
  AddMemTest(TSortIntArrayThreads);
  AddMemTest(TStandardSortExtendedArrayThreads);
  AddMemTest(TMemFreeThreads1);
  AddMemTest(TMemFreeThreads2);
  AddMemTest(TLinkedListBench);
  AddMemTest(TMultiThreadAllocateAndFreeMemTest2);
  AddMemTest(TMultiThreadAllocateAndFreeMemTest4);
  AddMemTest(TMultiThreadAllocateAndFreeMemTest8);
  AddMemTest(TMultiThreadAllocateAndFreeMemTest12);
  AddMemTest(TMultiThreadAllocateAndFreeMemTest16);
  AddMemTest(TMultiThreadAllocateAndFreeMemTest31);
  AddMemTest(TMultiThreadAllocateAndFreeMemTest64);
  AddMemTest(TMultiThreadReallocateMemTest2);
  AddMemTest(TMultiThreadReallocateMemTest4);
  AddMemTest(TMultiThreadReallocateMemTest8);
  AddMemTest(TMultiThreadReallocateMemTest12);
  AddMemTest(TMultiThreadReallocateMemTest16);
  AddMemTest(TMultiThreadReallocateMemTest31);
  AddMemTest(TMultiThreadReallocateMemTest64);
  AddMemTest(TQuickSortIntArrayThreads);
  AddMemTest(TQuickSortExtendedArrayThreads);
  AddMemTest(TNexusMemTest1Thread);
  AddMemTest(TNexusMemTest2Threads);
  AddMemTest(TNexusMemTest4Threads);
  AddMemTest(TNexusMemTest8Threads);
  AddMemTest(TNexusMemTest12Threads);
  AddMemTest(TNexusMemTest16Threads);
  AddMemTest(TNexusMemTest31Threads);
  AddMemTest(TNexusMemTest64Threads);
{$IFDEF NEXUS_UP_TO_512}
  AddMemTest(TNexusMemTest128Threads);
  AddMemTest(TNexusMemTest256Threads);
  AddMemTest(TNexusMemTest512Threads);
{$ENDIF}
  AddMemTest(TWildThreads);
  AddMemTest(TRawPerformanceMultiThread2);
  AddMemTest(TRawPerformanceMultiThread4);
  AddMemTest(TRawPerformanceMultiThread8);
  AddMemTest(TRawPerformanceMultiThread12);
  AddMemTest(TRawPerformanceMultiThread16);
  AddMemTest(TRawPerformanceMultiThread31);
  AddMemTest(TRawPerformanceMultiThread64);
  AddMemTest(TManyThreadsTest);
  AddMemTest(TStringThreadTest2);
  AddMemTest(TStringThreadTest4);
  AddMemTest(TStringThreadTest8);
  AddMemTest(TStringThreadTest12);
  AddMemTest(TStringThreadTest16);
  AddMemTest(TStringThreadTest31);
  AddMemTest(TStringThreadTest64);
  // End of MemTest list
  AddMemTest(TMultiThreadReplayMemTest);
  AddMemTest(TReplayMemTest); // not active by default, added so you can run your own replays

  // now sort them by name

  MemTests.Sort(
    TComparer<TMemTestClass>.Construct(
    function(const A, B: TMemTestClass): Integer
    begin
      Result := System.SysUtils.CompareText(A.GetMemTestName, B.GetMemTestName);
    end));

end;

initialization

MemTests := TList<TMemTestClass>.Create;
// Get the list of MemTests
DefineMemTests;

finalization

FreeAndNil(MemTests);

end.

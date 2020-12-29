program MemoryManagerTest;

{$I MemoryManagerTest.inc}
{$R *.res}

uses
{$IFDEF MM_DEFAULT}
  // use default Delphi memory manager
{$ENDIF}
{$IFDEF MM_TCMALLOC}
  tcmalloc in 'TCMalloc/tcmalloc.pas',
{$ENDIF}
{$IFDEF MM_SCALEMM2}
  SCALEMM2 in 'ScaleMM2/ScaleMM2.pas',
  smmDump in 'ScaleMM2/smmDump.pas',
  smmFunctions in 'ScaleMM2/smmFunctions.pas',
  smmGlobal in 'ScaleMM2/smmGlobal.pas',
  smmLargeMemory in 'ScaleMM2/smmLargeMemory.pas',
  smmLogging in 'ScaleMM2/smmLogging.pas',
  smmMediumMemory in 'ScaleMM2/smmMediumMemory.pas',
  smmSmallMemory in 'ScaleMM2/smmSmallMemory.pas',
  smmStatistics in 'ScaleMM2/smmStatistics.pas',
  smmTypes in 'ScaleMM2/smmTypes.pas',
  {$IFDEF CPUX86}
    Optimize.Move in 'ScaleMM2/Optimize.Move.pas',
  {$ENDIF}
{$ENDIF}
{$IFDEF MM_FASTMM4}
  FastMM4 in 'FastMM4/FastMM4.pas',
  FastMM4Messages in 'FastMM4/FastMM4Messages.pas',
{$ENDIF}
{$IFDEF MM_FASTMM4_FullDebug}
  FastMM4 in 'FastMM4_FullDebug/FastMM4.pas',
  FastMM4Messages in 'FastMM4_FullDebug/FastMM4Messages.pas',
{$ENDIF}
{$IFDEF MM_FASTMM5}
  FastMM5 in 'FastMM5/FastMM5.pas',
{$ENDIF}
{$IFDEF MM_FASTMM5_FullDebug}
  FastMM5 in 'FastMM5_FullDebug/FastMM5.pas',
{$ENDIF}
{$IFDEF MM_BIGBRAIN}
  BigBrainUltra in 'BigBrain/BigBrainUltra.pas',
  BrainWashUltra in 'BigBrain/BrainWashUltra.pas',
{$ENDIF}
  {Other units}
  VCL.Forms,
  AddressSpaceCreepBenchmark in 'AddressSpaceCreepBenchmark.pas',
  AddressSpaceCreepBenchmarkLarge in 'AddressSpaceCreepBenchmarkLarge.pas',
  ArrayUpsizeSingleThread in 'ArrayUpsizeSingleThread.pas',
  BenchmarkClassUnit in 'BenchmarkClassUnit.pas',
  BenchmarkUtilities in 'BenchmarkUtilities.pas',
  BitOps in 'BitOps.pas',
  BlockSizeSpreadBenchmark in 'BlockSizeSpreadBenchmark.pas',
  CPU_Usage_Unit in 'CPU_Usage_Unit.pas',
  DoubleFPBenchmark1Unit in 'DoubleFPBenchmark1Unit.pas',
  DoubleFPBenchmark2Unit in 'DoubleFPBenchmark2Unit.pas',
  DoubleFPBenchmark3Unit in 'DoubleFPBenchmark3Unit.pas',
  DownsizeTestUnit in 'DownsizeTestUnit.pas',
  FastcodeCPUID in 'FastcodeCPUID.pas',
  FillCharMultiThreadBenchmark1Unit in 'FillCharMultiThreadBenchmark1Unit.pas',
  FragmentationTestUnit in 'FragmentationTestUnit.pas',
  GeneralFunctions in 'GeneralFunctions.pas',
  LargeBlockSpreadBenchmark in 'LargeBlockSpreadBenchmark.pas',
  LinkedListBenchmark in 'LinkedListBenchmark.pas',
  MemFreeBenchmark1Unit in 'MemFreeBenchmark1Unit.pas',
  MemFreeBenchmark2Unit in 'MemFreeBenchmark2Unit.pas',
  MoveBenchmark1Unit in 'MoveBenchmark1Unit.pas',
  MoveBenchmark2Unit in 'MoveBenchmark2Unit.pas',
{$IFDEF WIN32}
  MoveJOHUnit9 in 'MoveJOHUnit9.pas',
{$ENDIF}
  MultiThreadedAllocAndFree in 'MultiThreadedAllocAndFree.pas',
  MultiThreadedReallocate in 'MultiThreadedReallocate.pas',
  NexusDBBenchmarkUnit in 'NexusDBBenchmarkUnit.pas',
  PrimeNumbers in 'PrimeNumbers.pas',
  RawPerformanceMultiThread in 'RawPerformanceMultiThread.pas',
  RawPerformanceSingleThread in 'RawPerformanceSingleThread.pas',
  ReallocMemBenchmark in 'ReallocMemBenchmark.pas',
  ReplayBenchmarkUnit in 'ReplayBenchmarkUnit.pas',
  SingleFPBenchmark1Unit in 'SingleFPBenchmark1Unit.pas',
  SingleFPBenchmark2Unit in 'SingleFPBenchmark2Unit.pas',
  SingleThreadedAllocAndFree in 'SingleThreadedAllocAndFree.pas',
  SingleThreadedAllocMem in 'SingleThreadedAllocMem.pas',
  SingleThreadedReallocate in 'SingleThreadedReallocate.pas',
  SingleThreadedTinyReloc in 'SingleThreadedTinyReloc.pas',
  SmallDownsizeBenchmark in 'SmallDownsizeBenchmark.pas',
  SmallUpsizeBenchmark in 'SmallUpsizeBenchmark.pas',
  SortExtendedArrayBenchmark1Unit in 'SortExtendedArrayBenchmark1Unit.pas',
  SortExtendedArrayBenchmark2Unit in 'SortExtendedArrayBenchmark2Unit.pas',
  SortIntArrayBenchmark1Unit in 'SortIntArrayBenchmark1Unit.pas',
  SortIntArrayBenchmark2Unit in 'SortIntArrayBenchmark2Unit.pas',
  StringThread in 'StringThread.pas',
  StringThreadTestUnit in 'StringThreadTestUnit.pas',
  SystemInfoUnit in 'SystemInfoUnit.pas',
  WildThreadsBenchmarkUnit in 'WildThreadsBenchmarkUnit.pas',

  BenchmarkForm in 'BenchmarkForm.pas' {BenchmarkFrm};

{$IFDEF WIN32}
const
  IMAGE_FILE_LARGE_ADDRESS_AWARE = $0020;
{$SETPEFLAGS IMAGE_FILE_LARGE_ADDRESS_AWARE}
{$ENDIF}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TBenchmarkFrm, BenchmarkFrm);
  Application.Run;

end.

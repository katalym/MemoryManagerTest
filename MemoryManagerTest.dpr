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
{$IFDEF MM_BrainMM}
  BrainMM in 'BrainMM/BrainMM.pas',
{$ENDIF}
  {Other units}
  madExcept,
  madLinkDisAsm,
  madListHardware,
  madListProcesses,
  madListModules,
  VCL.Forms,
  MMUsageLogger_MemotyOperationRecordUnit in 'UsageLogger\MMUsageLogger_MemotyOperationRecordUnit.pas',
  AddressSpaceCreepMemTest in 'AddressSpaceCreepMemTest.pas',
  AddressSpaceCreepMemTestLarge in 'AddressSpaceCreepMemTestLarge.pas',
  ArrayUpsizeSingleThread in 'ArrayUpsizeSingleThread.pas',
  MemTestClassUnit in 'MemTestClassUnit.pas',
  MemTestUtilities in 'MemTestUtilities.pas',
  BitOps in 'BitOps.pas',
  BlockSizeSpreadMemTest in 'BlockSizeSpreadMemTest.pas',
  CPU_Usage_Unit in 'CPU_Usage_Unit.pas',
  bvDataTypes in 'bvDataTypes.pas',
  DoubleFPMemTest1Unit in 'DoubleFPMemTest1Unit.pas',
  DoubleFPMemTest2Unit in 'DoubleFPMemTest2Unit.pas',
  DoubleFPMemTest3Unit in 'DoubleFPMemTest3Unit.pas',
  DownsizeTestUnit in 'DownsizeTestUnit.pas',
  FastcodeCPUID in 'FastcodeCPUID.pas',
  FillCharMultiThreadMemTest1Unit in 'FillCharMultiThreadMemTest1Unit.pas',
  FragmentationTestUnit in 'FragmentationTestUnit.pas',
  GeneralFunctions in 'GeneralFunctions.pas',
  LargeBlockSpreadMemTest in 'LargeBlockSpreadMemTest.pas',
  LinkedListMemTest in 'LinkedListMemTest.pas',
  MemFreeMemTest1Unit in 'MemFreeMemTest1Unit.pas',
  MemFreeMemTest2Unit in 'MemFreeMemTest2Unit.pas',
  MoveMemTest1Unit in 'MoveMemTest1Unit.pas',
  MoveMemTest2Unit in 'MoveMemTest2Unit.pas',
  {$IFDEF WIN32}
  MoveJOHUnit9 in 'MoveJOHUnit9.pas',
  {$ENDIF }
  MultiThreadedAllocAndFree in 'MultiThreadedAllocAndFree.pas',
  MultiThreadedReallocate in 'MultiThreadedReallocate.pas',
  NexusDBMemTestUnit in 'NexusDBMemTestUnit.pas',
  PrimeNumbers in 'PrimeNumbers.pas',
  RawPerformanceMultiThread in 'RawPerformanceMultiThread.pas',
  RawPerformanceSingleThread in 'RawPerformanceSingleThread.pas',
  ReallocMemTest in 'ReallocMemTest.pas',
  ReplayMemTestUnit in 'ReplayMemTestUnit.pas',
  SingleFPMemTest1Unit in 'SingleFPMemTest1Unit.pas',
  SingleFPMemTest2Unit in 'SingleFPMemTest2Unit.pas',
  SingleThreadedAllocAndFree in 'SingleThreadedAllocAndFree.pas',
  SingleThreadedAllocMem in 'SingleThreadedAllocMem.pas',
  SingleThreadedReallocate in 'SingleThreadedReallocate.pas',
  SingleThreadedTinyReloc in 'SingleThreadedTinyReloc.pas',
  SmallDownsizeMemTest in 'SmallDownsizeMemTest.pas',
  SmallUpsizeMemTest in 'SmallUpsizeMemTest.pas',
  SortExtendedArrayMemTest1Unit in 'SortExtendedArrayMemTest1Unit.pas',
  SortExtendedArrayMemTest2Unit in 'SortExtendedArrayMemTest2Unit.pas',
  SortIntArrayMemTest1Unit in 'SortIntArrayMemTest1Unit.pas',
  SortIntArrayMemTest2Unit in 'SortIntArrayMemTest2Unit.pas',
  StringThread in 'StringThread.pas',
  StringThreadTestUnit in 'StringThreadTestUnit.pas',
  SystemInfoUnit in 'SystemInfoUnit.pas',
  WildThreadsMemTestUnit in 'WildThreadsMemTestUnit.pas',
  MemoryManagerForm in 'MemoryManagerForm.pas' {MemoryManagerFrm};

{$IFDEF WIN32}
const
  IMAGE_FILE_LARGE_ADDRESS_AWARE = $0020;
{$SETPEFLAGS IMAGE_FILE_LARGE_ADDRESS_AWARE}
{$ENDIF}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMemoryManagerFrm, MemoryManagerFrm);
  Application.Run;

end.

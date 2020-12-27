unit BenchmarkUtilities;

interface

{$I MemoryManagerTest.inc}

type
  {Virtual memory state}
  TVMState = record
    {The total VM size allocated or reserved}
    TotalVMAllocated: integer;
    {The number of free space fragments}
    FreeSpaceFragments: integer;
    {The largest free space fragment}
    LargestFreeSpaceFragment: integer;
  end;

function GetCompilerAbbr: string;
function GetCompilerName: string;
{Gets the CPU tick count}
function GetCPUTicks: Int64;
{Gets the current state of the virtual memory pool}
function GetVMState: TVMState;
{Gets the number of bytes of virtual memory either reserved or committed by this
 process}
function GetAddressSpaceUsed: NativeUInt;

var
  {The address space that was in use when the application started}
  InitialAddressSpaceUsed: NativeUInt;

const
{$IFDEF MM_DEFAULT}
  {Default}
  MemoryManager_Name = 'Default';
  PassValidations = True;
  FastCodeQualityLabel = False;
  DllExtension = 'DEF';
{$ENDIF}
{$IFDEF MM_SCALEMM2}
  {ScaleMM2}
  MemoryManager_Name = 'ScaleMM2';
  PassValidations = True;
  FastCodeQualityLabel = False;
  DllExtension = 'SMM';
{$ENDIF}
{$IFDEF MM_BIGBRAIN}
  {BigBrain}
  MemoryManager_Name = 'BigBrain';
  PassValidations = True;
  FastCodeQualityLabel = False;
  DllExtension = 'BBR';
{$ENDIF}
{$IFDEF MM_FASTMM4}
  {Pierre le Riche's FastMM v4.xx}
  MemoryManager_Name = 'FastMM4';
  PassValidations = True;
  FastCodeQualityLabel = True;
  DllExtension = 'FA4';
{$ENDIF}
{$IFDEF MM_FASTMM5}
  {Pierre le Riche's FastMM v501}
  MemoryManager_Name = 'FastMM5';
  PassValidations = True;
  FastCodeQualityLabel = True;
  DllExtension = 'FA5';
{$ENDIF}

implementation

uses
  Windows;

function GetCompilerAbbr: string;
begin
  Result := '10.4';
end;

function GetCompilerName: string;
begin
  Result := 'Delphi 10.4';
end;

{$ifdef FPC}
  {$asmmode intel}
{$endif}

function GetCPUTicks: Int64; assembler;
asm
   rdtsc
 {$IFDEF WIN64}
   shl   rdx, 32
   or    rax, rdx
   xor   rdx, rdx
 {$ENDIF}
end;

function GetVMState: TVMState;
var
  LChunkIndex, LFreeBlockCount: integer;
  LMBI: TMemoryBasicInformation;

  procedure AddFreeBlock;
  begin
    if LFreeBlockCount > 0 then
    begin
      Inc(Result.FreeSpaceFragments);
      if LFreeBlockCount > (Result.LargestFreeSpaceFragment shr 16) then
        Result.LargestFreeSpaceFragment := LFreeBlockCount shl 16;
      LFreeBlockCount := 0;
    end;
  end;

begin
  Result.TotalVMAllocated := 0;
  Result.FreeSpaceFragments := 0;
  Result.LargestFreeSpaceFragment := 0;
  LFreeBlockCount := 0;
  for LChunkIndex := 0 to 32767 do
  begin
    {Get the state of each 64K chunk}
    FillChar(LMBI, SizeOf(LMBI), 0);
    VirtualQuery(Pointer(LChunkIndex shl 16), LMBI, SizeOf(LMBI));
    if LMBI.State = MEM_FREE then
    begin
      Inc(LFreeBlockCount);
    end
    else
    begin
      AddFreeBlock;
      Inc(Result.TotalVMAllocated, 65536);
    end;
  end;
end;

{Gets the number of bytes of virtual memory either reserved or committed by this
 process in K}
function GetAddressSpaceUsed: NativeUInt;
var
  LMemoryStatus: TMemoryStatus;
begin
  {Set the structure size}
  LMemoryStatus.dwLength := SizeOf(LMemoryStatus);
  {Get the memory status}
  GlobalMemoryStatus(LMemoryStatus);
  {The result is the total address space less the free address space}
  Result := (LMemoryStatus.dwTotalVirtual - LMemoryStatus.dwAvailVirtual) shr 10;
end;

initialization
  {Get the initial VM Usage}
  InitialAddressSpaceUsed := GetAddressSpaceUsed;

end.

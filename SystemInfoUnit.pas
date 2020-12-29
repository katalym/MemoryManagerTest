unit SystemInfoUnit;

interface

{$INCLUDE Defines.inc}
{$IFDEF FPC}
{$MODE delphi}
{$ASMMODE intel}
{$ENDIF}

uses Windows;

type
  TVersion = record
    Major: integer;
    Minor: integer;
    Release: integer;
    Build: integer;
  end;

  PVS_FIXEDFILEINFO = ^VS_FIXEDFILEINFO;

function SystemInfoCPU: string;
function SystemInfoWindows: string;

function GetFormattedVersion: string;

implementation

uses
{$IFNDEF fpc}
  System.AnsiStrings,
{$ENDIF}
  FastCodeCPUID, SysUtils, System.Win.ComObj, System.Variants, Winapi.ActiveX;

function GetModuleVersionDFL(ModuleFileName: string; var Ver: TVersion; Product: Boolean = False): string; forward;

resourcestring
  TEXT_NO_VERSIONINFO = 'No version info';

type
  TCpuIdRecord = record
    EAX, EBX, ECX, EDX: LongWord;
  end;

  TCpuCount = record
    Log: LongWord;
    LogPerCore: LongWord;
    CorePerPhys: LongWord;
  end;

var
  FrequencyCPU: Double;
  FrequencyCPUKnown: Boolean;

function CalculateFrequencyCPU: Double; forward;
function CheckHTEnabled(const CpuCount: TCpuCount): Boolean; forward;
function CheckHTEnabledThread(Param: Pointer): DWORD; stdcall; forward;
function CountCPUsAMD: TCpuCount; forward;
function CountCPUsIntel: TCpuCount; forward;
procedure CpuId(InfoIndex: LongWord; out Res: TCpuIdRecord); forward;
function GetCPUName(const VendorString: AnsiString;
  CPUType, CPUFamily, CPUModel, CPUStepping: integer; const CPUMHz: Double): AnsiString; forward;
function RdTsc: Int64; forward;

function CalculateFrequencyCPU: Double;
var
  PerfEnd, PerfFreq, PerfStart, PerfTemp, TscEnd, TscStart: Int64;
begin
  if not FrequencyCPUKnown then
  begin
    {$WARN SYMBOL_PLATFORM OFF}
    Win32Check(QueryPerformanceFrequency(PerfFreq));
    // First allow SpeedStep some time
    Win32Check(QueryPerformanceCounter(PerfStart));
    PerfEnd := PerfStart + (PerfFreq div 2);
    repeat
      Win32Check(QueryPerformanceCounter(PerfTemp));
    until PerfTemp >= PerfEnd;

    // Now comes the real test
    Win32Check(QueryPerformanceCounter(PerfStart));
    TscStart := RdTsc;
    PerfEnd := PerfStart + (PerfFreq div 4);
    repeat
      Win32Check(QueryPerformanceCounter(PerfTemp));
    until PerfTemp >= PerfEnd;
    TscEnd := RdTsc;
    {$WARN SYMBOL_PLATFORM ON}

    FrequencyCPU := (TscEnd - TscStart) * PerfFreq / (PerfTemp - PerfStart);
    FrequencyCPUKnown := True;
  end;
  Result := FrequencyCPU;
end;

function CheckHTEnabled(const CpuCount: TCpuCount): Boolean;
var
  ApicIds: array of LongWord;
  I: integer;
  D, LT, HT: Cardinal;
  B: Boolean;
  Threads: array of THandle;
  ThreadId: LongWord;
  P: PWOHandleArray;
  PP: Pointer;
begin
  SetLength(ApicIds, CpuCount.Log);
  SetLength(Threads, CpuCount.Log);
  {$WARN SYMBOL_PLATFORM OFF}

  for I := Low(Threads) to High(Threads) do
    Threads[I] := 0;
  try

    for I := Low(Threads) to High(Threads) do
    begin
      Threads[I] := CreateThread(nil, 0, @CheckHTEnabledThread, @ApicIds[I], CREATE_SUSPENDED, ThreadId);
      Win32Check(Threads[I] <> 0);
      Win32Check(SetThreadAffinityMask(Threads[I], 1 shl I) <> 0);
      Win32Check(ResumeThread(Threads[I]) <> $FFFFFFFF);
    end;

    PP := @(Threads[0]);
    P := PP;
    D := WaitForMultipleObjects(Length(Threads), P, True, 1000) - WAIT_OBJECT_0;
    LT := Low(Threads);
    HT := High(Threads);
{$WARN COMPARISON_TRUE OFF}
    B := (D >= LT) and (D <= HT);
{$WARN COMPARISON_TRUE ON}
    Win32Check(B);

  finally
    for I := Low(Threads) to High(Threads) do
      if Threads[I] <> 0 then
        CloseHandle(Threads[I]);
  end;
  {$WARN SYMBOL_PLATFORM ON}

  Result := False;
  for I := Low(ApicIds) to High(ApicIds) do
    if ApicIds[I] and 1 <> 0 then
    begin
      Result := True;
      Break;
    end;
end;

function CheckHTEnabledThread(Param: Pointer): DWORD;
var
  CIR: TCpuIdRecord;
begin
  CpuId(1, CIR);
  PLongWord(Param)^ := (CIR.EBX shr 24) and $FF;
  Result := 0;
end;

function CountCPUsAMD: TCpuCount;
var
  CIR: TCpuIdRecord;
  InfoCount, LogPerPhys: LongWord;
  SystemInfo: TSystemInfo;
begin
  GetSystemInfo(SystemInfo);
  Result.Log := SystemInfo.dwNumberOfProcessors;
  Result.LogPerCore := 1;
  Result.CorePerPhys := 1;

  CpuId(0, CIR);
  InfoCount := CIR.EAX;

  if InfoCount >= 1 then
  begin
    CpuId(1, CIR);
    if (CIR.EDX and (1 shl 28)) <> 0 then
    begin
      LogPerPhys := CIR.EBX shr 16 and $FF;
      if LogPerPhys >= 1 then
      begin
        CpuId($80000000, CIR);
        if CIR.EAX >= $80000008 then
        begin
          CpuId($80000008, CIR);
          Result.CorePerPhys := (CIR.ECX and $FF) + 1;
          Result.LogPerCore := LogPerPhys div Result.CorePerPhys;
          if (Result.LogPerCore > 1) and not CheckHTEnabled(Result) then
            Result.LogPerCore := 1;
        end;
      end;
    end;
  end;
end;

function CountCPUsIntel: TCpuCount;
var
  CIR: TCpuIdRecord;
  InfoCount: LongWord;
  SystemInfo: TSystemInfo;
begin
  GetSystemInfo(SystemInfo);
  Result.Log := SystemInfo.dwNumberOfProcessors;
  Result.LogPerCore := 1;
  Result.CorePerPhys := 1;

  CpuId(0, CIR);
  InfoCount := CIR.EAX;

  if InfoCount >= 4 then
  begin
    CpuId(4, CIR);
    Result.CorePerPhys := (CIR.EAX shr 26) + 1;
  end;

  if InfoCount >= 1 then
  begin
    CpuId(1, CIR);
    if (CIR.EDX and (1 shl 28)) <> 0 then
    begin
      Result.LogPerCore := CIR.EBX shr 16 and $FF;
      if Result.LogPerCore < 1 then
        Result.LogPerCore := 1
      else if (Result.LogPerCore > 1) and not CheckHTEnabled(Result) then
        Result.LogPerCore := 1;
    end;
  end;
end;

procedure CpuId(InfoIndex: LongWord; out Res: TCpuIdRecord);
{$IFDEF WIN64}
asm
  push   rbx
  push   rsi

  mov    rsi,   Res
  mov    eax, InfoIndex

  db     $0F, $A2 // cpuid
  mov    [rsi+TCpuIdRecord.&EAX], eax
  mov    [rsi+TCpuIdRecord.&EBX], ebx
  mov    [rsi+TCpuIdRecord.&ECX], ecx
  mov    [rsi+TCpuIdRecord.&EDX], edx

  pop    rsi
  pop    rbx
end;
{$ELSE}
asm
  push   ebx
  push   esi

  mov    esi,   edx

  db     $0F, $A2 // cpuid
  mov    [esi+TCpuIdRecord.&EAX], eax
  mov    [esi+TCpuIdRecord.&EBX], ebx
  mov    [esi+TCpuIdRecord.&ECX], ecx
  mov    [esi+TCpuIdRecord.&EDX], edx

  pop    esi
  pop    ebx
end;
{$ENDIF}

function GetCPUName(const VendorString: AnsiString; CPUType, CPUFamily, CPUModel, CPUStepping: Integer; const CPUMHz: Double): AnsiString;
begin
  Result := '';
  if VendorString = 'GenuineIntel' then
    case CPUFamily of
      4: case CPUModel of
           0, 1: Result := 'Intel 486 DX';
           2:    Result := 'Intel 486 SX';
           3:    Result := 'Intel 486 DX/2';
           4:    Result := 'Intel 486 SL';
           5:    Result := 'Intel 486 SX/2';
           7:    Result := 'Intel 486 DX/2-WB';
           8:    Result := 'Intel 486 DX/4';
           9:    Result := 'Intel 486 DX/4-WB';
         end;
      5: case CPUModel of
           0..2: Result := 'Intel Pentium';
           4:    Result := 'Intel Pentium MMX';
           7:    Result := 'Intel Mobile Pentium';
           8:    Result := 'Intel Mobile Pentium MMX';
         end;
      6: case CPUModel of
           1:  Result := 'Intel Pentium Pro';
           3:  Result := 'Intel Pentium II [Klamath]';
           5:  Result := 'Intel Pentium II [Deschutes]';
           6:  Result := 'Intel Celeron [Mendocino]';
           7:  Result := 'Intel Pentium III [Katmai]';
           8:  Result := 'Intel Pentium III [Coppermine]';
           9:  Result := 'Intel Pentium M [Banias]';
           10: Result := 'Intel Pentium III Xeon';
           11: Result := 'Intel Pentium III';
           13: Result := 'Intel Pentium M [Dothan]';
         end;
      15: case CPUModel of
            0, 1: Result := 'Pentium 4 [Willamette]';
            2:    Result := 'Pentium 4 [Northwood]';
            3, 4: Result := 'Pentium 4 [Prescott]';
          end;
    end
  else if VendorString = 'AuthenticAMD' then
    case CPUFamily of
      4: case CPUModel of
           3:  Result := 'AMD 486 DX/2';
           7:  Result := 'AMD 486 DX/2-WB';
           8:  Result := 'AMD 486 DX/4';
           9:  Result := 'AMD 486 DX/4-WB';
           14: Result := 'AMD Am5x86-WT';
           15: Result := 'AMD Am5x86-WB';
         end;
      5: case CPUModel of
           0:    Result := 'AMD K5/SSA5';
           1..3: Result := 'AMD K5';
           6, 7: Result := 'AMD K6';
           8:    Result := 'AMD K6-2';
           9:    Result := 'AMD K6-3';
           13:   Result := 'AMD K6-2+ / K6-III+';
         end;
      6: case CPUModel of
           0..2: Result := 'AMD Athlon';
           3:    Result := 'AMD Duron';
           4:    Result := 'AMD Athlon [Thunderbird]';
           6:    Result := 'AMD Athlon [Palamino]';
           7:    Result := 'AMD Duron [Morgan]';
           8:    Result := 'AMD Athlon [Thoroughbred]';
           10:   Result := 'AMD Athlon [Barton]';
         end;
      15: case CPUModel of
            4: Result := 'AMD Athlon 64';
            5: Result := 'AMD Athlon 64 FX / Opteron';
          end;
    end;
end;

function RdTsc: Int64; assembler;
asm
  rdtsc
  {$IFDEF WIN64}
  shl   rdx, 32
  or    rax, rdx
  xor   rdx, rdx
  {$ENDIF}
end;

function GetFormattedVersion: string;
var
  Ver: TVersion;
begin
  GetModuleVersionDFL(GetModuleName(HInstance), Ver);
  Result := Format('%d.%d.%d', [Ver.Major, Ver.Minor, Ver.Release])
end;

function GetModuleVersionDFL(ModuleFileName: string; var Ver: TVersion; Product: Boolean = False): string;
var
  VersionBufferLength: integer;
  PVersionBuffer: Pointer;
  Dummy: DWORD;
  PFixedFileInfo: PVS_FIXEDFILEINFO;
  ModuleVersionLength: DWORD;
  VerW1, VerW2: DWORD;
begin
  Ver.Major := 0;
  Ver.Minor := 0;
  Ver.Release := 0;
  Ver.Build := 0;
  VersionBufferLength := GetFileVersionInfoSize(PChar(ModuleFileName), Dummy);
  PVersionBuffer := AllocMem(VersionBufferLength);
  if (PVersionBuffer <> nil) then
  begin
    if (GetFileVersionInfo(PChar(ModuleFileName), VersionBufferLength,
      VersionBufferLength, PVersionBuffer)) then
    begin
      if (VerQueryValue(PVersionBuffer, '\', Pointer(PFixedFileInfo),
        ModuleVersionLength)) then
      begin
        if Product then
        begin
          VerW1 := PFixedFileInfo^.dwProductVersionMS;
          VerW2 := PFixedFileInfo^.dwProductVersionLS;
        end
        else
        begin
          VerW1 := PFixedFileInfo^.dwFileVersionMS;
          VerW2 := PFixedFileInfo^.dwFileVersionLS;
        end;
        Ver.Major := ((VerW1) and $FFFF0000) shr 16;
        Ver.Minor := ((VerW1) and $0000FFFF);
        Ver.Release := ((VerW2) and $FFFF0000) shr 16;
        Ver.Build := ((VerW2) and $0000FFFF);
        Result := Format('%d.%d.%d.%d', [Ver.Major, Ver.Minor, Ver.Release,
          Ver.Build]);
      end;
    end
    else
    begin
      Result := TEXT_NO_VERSIONINFO;
    end;
    FreeMem(PVersionBuffer);
  end
  else
  begin
    Result := TEXT_NO_VERSIONINFO;
  end;
end;

function SystemInfoCPU: string;
var
  CIR: TCpuIdRecord;
  CPUMHz: Double;
  CPUFamily, CPUModel, CPUStepping, CPUType, InfoCount: LongWord;
  CpuCount: TCpuCount;
  AnsiStr, CPUCountStr, CPUName: AnsiString;
  BrandString: array [0 .. 47] of AnsiChar;
  VendorString: array [0 .. 12] of AnsiChar;
begin
  CpuId(0, CIR);
  InfoCount := CIR.EAX;
  Move(CIR.EBX, VendorString[0], SizeOf(CIR.EBX));
  Move(CIR.EDX, VendorString[4], SizeOf(CIR.EDX));
  Move(CIR.ECX, VendorString[8], SizeOf(CIR.ECX));
  VendorString[12] := #0;

  CPUMHz := CalculateFrequencyCPU / 1000000;
  if InfoCount >= 1 then
  begin
    CpuId(1, CIR);
    CPUType := (CIR.EAX shr 12) and $3;
    CPUFamily := (CIR.EAX shr 8) and $F;
    CPUModel := (CIR.EAX shr 4) and $F;
    CPUStepping := CIR.EAX and $F;
    if CPUFamily = $F then
    begin
      CPUFamily := CPUFamily + (CIR.EAX shr 16) and $FF0;
      CPUModel := CPUModel + (CIR.EAX shr 12) and $F0;
      Result := Format('%s, type %.1x, family %.3x, model %.2x, stepping %.1x',
        [VendorString, CPUType, CPUFamily, CPUModel, CPUStepping, CPUMHz]);
    end
    else
      Result := Format('%s, type %.1x, family %.1x, model %.1x, stepping %.1x',
        [VendorString, CPUType, CPUFamily, CPUModel, CPUStepping, CPUMHz]);

    // Does this work on Pentium III and earlier? Intel says need to check
    // CIR.EAX and $80000000, but that doesn't seem to work.
    CpuId($80000000, CIR);
    if CIR.EAX >= $80000004 then
    begin
      CpuId($80000002, CIR);
      Move(CIR, BrandString[0], SizeOf(CIR));
      CpuId($80000003, CIR);
      Move(CIR, BrandString[16], SizeOf(CIR));
      CpuId($80000004, CIR);
      Move(CIR, BrandString[32], SizeOf(CIR));
      Result := Format('%s (%s)', [TrimLeft(BrandString), Result]);
    end
    else
    begin
      CPUName := GetCPUName(VendorString, CPUType, CPUFamily, CPUModel,
        CPUStepping, CPUMHz);
      if CPUName <> '' then
        Result := Format('%s (%s)', [CPUName, Result]);
    end;
  end;

  if VendorString = 'AuthenticAMD' then
    CpuCount := CountCPUsAMD
  else
    CpuCount := CountCPUsIntel;

  CPUCountStr := '';
  if CpuCount.Log > 1 then
  begin
    if CpuCount.LogPerCore > 1 then
    begin
      AnsiStr := ', %d logical CPUs';
      CPUCountStr := CPUCountStr +
{$IFNDEF FPC}System.AnsiStrings.{$ENDIF}Format(AnsiStr, [CpuCount.Log]);
    end;
    if CpuCount.CorePerPhys > 1 then
    begin
      AnsiStr := ', %d CPU cores';
      CPUCountStr := CPUCountStr +
{$IFNDEF FPC}System.AnsiStrings.{$ENDIF}Format(AnsiStr,
        [CpuCount.Log div CpuCount.LogPerCore]);
    end;
    AnsiStr := ', %d physical CPUs';
    CPUCountStr := CPUCountStr +
{$IFNDEF FPC}System.AnsiStrings.{$ENDIF}Format(AnsiStr,
      [CpuCount.Log div (CpuCount.LogPerCore * CpuCount.CorePerPhys)]);
  end;

  Result := Format('%s, %.1f MHz%s', [Result, CPUMHz, CPUCountStr]);
end;

function SystemInfoWindows: string;
const
  WbemUser = '';
  WbemPassword = '';
  WbemComputer = 'localhost';
  wbemFlagForwardOnly = $00000020;
var
  FSWbemLocator: OLEVariant;
  FWMIService: OLEVariant;
  FWbemObjectSet: OLEVariant;
  FWbemObject: OLEVariant;
  oEnum: IEnumvariant;
  iValue: LongWord;
begin;
  Result := '';

  try
    try
      FSWbemLocator := CreateOleObject('WbemScripting.SWbemLocator');
      FWMIService := FSWbemLocator.ConnectServer(WbemComputer, 'root\CIMV2',
        WbemUser, WbemPassword);
      FWbemObjectSet := FWMIService.ExecQuery
        ('SELECT * FROM Win32_OperatingSystem', 'WQL', wbemFlagForwardOnly);
      oEnum := IUnknown(FWbemObjectSet._NewEnum) as IEnumvariant;
      while oEnum.Next(1, FWbemObject, iValue) = 0 do
      begin
        Result := Format('%s, version: %s', [String(FWbemObject.Caption), String(FWbemObject.Version)]);
        FWbemObject := Unassigned;
      end;
    except
    end;
  finally
  end;
end;

end.

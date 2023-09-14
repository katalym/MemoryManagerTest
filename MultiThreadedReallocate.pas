{A multi-threaded MemTest that reallocates memory blocks and uses them.}

unit MultiThreadedReallocate;

interface

{$I MemoryManagerTest.inc}

uses
  Windows, MemTestClassUnit, Classes, Math;

type

  TMultiThreadReallocateMemTestAbstract = class(TMemTest)
  public
    class function GetMemTestDescription: string; override;
    class function GetMemTestName: string; override;
    class function GetCategory: TMemTestCategory; override;
    class function GetNumThreads: Integer; virtual; abstract;
    class function IsThreadedSpecial: Boolean; override;
    procedure RunMemTest; override;
  end;

  TMultiThreadReallocateMemTest2 = class(TMultiThreadReallocateMemTestAbstract)
    class function GetNumThreads: Integer; override;
  end;

  TMultiThreadReallocateMemTest4 = class(TMultiThreadReallocateMemTestAbstract)
    class function GetNumThreads: Integer; override;
  end;

  TMultiThreadReallocateMemTest8 = class(TMultiThreadReallocateMemTestAbstract)
    class function GetNumThreads: Integer; override;
  end;

  TMultiThreadReallocateMemTest12 = class(TMultiThreadReallocateMemTestAbstract)
    class function GetNumThreads: Integer; override;
  end;

  TMultiThreadReallocateMemTest16 = class(TMultiThreadReallocateMemTestAbstract)
    class function GetNumThreads: Integer; override;
  end;

  TMultiThreadReallocateMemTest31 = class(TMultiThreadReallocateMemTestAbstract)
    class function GetNumThreads: Integer; override;
  end;

  TMultiThreadReallocateMemTest64 = class(TMultiThreadReallocateMemTestAbstract)
    class function GetNumThreads: Integer; override;
  end;

implementation

uses
  PrimeNumbers,
  SysUtils,
  bvDataTypes;

type
  TCreateAndFreeThread = class(TThread)
  public
    FCurValue: Int64;
    FPrime: Cardinal;
    FRepeatCount: Integer;
    procedure Execute; override;
  end;

procedure TCreateAndFreeThread.Execute;
const
{$IFDEF FullDebug}
  PointerCount = 25;
{$ELSE}
  PointerCount = 2500;
{$ENDIF}
var
  i, j: Integer;
  kcalc: NativeUint;
  kloop: Cardinal;
  LPointers: array [0 .. PointerCount - 1] of Pointer;
  LMax, LSize, LSum: Integer;
begin
  {Allocate the initial pointers}
  for i := 0 to PointerCount - 1 do
  begin
    {Rough breakdown: 50% of pointers are <=64 bytes, 95% < 1K, 99% < 4K, rest < 256K}
    if i and 1 <> 0 then
      LMax := 64
    else
      if i and 15 <> 0 then
      LMax := 1024
    else
      if i and 255 <> 0 then
      LMax := 4 * 1024
    else
      LMax := 256 * 1024;
    {Get the size, minimum 1}
    Inc(FCurValue, FPrime);
    LSize := bvInt64ToInt((FCurValue mod LMax) + 1);
    {Get the pointer}
    GetMem(LPointers[i], LSize);
  end;
  {Reallocate in a loop}
  for j := 1 to FRepeatCount do
  begin
    for i := 0 to PointerCount - 1 do
    begin
      {Rough breakdown: 50% of pointers are <=64 bytes, 95% < 1K, 99% < 4K, rest < 256K}
      if i and 1 <> 0 then
        LMax := 64
      else
        if i and 15 <> 0 then
        LMax := 1024
      else
        if i and 255 <> 0 then
        LMax := 4 * 1024
      else
        LMax := 256 * 1024;
      {Get the size, minimum 1}
      Inc(FCurValue, FPrime);
      LSize := bvInt64ToInt((FCurValue mod LMax) + 1);
      {Reallocate the pointer}
      ReallocMem(LPointers[i], LSize);
      {Write the memory}
      for kloop := 0 to bvIntToCardinal((LSize - 1) div 32) do
      begin
        kcalc := kloop;
        PByte(NativeUint(LPointers[i]) + kcalc * 32)^ := byte(i);
      end;
      {Read the memory}
      LSum := 0;
      if LSize > 15 then
      begin
        for kloop := 0 to bvIntToCardinal((LSize - 16) div 32) do
        begin
          kcalc := kloop;
          Inc(LSum, PShortInt(NativeUint(LPointers[i]) + kcalc * 32 + 15)^);
        end;
      end;
      {"Use" the sum to suppress the compiler warning}
      if LSum > 0 then;
    end;
  end;
  {Free all the pointers}
  for i := 0 to PointerCount - 1 do
    FreeMem(LPointers[i]);
  {Set the return value}
  ReturnValue := 1;
end;

class function TMultiThreadReallocateMemTestAbstract.GetMemTestDescription: string;
begin
  Result := 'A ' + IntToStr(GetNumThreads) + '-threaded MemTest that allocates and reallocates memory '
    + 'blocks. The usage of different block sizes approximates real-world usage '
    + 'as seen in various replays. Allocated memory is actually "used", i.e. '
    + 'written to and read.  '
    + 'MemTest submitted by Pierre le Riche.';
end;

class function TMultiThreadReallocateMemTestAbstract.GetMemTestName: string;
begin
  Result := 'Multi-threaded ' + GetNumThreads.ToString.PadLeft(2, ' ') + ' reallocate and use';
end;

class function TMultiThreadReallocateMemTestAbstract.GetCategory: TMemTestCategory;
begin
  Result := bmMultiThreadRealloc;
end;

class function TMultiThreadReallocateMemTestAbstract.IsThreadedSpecial: Boolean;
begin
  Result := True;
end;

procedure TMultiThreadReallocateMemTestAbstract.RunMemTest;
const
  CRepeatCountTotal = 5555;
var
  PrimeIndex, n: Integer;
  LCreateAndFree: TCreateAndFreeThread;
  threads: TList;
  LFinished: Boolean;
  LNumThreads: Integer;
begin
  inherited;
  PrimeIndex := low(VeryGoodPrimes);
  threads := TList.Create;
  LNumThreads := GetNumThreads;
  {create threads}
  for n := 1 to LNumThreads do begin
    LCreateAndFree := TCreateAndFreeThread.Create(True);
    LCreateAndFree.FPrime := VeryGoodPrimes[PrimeIndex];
    LCreateAndFree.FRepeatCount := CRepeatCountTotal div LNumThreads;
    Inc(PrimeIndex);
    if PrimeIndex > high(VeryGoodPrimes) then
      PrimeIndex := low(VeryGoodPrimes);
    LCreateAndFree.FreeOnTerminate := False;
    threads.Add(LCreateAndFree);
  end;
  {start all threads at the same time}
  SetThreadPriority(GetCurrentThread, THREAD_PRIORITY_ABOVE_NORMAL);
  for n := 0 to threads.Count - 1 do
  begin
    LCreateAndFree := TCreateAndFreeThread(threads.Items[n]);
    LCreateAndFree.Suspended := False;
  end;
  SetThreadPriority(GetCurrentThread, THREAD_PRIORITY_NORMAL);
  {wait for completion of the threads}
  repeat
    {Any threads still running?}
    LFinished := True;
    for n := 0 to threads.Count - 1 do
    begin
      LCreateAndFree := TCreateAndFreeThread(threads.Items[n]);
      LFinished := LFinished and (LCreateAndFree.ReturnValue <> 0);
    end;
    {Update usage statistics}
    UpdateUsageStatistics;
{$IFDEF WIN32}
    {Don't sleep on Win64}
    sleep(10);
{$ENDIF}
  until LFinished;
  {Free the threads}
  for n := 0 to threads.Count - 1 do
  begin
    LCreateAndFree := TCreateAndFreeThread(threads.Items[n]);
    LCreateAndFree.Terminate;
  end;
  for n := 0 to threads.Count - 1 do
  begin
    LCreateAndFree := TCreateAndFreeThread(threads.Items[n]);
    LCreateAndFree.WaitFor;
  end;
  for n := 0 to threads.Count - 1 do
  begin
    LCreateAndFree := TCreateAndFreeThread(threads.Items[n]);
    LCreateAndFree.Free;
  end;
  threads.Clear;
  threads.Free;
end;

class function TMultiThreadReallocateMemTest2.GetNumThreads: Integer;
begin
  Result := 2;
end;

class function TMultiThreadReallocateMemTest4.GetNumThreads: Integer;
begin
  Result := 4;
end;

class function TMultiThreadReallocateMemTest8.GetNumThreads: Integer;
begin
  Result := 8;
end;

class function TMultiThreadReallocateMemTest12.GetNumThreads: Integer;
begin
  Result := 12;
end;

class function TMultiThreadReallocateMemTest16.GetNumThreads: Integer;
begin
  Result := 16;
end;

class function TMultiThreadReallocateMemTest31.GetNumThreads: Integer;
begin
  Result := 32;
end;

class function TMultiThreadReallocateMemTest64.GetNumThreads: Integer;
begin
  Result := 64;
end;

end.

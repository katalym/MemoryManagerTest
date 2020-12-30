unit MMUsageLogger_TestFrm;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls;

type
  TMMUsageLogger_TestForm = class(TForm)
    Button2: TButton;
    Label1: TLabel;
    Edit1: TEdit;
    procedure FormCreate(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  end;

var
  MMUsageLogger_TestForm: TMMUsageLogger_TestForm;

implementation

uses
  MMUsageLogger;

{$R *.dfm}

type
  TCreateAndFreeThread = class(TThread)
  public
    FCurValue: Int64;
    FPrime: Integer;
    FRepeatCount: Integer;
    procedure Execute; override;
  end;

procedure TMMUsageLogger_TestForm.FormCreate(Sender: TObject);
begin
  Edit1.Text := MMUsageLogger.LogFileName;
end;

procedure TMMUsageLogger_TestForm.Button2Click(Sender: TObject);
const
  CRepeatCountTotal = 55555;
var
  PrimeIndex, n: Integer;
  LCreateAndFree: TCreateAndFreeThread;
  LNumThreads: Integer;
  threads: TList;
  LFinished: Boolean;
begin
  inherited;
  LNumThreads := 32;
  PrimeIndex := 0;
  threads := TList.Create;
  {create threads}
  for n := 1 to LNumThreads do
  begin
    LCreateAndFree := TCreateAndFreeThread.Create(True);
    LCreateAndFree.Priority := tpLower;
    LCreateAndFree.FPrime := 9999 * PrimeIndex;
    LCreateAndFree.FRepeatCount := CRepeatCountTotal div LNumThreads;
    Inc(PrimeIndex);
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
  FreeAndNil(threads);
end;

procedure TCreateAndFreeThread.Execute;
const
  PointerCount = 25;
var
  i, j: Integer;
  kloop: Cardinal;
  kcalc: NativeUint;
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
    LSize := (FCurValue mod LMax) + 1;
    {Get the pointer}
    GetMem(LPointers[i], LSize);
  end;
  {Free and allocate in a loop}
  for j := 1 to FRepeatCount do
  begin
    for i := 0 to PointerCount - 1 do
    begin
      {Free the pointer}
      FreeMem(LPointers[i]);
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
      LSize := (FCurValue mod LMax) + 1;
      {Get the pointer}
      GetMem(LPointers[i], LSize);
      {Write the memory}
      for kloop := 0 to (LSize - 1) div 32 do
      begin
        kcalc := kloop;
        PByte(NativeUint(LPointers[i]) + kcalc * 32)^ := byte(i);
      end;
      {Read the memory}
      LSum := 0;
      if LSize > 15 then
      begin
        for kloop := 0 to (LSize - 16) div 32 do
        begin
          kcalc := kloop;
          Inc(LSum, PShortInt(NativeUint(LPointers[i]) + kcalc * 32 + 15)^);
        end;
      end;
      {"Use" the sum to suppress the compiler warning}
      if LSum > 0 then;
    end;
  end;
  {Free all the objects}
  for i := 0 to PointerCount - 1 do
    FreeMem(LPointers[i]);
  {Set the return value}
  ReturnValue := 1;
end;

end.

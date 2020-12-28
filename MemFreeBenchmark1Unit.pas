unit MemFreeBenchmark1Unit;

interface

uses Windows, BenchmarkClassUnit, Classes, Math;

type

  TMemFreeThreads1 = class(TMMBenchmark)
  public
    class function GetBenchmarkDescription: string; override;
    class function GetBenchmarkName: string; override;
    class function GetCategory: TBenchmarkCategory; override;
    procedure RunBenchmark; override;
  end;

implementation

uses SysUtils;

type
  TMemFreeThread1 = class(TThread)
     FBenchmark: TMMBenchmark;
     procedure Execute; override;
  end;

procedure TMemFreeThread1.Execute;
var
  PointerArray : array of Pointer;
  I, AllocSize, J: Integer;
  AllocSizeFP : Double;
const
  RUNS = 2;
  NOOFPOINTERS = 12000000;
  ALLOCGROWSTEPSIZE = 0.0000006;
  {$IFDEF WIN32}
  SLEEPTIMEAFTERFREE = 10;//Seconds to free
  {$ENDIF}
begin
  //Allocate
  SetLength(PointerArray, NOOFPOINTERS);
  for J := 1 to Runs do
  begin
    AllocSizeFP := 1;
    for I:= 0 to Length(PointerArray)-1 do
      begin
        AllocSizeFP := AllocSizeFP + ALLOCGROWSTEPSIZE;
        AllocSize := Round(AllocSizeFP);
        GetMem(PointerArray[I], AllocSize);
      end;
    //Free
    for I:= 0 to Length(PointerArray)-1 do
      FreeMem(PointerArray[I]);
  end;
  SetLength(PointerArray, 0);
  {$IFDEF WIN32}
  //Give a little time to free
  Sleep(SLEEPTIMEAFTERFREE);
  {$ENDIF}
  FBenchmark.UpdateUsageStatistics;
end;

class function TMemFreeThreads1.GetBenchmarkDescription: string;
begin
  Result := 'A benchmark that measures how much memory is left unfreed after heavy work '
    + 'Benchmark submitted by Dennis Kjaer Christensen.';
end;

class function TMemFreeThreads1.GetBenchmarkName: string;
begin
  Result := 'Mem Free 1';
end;

class function TMemFreeThreads1.GetCategory: TBenchmarkCategory;
begin
  Result := bmSingleThreadAllocAndFree;
end;

procedure TMemFreeThreads1.RunBenchmark;
var
  MemFreeThread1 : TMemFreeThread1;
begin
  inherited;
  MemFreeThread1 := TMemFreeThread1.Create(True);
  MemFreeThread1.FreeOnTerminate := False;
  MemFreeThread1.FBenchmark := Self;
  MemFreeThread1.Suspended := False;
  MemFreeThread1.WaitFor;
  FreeAndNil(MemFreeThread1);
end;

end.

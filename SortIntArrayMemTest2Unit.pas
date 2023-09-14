unit SortIntArrayMemTest2Unit;

interface

{$I MemoryManagerTest.inc}

uses
  Windows, MemTestClassUnit, Classes, Math;

type

  TQuickSortIntArrayThreads = class(TMemTest)
  public
    class function GetMemTestDescription: string; override;
    class function GetMemTestName: string; override;
    class function GetCategory: TMemTestCategory; override;
    procedure RunMemTest; override;
  end;

implementation

uses SysUtils, bvDataTypes;

type

  TSortIntArrayThread = class(TThread)
    FMemTest: TMemTest;
    FPrime: Integer;
    procedure Execute; override;
  end;

function SortCompareInt(Item1, Item2: Pointer): Integer;
begin
  Result := bvNativeIntToInt(NativeInt(Item1) - NativeInt(Item2));
end;

procedure TSortIntArrayThread.Execute;
var
  I, J, IntVal, Size: Integer;
  List: TList;
  FCurValue: Int64;
const
  MINSIZE = 500;
{$IFDEF FullDebug}
  MAXSIZE     = 600;
  RepeatCount = 4;
{$ELSE}
  MAXSIZE     = 1500;
  RepeatCount = 20;
{$ENDIF}
  CMaxValue = 101 {prime};
begin
  FCurValue := FPrime;
  for J := 1 to RepeatCount do
  begin
    for Size := MINSIZE to MAXSIZE do
    begin
      List := TList.Create;
      try
        List.Count := Size;
        for I := 0 to Size - 1 do
        begin
          IntVal := bvInt64ToInt(FCurValue mod CMaxValue);
          Inc(FCurValue, FPrime);
          List[I] := Pointer(IntVal);
        end;
        List.Sort({$IFDEF FPC}@{$ENDIF}SortCompareInt);
      finally
        List.Free;
      end;
    end;
    FMemTest.UpdateUsageStatistics;
  end;
end;

class function TQuickSortIntArrayThreads.GetMemTestDescription:
  string;
begin
  Result := 'A MemTest that measures read and write speed to an array of Integer. '
    + 'Access pattern is created by  selection sorting array of arbitrary values using the QuickSort algorithm implemented in TList.. '
    + 'Measures memory usage after all blocks have been freed. '
    + 'MemTest submitted by Avatar Zondertau, based on a MemTest by Dennis Kjaer Christensen.';
end;

class function TQuickSortIntArrayThreads.GetMemTestName: string;
begin
  Result := 'Quick Sort Integer Array';
end;

class function TQuickSortIntArrayThreads.GetCategory: TMemTestCategory;
begin
  Result := bmMemoryAccessSpeed;
end;

procedure TQuickSortIntArrayThreads.RunMemTest;
var
  SortIntArrayThread: TSortIntArrayThread;
begin
  inherited;
  SortIntArrayThread := TSortIntArrayThread.Create(True);
  SortIntArrayThread.FreeOnTerminate := False;
  SortIntArrayThread.FMemTest := Self;
  SortIntArrayThread.FPrime := 463;
  SortIntArrayThread.Suspended := False;
  SortIntArrayThread.WaitFor;
  SortIntArrayThread.Free;
end;

end.

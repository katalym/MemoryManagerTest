unit SortIntArrayMemTest1Unit;

interface

{$I MemoryManagerTest.inc}

uses
  Windows, MemTestClassUnit, Classes, Math;

type

  TSortIntArrayThreads = class(TMemTest)
  public
    class function GetMemTestDescription: string; override;
    class function GetMemTestName: string; override;
    class function GetCategory: TMemTestCategory; override;
    procedure RunMemTest; override;
  end;

implementation

uses
  SysUtils, bvDataTypes;

type

  TSortIntArrayThread = class(TThread)
    FMemTest: TMemTest;
    FCurValue: Int64;
    FPrime: Integer;
    procedure Execute; override;
  end;

procedure TSortIntArrayThread.Execute;
var
  IntArray: array of Integer;
  Size, I1, I2, I3, IndexMax, Temp, Max: Integer;
const
  MINSIZE = 5;
{$IFDEF FullDebug}
  MAXSIZE = 300;
{$ELSE}
  MAXSIZE = 3200;
{$ENDIF}
  MaxValue = 103 {prime};
begin
  FCurValue := FPrime;
  for Size := MINSIZE to MAXSIZE do
  begin
    SetLength(IntArray, Size);
    // Fill array with arbitrary values
    for I1 := 0 to Size - 1 do
    begin
      IntArray[I1] := bvInt64ToInt(FCurValue mod MaxValue);
      Inc(FCurValue, FPrime);
    end;
    // Sort array just to create an acces pattern
    for I2 := 0 to Size - 2 do
    begin
      // Find biggest element in unsorted part of array
      Max := IntArray[I2];
      IndexMax := I2;
      for I3 := I2 + 1 to Size - 1 do
      begin
        if IntArray[I3] > Max then
        begin
          Max := IntArray[I3];
          IndexMax := I3;
        end;
      end;
      // Swap current element with biggest remaining element
      Temp := IntArray[I2];
      IntArray[I2] := IntArray[IndexMax];
      IntArray[IndexMax] := Temp;
    end;
  end;
  // "Free" array
  SetLength(IntArray, 0);
  FMemTest.UpdateUsageStatistics;
end;

class function TSortIntArrayThreads.GetMemTestDescription: string;
begin
  Result := 'A MemTest that measures read and write speed to an array of Integer. '
    + 'Access pattern is created by  selection sorting array of arbitrary values. '
    + 'Measures memory usage after all blocks have been freed. '
    + 'MemTest submitted by Dennis Kjaer Christensen.';
end;

class function TSortIntArrayThreads.GetMemTestName: string;
begin
  Result := 'Sort Integer Array';
end;

class function TSortIntArrayThreads.GetCategory: TMemTestCategory;
begin
  Result := bmMemoryAccessSpeed;
end;

procedure TSortIntArrayThreads.RunMemTest;
var
  SortIntArrayThread: TSortIntArrayThread;
begin
  inherited;
  SortIntArrayThread := TSortIntArrayThread.Create(True);
  SortIntArrayThread.FreeOnTerminate := False;
  SortIntArrayThread.FMemTest := Self;
  SortIntArrayThread.FPrime := 1153;
  SortIntArrayThread.Suspended := False;
  SortIntArrayThread.WaitFor;
  FreeAndNil(SortIntArrayThread);
end;

end.

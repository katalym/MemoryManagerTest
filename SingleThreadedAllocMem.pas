{A MemTest that tests the speed and validity of allocmem}

unit SingleThreadedAllocMem;

{$I MemoryManagerTest.inc}

interface

uses Windows, SysUtils, MemTestClassUnit, Classes, Math;

type

  TSingleThreadAllocMemMemTest = class(TMemTest)
  public
    class function GetMemTestDescription: string; override;
    class function GetMemTestName: string; override;
    class function GetCategory: TMemTestCategory; override;
    procedure RunMemTest; override;
  end;

implementation

uses
  bvDataTypes;

class function TSingleThreadAllocMemMemTest.GetMemTestDescription: string;
begin
  Result := 'A single-threaded MemTest that tests the speed and validity of AllocMem.  '
    + 'MemTest submitted by Pierre le Riche.';
end;

class function TSingleThreadAllocMemMemTest.GetMemTestName: string;
begin
  Result := 'Single-threaded AllocMem';
end;

class function TSingleThreadAllocMemMemTest.GetCategory: TMemTestCategory;
begin
  Result := bmSingleThreadAllocAndFree;
end;

procedure TSingleThreadAllocMemMemTest.RunMemTest;
const
  Prime = 17;
{$IFDEF FullDebug}
  RepeatCount = 5;
{$ELSE}
  RepeatCount = 100;
{$ENDIF}
  PointerCount = 300;
  MaxBlockSize = 300000;
type
  TByteArray = array [0 .. MaxBlockSize - 1] of Byte;
  PByteArray = ^TByteArray;
var
  i, j, k: Integer;
  CurValue: Int64;
  LPointers: array [0 .. PointerCount - 1] of Pointer;
  LSize: Integer;
  LCheck: Byte;
begin
  inherited;
  {We want predictable results}
  CurValue := Prime;
  FillChar(LPointers, SizeOf(LPointers), 0);
  {FreeMem and AllocMem in a loop}
  for j := 1 to RepeatCount do
  begin
    {Update usage statistics}
    UpdateUsageStatistics;
    for i := 0 to PointerCount - 1 do
    begin
      {Free the pointer}
      FreeMem(LPointers[i]);
      {Get the size, minimum 1}
      LSize := bvInt64ToInt((CurValue mod MaxBlockSize) + 1);
      Inc(CurValue, Prime);
      {Get the pointer}
      LPointers[i] := AllocMem(LSize);
      {Read the memory}
      LCheck := 0;
      for k := 0 to LSize - 1 do
      begin
        {Check the memory}
        LCheck := LCheck or PByteArray(LPointers[i])^[k];
        {Modify it}
        PByteArray(LPointers[i])^[k] := Byte(k);
      end;
      {Is the check valid?}
      if LCheck <> 0 then
        raise Exception.Create('AllocMem returned a block that was not zero initialized.');
    end;
  end;
  {Free all the objects}
  for i := 0 to PointerCount - 1 do
    FreeMem(LPointers[i]);
end;

end.

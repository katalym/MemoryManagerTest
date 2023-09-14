unit ArrayUpsizeSingleThread;

interface

{$I MemoryManagerTest.inc}

uses
  MemTestClassUnit, Classes;

type
  TArrayUpsizeSingleThread = class(TMemTest)
  private
    procedure Execute;
  public
    procedure RunMemTest; override;
    class function GetMemTestName: string; override;
    class function GetMemTestDescription: string; override;
    class function GetCategory: TMemTestCategory; override;
  end;

implementation

uses
  SysUtils;

const
  // full debug mode is used to detect memory leaks - not for actual performance test
  // value is decreased to avoid Out of Memory in fuul debug mode
{$IFDEF FullDebug}
  IterationCount = 2800000;
{$ELSE}
  IterationCount = 28000000;
{$ENDIF}

procedure TArrayUpsizeSingleThread.Execute;
var
  i: Integer;
  x: array of Int64;
begin
  for i := 1 to IterationCount do begin
    SetLength(x, i);
    x[i - 1] := i;
  end;
  UpdateUsageStatistics;
end;

class function TArrayUpsizeSingleThread.GetMemTestDescription: string;
begin
  Result := 'Constantly resize a dynamic array in 8 byte steps upward to '
    + 'reproduce JclDebug behaviour when loading debug information'
    + 'Start size is 16 bytes.  Stop size is 8 * 10 * 1024 * 1024 + 8 bytes';
end;

class function TArrayUpsizeSingleThread.GetMemTestName: string;
begin
  Result := 'Array Upsize 1 thread';
end;

class function TArrayUpsizeSingleThread.GetCategory: TMemTestCategory;
begin
  Result := bmSingleThreadRealloc;
end;

procedure TArrayUpsizeSingleThread.RunMemTest;
begin
  inherited;
  Execute;
end;

end.

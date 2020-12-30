unit ArrayUpsizeSingleThread;

interface

{$I MemoryManagerTest.inc}

uses
  BenchmarkClassUnit, Classes;

type
  TArrayUpsizeSingleThread = class(TMMBenchmark)
  private
    procedure Execute;
  public
    procedure RunBenchmark(const aUsageFileToReplay: string =''); override;
    class function GetBenchmarkName: string; override;
    class function GetBenchmarkDescription: string; override;
    class function GetCategory: TBenchmarkCategory; override;
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

class function TArrayUpsizeSingleThread.GetBenchmarkDescription: string;
begin
  Result := 'Constantly resize a dynamic array in 8 byte steps upward to '
    + 'reproduce JclDebug behaviour when loading debug information'
    + 'Start size is 16 bytes.  Stop size is 8 * 10 * 1024 * 1024 + 8 bytes';
end;

class function TArrayUpsizeSingleThread.GetBenchmarkName: string;
begin
  Result := 'Array Upsize 1 thread';
end;

class function TArrayUpsizeSingleThread.GetCategory: TBenchmarkCategory;
begin
  Result := bmSingleThreadRealloc;
end;

procedure TArrayUpsizeSingleThread.RunBenchmark;
begin
  inherited;
  Execute;
end;

end.

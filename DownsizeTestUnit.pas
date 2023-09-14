{A MemTest demonstrating that never downsizing memory blocks can lead to problems.}

unit DownsizeTestUnit;

interface

{$I MemoryManagerTest.inc}

uses MemTestClassUnit;

type

  TDownsizeTest = class(TMemTest)
  protected
    FStrings: array of string;
  public
    class function GetMemTestDescription: string; override;
    class function GetMemTestName: string; override;
    class function GetCategory: TMemTestCategory; override;
    procedure RunMemTest; override;
  end;

implementation

uses
  bvDataTypes, System.SysUtils;

class function TDownsizeTest.GetMemTestDescription: string;
begin
  Result := 'Allocates large blocks and immediately resizes them to a '
    + 'much smaller size. This checks whether the memory manager downsizes '
    + 'memory blocks correctly.  '
    + 'MemTest submitted by Pierre le Riche.';
end;

class function TDownsizeTest.GetMemTestName: string;
begin
  Result := 'Block downsize';
end;

class function TDownsizeTest.GetCategory: TMemTestCategory;
begin
  Result := bmSingleThreadRealloc;
end;

procedure TDownsizeTest.RunMemTest;
const
  // full debug mode is used to detect memory leaks - not for actual performance test
  // value is decreased to avoid Out of Memory in fuul debug mode
{$IFDEF FullDebug}
  TotalStrings   = 5000;
  IterationCount = 5;
{$ELSE}
  TotalStrings   = 3000000;
  IterationCount = 45;
{$ENDIF}
var
  i, n, LOffset: integer;
begin
  inherited;

  for n := 1 to IterationCount do
  begin
    {Allocate a lot of strings}
    SetLength(FStrings, TotalStrings);
    for i := bvNativeIntToInt(Low(FStrings)) to bvNativeIntToInt(high(FStrings)) do begin
      {Grab a 20K block}
      SetLength(FStrings[i], 20000);
      {Touch memory}
      LOffset := 1;
      while LOffset <= 20000 do
      begin
        FStrings[i][LOffset] := #1;
        Inc(LOffset, 4096);
      end;
      {Reduce the size to 1 byte}
      SetLength(FStrings[i], 1);
    end;
    {Update the peak address space usage}
    UpdateUsageStatistics;
  end;
end;

end.

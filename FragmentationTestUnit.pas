{A MemTest demonstrating how the RTL Delphi MM fragments the virtual address
  space}

unit FragmentationTestUnit;

interface

{$I MemoryManagerTest.inc}

uses
  MemTestClassUnit;

type

  TFragmentationTest = class(TMemTest)
  protected
    FStrings: array of string;
  public
    class function GetMemTestDescription: string; override;
    class function GetMemTestName: string; override;
    class function GetCategory: TMemTestCategory; override;
    procedure RunMemTest; override;
  end;

implementation

const
  // full debug mode is used to detect memory leaks - not for actual performance test
  // value is decreased to avoid Out of Memory in fuul debug mode
{$IFDEF FullDebug}
  IterationCount = 3;
{$ELSE}
  IterationCount = 120;
{$ENDIF}

class function TFragmentationTest.GetMemTestDescription: string;
begin
  Result := 'A MemTest that intersperses large block allocations with the '
    + 'allocation of smaller blocks to test how resistant the memory manager '
    + 'is to address space fragmentation that may eventually lead to '
    + '"out of memory" errors.  '
    + 'MemTest submitted by Pierre le Riche.';
end;

class function TFragmentationTest.GetMemTestName: string;
begin
  Result := 'Fragmentation Test';
end;

class function TFragmentationTest.GetCategory: TMemTestCategory;
begin
  Result := bmSingleThreadRealloc;
end;

procedure TFragmentationTest.RunMemTest;
var
  i, n: integer;
begin
  inherited;

  for n := 1 to IterationCount do // loop added to have more than 1000 MTicks for this MemTest
  begin
    SetLength(FStrings, 0);
    for i := 1 to 90 do
    begin
      // add 100000 elements
      SetLength(FStrings, length(FStrings) + 100000);
      // allocate a 1 length string
      SetLength(FStrings[high(FStrings)], 1);
    end;
    {Update the peak address space usage}
    UpdateUsageStatistics;
  end;
end;

end.

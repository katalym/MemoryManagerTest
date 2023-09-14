unit MemFreeMemTest2Unit;

interface

uses
  Windows, MemTestClassUnit, Classes, Math;

type

  TMemFreeThreads2 = class(TMemTest)
  public
    class function GetMemTestDescription: string; override;
    class function GetMemTestName: string; override;
    class function GetCategory: TMemTestCategory; override;
    procedure RunMemTest; override;
    class function RunByDefault: Boolean; override;
  end;

implementation

uses SysUtils;

type
  TMemFreeThread2 = class(TThread)
    FMemTest: TMemTest;
    procedure Execute; override;
  end;

procedure TMemFreeThread2.Execute;
begin
  Sleep(100); // Do not run in zero ticks !!!!!
  FMemTest.UpdateUsageStatistics;
end;

class function TMemFreeThreads2.GetMemTestDescription: string;
begin
  Result := 'A MemTest that measures how much memory the MM allocates when doing close to nothing'
    + ' MemTest submitted by Dennis Kjaer Christensen.';
end;

class function TMemFreeThreads2.GetMemTestName: string;
begin
  Result := 'Mem Free 2';
end;

class function TMemFreeThreads2.GetCategory: TMemTestCategory;
begin
  Result := bmSingleThreadAllocAndFree;
end;

procedure TMemFreeThreads2.RunMemTest;
var
  MemFreeThread2: TMemFreeThread2;
begin
  inherited;
  MemFreeThread2 := TMemFreeThread2.Create(True);
  MemFreeThread2.FreeOnTerminate := False;
  MemFreeThread2.FMemTest := Self;
  MemFreeThread2.Suspended := False;
  MemFreeThread2.WaitFor;
  FreeAndNil(MemFreeThread2);
end;

class function TMemFreeThreads2.RunByDefault: Boolean;
begin
  Result := False;
end;

end.

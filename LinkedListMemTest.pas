unit LinkedListMemTest;

interface

{$I MemoryManagerTest.inc}

uses
  Classes, MemTestClassUnit, Math;

const
  // full debug mode is used to detect memory leaks - not for actual performance test
  // value is decreased to avoid Out of Memory in fuul debug mode
{$IFDEF FullDebug}
  cNB_LIST_ITEMS = 20000;
{$ELSE}
  cNB_LIST_ITEMS = 1200000;
{$ENDIF}

type

  TLinkedListBench = class(TMemTest)
  public
    constructor CreateMemTest; override;
    destructor Destroy; override;
    class function GetMemTestDescription: string; override;
    class function GetMemTestName: string; override;
    class function GetCategory: TMemTestCategory; override;
    procedure RunMemTest; override;
  end;

implementation

type
  TExternalRefObject1 = class
    Padding: array [0 .. 50] of Integer;
  end;

  TExternalRefObject2 = class(TExternalRefObject1)
    Padding2: array [0 .. 50] of Integer;
  end;

  TExternalRefObject3 = class(TExternalRefObject2)
    Padding3: array [0 .. 50] of Integer;
  end;

  TExternalRefObject4 = class(TExternalRefObject3)
    Padding4: array [0 .. 50] of Integer;
  end;

  PLinkedListItem = ^TLinkedListItem;

  TLinkedListItem = record
    Next, Prev: PLinkedListItem;
    List: TList;
    ExternalRef: TExternalRefObject1;
  end;

  TLinkedList = class
    First, Last: PLinkedListItem;
  end;

procedure Dummy; forward;

constructor TLinkedListBench.CreateMemTest;
begin
  inherited;
end;

destructor TLinkedListBench.Destroy;
begin
  inherited;
end;

class function TLinkedListBench.GetMemTestDescription: string;
begin
  Result := 'Allocates a linked list containers and then navigates back and '
    + 'forth through it multiple times.';
end;

class function TLinkedListBench.GetMemTestName: string;
begin
  Result := 'Linked-list container';
end;

class function TLinkedListBench.GetCategory: TMemTestCategory;
begin
  Result := bmMemoryAccessSpeed;
end;

procedure TLinkedListBench.RunMemTest;
var
  i: Integer;
  List: TLinkedList;
  current: PLinkedListItem;
  NextValue: Integer;
begin
  inherited;
  // allocate the list
  NextValue := 199; // prime
  List := TLinkedList.Create;
  New(current);
  current^.Next := nil;
  current^.Prev := nil;
  current^.ExternalRef := TExternalRefObject1.Create;
  List.First := current;
  List.Last := List.First;
  for i := 2 to cNB_LIST_ITEMS do begin
    New(current);
    current^.Next := nil;
    List.Last^.Next := current;
    current^.Prev := List.Last;
    List.Last := current;
    case NextValue mod 4 of // allocate from a small variety of external refs
      0:
        current^.ExternalRef := TExternalRefObject1.Create;
      1:
        current^.ExternalRef := TExternalRefObject2.Create;
      2:
        current^.ExternalRef := TExternalRefObject3.Create;
      3:
        current^.ExternalRef := TExternalRefObject4.Create;
    end;
    Inc(NextValue, 199); // prime
  end;

  // peak usage reached now
  UpdateUsageStatistics;

  // do the bench
  for i := 1 to 100 do begin
    current := List.First;
    while current <> nil do begin
      if current^.ExternalRef.Padding[0] = - 1 then
        Dummy; // access the ExternalRef
      current := current^.Next;
    end;
    current := List.Last;
    while current <> nil do begin
      if current^.ExternalRef.Padding[0] = - 1 then
        Dummy; // access the ExternalRef
      current := current^.Prev;
    end;
  end;

  // cleanup
  current := List.First;
  while current <> nil do begin
    List.First := current^.Next;
    current^.ExternalRef.Free;
    Dispose(current);
    current := List.First;
  end;
  List.Free;
end;

procedure Dummy;
begin
end;

end.

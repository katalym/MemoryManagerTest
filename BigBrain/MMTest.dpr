program MMTest;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  BigBrainUltra,
  BrainWashUltra,
  System.SysUtils,
  Winapi.Windows;

var
  i, n, vOffset: integer;
  vStartTicks: Cardinal;
  vStrings: array of string;
begin
  try

    vStartTicks := GetTickCount;

    for n := 1 to 10 do
    begin
      { Allocate a lot of strings }
      SetLength(vStrings, 3000000);
      for i := Low(vStrings) to High(vStrings) do begin
        { Grab a 20K block }
        SetLength(vStrings[i], 20000);
        { Touch memory }
        vOffset := 1;
        while vOffset <= 20000 do
        begin
          vStrings[i][vOffset] := #1;
          Inc(vOffset, 4096);
        end;
        { Reduce the size to 1 byte }
        SetLength(vStrings[i], 1);
      end;
    end;

    Writeln(GetTickCount - vStartTicks);

  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;

end.

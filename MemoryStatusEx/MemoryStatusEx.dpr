program MemoryStatusEx;

uses
  Vcl.Forms,
  MemoryStatusExFrm in 'MemoryStatusExFrm.pas' {MemoryStatusExForm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMemoryStatusExForm, MemoryStatusExForm);
  Application.Run;
end.

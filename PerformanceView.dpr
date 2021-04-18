program PerformanceView;

{$R *.res}

uses
  VCL.Forms,
  PerformanceFrm in 'PerformanceFrm.pas' {PerformanceForm};

{$IFDEF WIN32}
const
  IMAGE_FILE_LARGE_ADDRESS_AWARE = $0020;
{$SETPEFLAGS IMAGE_FILE_LARGE_ADDRESS_AWARE}
{$ENDIF}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TPerformanceForm, PerformanceForm);
  Application.Run;

end.

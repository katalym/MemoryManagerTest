unit PerformanceFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, VCL.Controls, VCL.Forms, VCL.StdCtrls, VCL.Buttons, VCL.ExtCtrls, VCL.Menus,
  VCL.ActnList, System.Actions, System.ImageList, Vcl.ImgList;

type
  TPerformanceForm = class(TForm)
    actCompareToThisResult: TAction;
    actExcludeFromComparison: TAction;
    actIncludeIntoComparison: TAction;
    actReloadResults: TAction;
    alActions: TActionList;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    btnMoveToRight: TBitBtn;
    btnReloadResults: TBitBtn;
    btnRunSelectedBenchmark: TBitBtn;
    edtUsageReplay: TEdit;
    lblCompareToThisResult: TLabel;
    lblUsageReplay: TLabel;
    lstAvailableResults: TListBox;
    lstBenchmarks: TListBox;
    lstCompareResults: TListBox;
    mniPopupCheckAllDefaultBenchmarks: TMenuItem;
    mniPopupCheckAllThreadedBenchmarks: TMenuItem;
    mniPopupClearAllCheckMarks: TMenuItem;
    mniPopupSelectAllCheckMarks: TMenuItem;
    mniSep: TMenuItem;
    mnuBenchmarks: TPopupMenu;
    Panel1: TPanel;
    pnlCompareToThisResult: TPanel;
    pnlListActions: TPanel;
    pnlResults: TGridPanel;
    pnlTop: TPanel;
    pnlUsage: TPanel;
    Splitter2: TSplitter;
    procedure actCompareToThisResultExecute(Sender: TObject);
    procedure actCompareToThisResultUpdate(Sender: TObject);
    procedure actExcludeFromComparisonExecute(Sender: TObject);
    procedure actExcludeFromComparisonUpdate(Sender: TObject);
    procedure actIncludeIntoComparisonExecute(Sender: TObject);
    procedure actIncludeIntoComparisonUpdate(Sender: TObject);
    procedure actReloadResultsExecute(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    FCompareToThisResult: string;
    FFormActivated: Boolean;
    procedure DoActivateForm;
    procedure DoReloadResults;
    procedure ReadIniFile;
    procedure SetCompareToThisResult(const Value: string);
    procedure WriteIniFile;
  public
    property CompareToThisResult: string read FCompareToThisResult write
        SetCompareToThisResult;
  end;

var
  PerformanceForm: TPerformanceForm;

implementation

uses
  System.IniFiles, System.IOUtils, System.Types, System.StrUtils;

{$R *.dfm}

procedure TPerformanceForm.actCompareToThisResultExecute(Sender: TObject);
begin
  CompareToThisResult := lstCompareResults.Items[lstCompareResults.ItemIndex];
end;

procedure TPerformanceForm.actCompareToThisResultUpdate(Sender: TObject);
begin
  (Sender as TAction).Enabled :=
    (lstCompareResults.Count > 0) and (lstCompareResults.ItemIndex <> -1);
end;

procedure TPerformanceForm.actExcludeFromComparisonExecute(Sender: TObject);
begin
  lstAvailableResults.Items.Add(lstCompareResults.Items[lstCompareResults.ItemIndex]);
  lstCompareResults.Items.Delete(lstCompareResults.ItemIndex);
end;

procedure TPerformanceForm.actExcludeFromComparisonUpdate(Sender: TObject);
begin
  (Sender as TAction).Enabled :=
    (lstCompareResults.Count > 0) and (lstCompareResults.ItemIndex <> -1);
end;

procedure TPerformanceForm.actIncludeIntoComparisonExecute(Sender: TObject);
begin
  lstCompareResults.Items.Add(lstAvailableResults.Items[lstAvailableResults.ItemIndex]);
  lstAvailableResults.Items.Delete(lstAvailableResults.ItemIndex);
end;

procedure TPerformanceForm.actIncludeIntoComparisonUpdate(Sender: TObject);
begin
  (Sender as TAction).Enabled :=
    (lstAvailableResults.Count > 0) and (lstAvailableResults.ItemIndex <> -1);
end;

procedure TPerformanceForm.actReloadResultsExecute(Sender: TObject);
begin
  DoReloadResults;
end;

procedure TPerformanceForm.DoActivateForm;
begin
  FFormActivated := True;
  CompareToThisResult := '';
  DoReloadResults;
end;

procedure TPerformanceForm.DoReloadResults;
var
  vFiles: TStringDynArray;
  vDir, s: string;
begin
  lstAvailableResults.Clear;
  lstCompareResults.Clear;

  vDir := ExtractFilePath(Application.ExeName);
  vFiles := TDirectory.GetFiles(vDir, '*.results.csv', TSearchOption.soAllDirectories);

  for s in vFiles do
    lstAvailableResults.Items.Add(ReplaceText(s, vDir, ''));
end;

procedure TPerformanceForm.FormActivate(Sender: TObject);
begin
  if not FFormActivated then
    DoActivateForm;
end;

procedure TPerformanceForm.FormDestroy(Sender: TObject);
begin

  WriteIniFile;

end;

procedure TPerformanceForm.FormShow(Sender: TObject);
begin
  if not FFormActivated then
  begin
    Height := 900;
    Width := 1200;
    ReadIniFile;
  end;
end;

procedure TPerformanceForm.ReadIniFile;

  function _GetFormMonitorByPosition: Integer;
  var
    i: Integer;
  begin
    Result := 0;
    for i := 0 to Screen.MonitorCount - 1 do
      if (Self.Left >= Screen.Monitors[i].Left) and (Self.Left <= Screen.Monitors[i].Left + Screen.Monitors[i].Width) and
         (Self.Top >= Screen.Monitors[i].Top) and (Self.Top <= Screen.Monitors[i].Top + Screen.Monitors[i].Height) then
      begin
        Result := i;
        Break;
      end;
  end;

  procedure _RestoreFormBounds;
  var
    vMonitorNumber, vLeft, vTop, vHeight, vWidth: Integer;
  begin

    // restore form position and size saved on the last run
    vLeft := Self.Left;
    vTop := Self.Top;
    vHeight := Height;
    vWidth := Width;

    vMonitorNumber := _GetFormMonitorByPosition;

    // if form extends beyongs the monitor lets center it in existed monitor's boundaries
    if vTop + vHeight > Screen.Monitors[vMonitorNumber].Top + Screen.Monitors[vMonitorNumber].Height then
      vTop := Screen.Monitors[vMonitorNumber].Top + Screen.Monitors[vMonitorNumber].Height - vHeight;
    if vLeft + vWidth > Screen.Monitors[vMonitorNumber].Left + Screen.Monitors[vMonitorNumber].Width then
      vLeft := Screen.Monitors[vMonitorNumber].Left + Screen.Monitors[vMonitorNumber].Width - vWidth;

    if vTop < Screen.Monitors[vMonitorNumber].Top then
      vTop := Screen.Monitors[vMonitorNumber].Top;
    if vLeft < Screen.Monitors[vMonitorNumber].Left then
      vLeft := Screen.Monitors[vMonitorNumber].Left;

    // imitate different size of the form to force resize methods to be applied
    if (vLeft = Left) and (vTop = Top) and (vWidth = Width) and (vHeight = Height) then
      SetBounds(vLeft, vTop, vWidth + 1, vHeight);

    SetBounds(vLeft, vTop, vWidth, vHeight);

  end;

var
  vIniFile: TIniFile;
begin
  vIniFile := TIniFile.Create(ChangeFileExt(Application.ExeName, '.ini'));
  try

    Left := vIniFile.ReadInteger('FormSettings', 'Left', Left);
    Top := vIniFile.ReadInteger('FormSettings', 'Top', Top);
    Height := vIniFile.ReadInteger('FormSettings', 'Height', Height);
    Width := vIniFile.ReadInteger('FormSettings', 'Width', Width);
    edtUsageReplay.Text := vIniFile.ReadString('FormSettings', edtUsageReplay.Name, edtUsageReplay.Text);

  finally
    vIniFile.Free;
  end;

  _RestoreFormBounds;

end;

procedure TPerformanceForm.SetCompareToThisResult(const Value: string);
begin
  lstBenchmarks.Clear;
  FCompareToThisResult := Value;
  if not FCompareToThisResult.IsEmpty then
  begin
    lblCompareToThisResult.Caption := FCompareToThisResult + ' is used as for comparison';
    lstBenchmarks.Items.LoadFromFile(FCompareToThisResult);
  end else
    lblCompareToThisResult.Caption := '';
end;

procedure TPerformanceForm.WriteIniFile;
var
  vIniFile: TIniFile;
begin
  vIniFile := TIniFile.Create(ChangeFileExt(Application.ExeName, '.ini'));
  try

    vIniFile.WriteInteger('FormSettings', 'Left', Left);
    vIniFile.WriteInteger('FormSettings', 'Top', Top);
    vIniFile.WriteInteger('FormSettings', 'Height', Height);
    vIniFile.WriteInteger('FormSettings', 'Width', Width);
    vIniFile.WriteString('FormSettings', edtUsageReplay.Name, edtUsageReplay.Text);

  finally
    vIniFile.Free;
  end;

end;

end.

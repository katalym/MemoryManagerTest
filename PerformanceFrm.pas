unit PerformanceFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, VCL.Controls, VCL.Forms, VCL.StdCtrls, VCL.Buttons, VCL.ExtCtrls, VCL.Menus,
  VCL.ActnList, System.Actions, System.ImageList, Vcl.ImgList, Data.DB, Datasnap.DBClient, Vcl.Grids, Vcl.DBGrids;

type
  TPerformanceForm = class(TForm)
    actCompareToThisResult: TAction;
    actExcludeFromComparison: TAction;
    actIncludeIntoComparison: TAction;
    actReloadResults: TAction;
    actSaveComparionResults: TAction;
    alActions: TActionList;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    btnMoveToRight: TBitBtn;
    btnReloadResults: TBitBtn;
    btnSaveComparionResults: TBitBtn;
    cdsCompareTo: TClientDataSet;
    dscCompareTo: TDataSource;
    edtComparisonFileName: TEdit;
    lblCompareToThisResult: TLabel;
    lblComparisonFileName: TLabel;
    lstAvailableResults: TListBox;
    lstMemTests: TDBGrid;
    lstCompareResults: TListBox;
    mniPopupCheckAllDefaultMemTests: TMenuItem;
    mniPopupCheckAllThreadedMemTests: TMenuItem;
    mniPopupClearAllCheckMarks: TMenuItem;
    mniPopupSelectAllCheckMarks: TMenuItem;
    mniSep: TMenuItem;
    mnuMemTests: TPopupMenu;
    Panel1: TPanel;
    pnlCompareToThisResult: TPanel;
    pnlListActions: TPanel;
    pnlResults: TGridPanel;
    pnlTop: TPanel;
    pnlUsage: TPanel;
    procedure actCompareToThisResultExecute(Sender: TObject);
    procedure actCompareToThisResultUpdate(Sender: TObject);
    procedure actExcludeFromComparisonExecute(Sender: TObject);
    procedure actExcludeFromComparisonUpdate(Sender: TObject);
    procedure actIncludeIntoComparisonExecute(Sender: TObject);
    procedure actIncludeIntoComparisonUpdate(Sender: TObject);
    procedure actReloadResultsExecute(Sender: TObject);
    procedure actSaveComparionResultsExecute(Sender: TObject);
    procedure actSaveComparionResultsUpdate(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    FCompareToThisResult: string;
    FFormActivated: Boolean;
    procedure DoActivateForm;
    procedure DoReloadResults;
    procedure LoadTestData;
    procedure PrepareComparisonData;
    procedure ReadIniFile;
    procedure SetCompareToThisResult(const Value: string);
    procedure WriteIniFile;
  public
    property CompareToThisResult: string read FCompareToThisResult write SetCompareToThisResult;
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
  if SameText(CompareToThisResult, lstCompareResults.Items[lstCompareResults.ItemIndex]) then
    CompareToThisResult := '';
  lstAvailableResults.Items.Add(lstCompareResults.Items[lstCompareResults.ItemIndex]);
  lstCompareResults.Items.Delete(lstCompareResults.ItemIndex);
  PrepareComparisonData;
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
  PrepareComparisonData;
end;

procedure TPerformanceForm.actIncludeIntoComparisonUpdate(Sender: TObject);
begin
  (Sender as TAction).Enabled :=
    (lstAvailableResults.Count > 0) and (lstAvailableResults.ItemIndex <> -1);
end;

procedure TPerformanceForm.actReloadResultsExecute(Sender: TObject);
begin
  DoReloadResults;
  PrepareComparisonData;
end;

procedure TPerformanceForm.actSaveComparionResultsExecute(Sender: TObject);
var
  vData: TStringList;
  i: integer;
  s: string;
begin
  //create a new file
  vData := TStringList.Create;
  try

    s := ''; //initialize empty string

    //write field names (as column headers)
    for i := 0 to cdsCompareTo.FieldCount - 1 do begin
      s := s + Format('"%s";', [cdsCompareTo.Fields[i].DisplayLabel]);
    end;
    vData.Add(s);

    cdsCompareTo.First;
    while not cdsCompareTo.Eof do begin
      s := '';
      for i := 0 to cdsCompareTo.FieldCount - 1 do begin
        s := s + Format('"%s";', [cdsCompareTo.Fields[i].AsString]);
      end;
      vData.Add(s);
      cdsCompareTo.Next;
    end;

    vData.SaveToFile(Trim(edtComparisonFileName.Text));

  finally
    vData.Free;
  end;
end;

procedure TPerformanceForm.actSaveComparionResultsUpdate(Sender: TObject);
begin
  (Sender as TAction).Enabled :=
    (cdsCompareTo.Active) and (cdsCompareTo.RecordCount > 0) and not Trim(edtComparisonFileName.Text).IsEmpty;
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
  CompareToThisResult := '';
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

procedure TPerformanceForm.LoadTestData;

  function _GetTestName(const aTestFileName: string): string;
  begin
    Result := ExtractFileName(aTestFileName);
    Result := ReplaceText(Result, 'MemoryManagerTest_', '');
    Result := Copy(Result, 1, pos('.', Result) - 1);
  end;

var
  vData: TStringList;
  s, vMM, vMMCompareTo, vResFile: string;
  vDyn: TStringDynArray;
  vField: TField;
begin

  cdsCompareTo.Fields.Clear;
  cdsCompareTo.FieldDefs.Clear;
  cdsCompareTo.IndexDefs.Clear;
  vMMCompareTo := _GetTestName(FCompareToThisResult);

  vField := TStringField.Create(cdsCompareTo);
  vField.DisplayWidth := 40;
  vField.FieldName := 'Test';
  vField.Size := 80;
  vField.DataSet := cdsCompareTo;

  vField := TStringField.Create(cdsCompareTo);
  vField.DisplayWidth := 15;
  vField.DisplayLabel := 'Manager';
  vField.FieldName := 'MemoryManager';
  vField.Size := 40;
  vField.DataSet := cdsCompareTo;
  vField.Visible := False;

  vField := TIntegerField.Create(cdsCompareTo);
  (vField as TIntegerField).DisplayFormat := '0,0.';
  vField.DisplayLabel := 'CPU(ms) ' + vMMCompareTo;
  vField.FieldName := 'CPU' + vMMCompareTo;
  vField.DataSet := cdsCompareTo;

  vField := TIntegerField.Create(cdsCompareTo);
  (vField as TIntegerField).DisplayFormat := '0,0.';
  vField.DisplayLabel := 'Ticks(ms) ' + vMMCompareTo;
  vField.FieldName := 'Ticks' + vMMCompareTo;
  vField.DataSet := cdsCompareTo;

  vField := TIntegerField.Create(cdsCompareTo);
  (vField as TIntegerField).DisplayFormat := '0,0.';
  vField.DisplayLabel := 'Memory(Kb) ' + vMMCompareTo;
  vField.FieldName := 'Memory' + vMMCompareTo;
  vField.DataSet := cdsCompareTo;

  for vResFile in lstCompareResults.Items do begin
    if not SameText(vResFile, FCompareToThisResult) then
    begin
      vMM := _GetTestName(vResFile);

      vField := TCurrencyField.Create(cdsCompareTo);
      (vField as TCurrencyField).DisplayFormat := ',0.0';
      vField.DisplayLabel := 'CPU(%) ' + vMM;
      vField.FieldName := 'CPU' + vMM;
      vField.DataSet := cdsCompareTo;

      vField := TCurrencyField.Create(cdsCompareTo);
      (vField as TCurrencyField).DisplayFormat := ',0.0';
      vField.DisplayLabel := 'Ticks(%) ' + vMM;
      vField.FieldName := 'Ticks' + vMM;
      vField.DataSet := cdsCompareTo;

      vField := TCurrencyField.Create(cdsCompareTo);
      (vField as TCurrencyField).DisplayFormat := ',0.0';
      vField.DisplayLabel := 'Memory(%) ' + vMM;
      vField.FieldName := 'Memory' + vMM;
      vField.DataSet := cdsCompareTo;
    end;
  end;

  cdsCompareTo.CreateDataSet;
  cdsCompareTo.AddIndex('a', 'Test', [ixCaseInsensitive, ixUnique]);
  cdsCompareTo.IndexName := 'a';

  if FileExists(FCompareToThisResult) then
  begin
    vData := TStringList.Create;
    try
      vData.LoadFromFile(FCompareToThisResult);
      for s in vData do begin
        vDyn := SplitString(s, ';');
        cdsCompareTo.Append;
        cdsCompareTo.FieldByName('Test').Value := ReplaceText(vDyn[0], '"', '');
        cdsCompareTo.FieldByName('MemoryManager').Value := vDyn[1];
        cdsCompareTo.FieldByName('CPU' + vMMCompareTo).Value := vDyn[2];
        cdsCompareTo.FieldByName('Ticks' + vMMCompareTo).Value := vDyn[3];
        cdsCompareTo.FieldByName('Memory' + vMMCompareTo).Value := vDyn[4];
      end;
      cdsCompareTo.Post;

      for vResFile in lstCompareResults.Items do begin
        if not SameText(vResFile, FCompareToThisResult) then
        begin
          vMM := _GetTestName(vResFile);

          vData.LoadFromFile(vResFile);
          for s in vData do begin
            vDyn := SplitString(s, ';');
            if cdsCompareTo.Locate('Test', ReplaceText(vDyn[0], '"', ''), []) then
            begin
              cdsCompareTo.Edit;
              if cdsCompareTo.FieldByName('CPU' + vMMCompareTo).Value > 0 then
                cdsCompareTo.FieldByName('CPU' + vMM).Value :=
                  vDyn[2].ToInteger * 100 / cdsCompareTo.FieldByName('CPU' + vMMCompareTo).Value;
              if cdsCompareTo.FieldByName('Ticks' + vMMCompareTo).Value > 0 then
                cdsCompareTo.FieldByName('Ticks' + vMM).Value :=
                  vDyn[3].ToInteger * 100 / cdsCompareTo.FieldByName('Ticks' + vMMCompareTo).Value;
              if cdsCompareTo.FieldByName('Memory' + vMMCompareTo).Value > 0 then
                cdsCompareTo.FieldByName('Memory' + vMM).Value :=
                  vDyn[4].ToInteger * 100 / cdsCompareTo.FieldByName('Memory' + vMMCompareTo).Value;
              cdsCompareTo.Post;
            end;
          end;
        end;
      end;

    finally
      vData.Free;
    end;
    cdsCompareTo.First;
  end;
end;

procedure TPerformanceForm.PrepareComparisonData;
begin
  if cdsCompareTo.Active then
  begin
    cdsCompareTo.IndexName := '';
    cdsCompareTo.EmptyDataSet;
    cdsCompareTo.Close;
  end;
  if not FCompareToThisResult.IsEmpty then
  begin
    lblCompareToThisResult.Caption := FCompareToThisResult + ' is used as for comparison';
    LoadTestData;
  end else
    lblCompareToThisResult.Caption := '';
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
    edtComparisonFileName.Text := vIniFile.ReadString('FormSettings', edtComparisonFileName.Name, edtComparisonFileName.Text);

  finally
    vIniFile.Free;
  end;

  _RestoreFormBounds;

end;

procedure TPerformanceForm.SetCompareToThisResult(const Value: string);
begin
  FCompareToThisResult := Value;
  PrepareComparisonData;
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
    vIniFile.WriteString('FormSettings', edtComparisonFileName.Name, edtComparisonFileName.Text);

  finally
    vIniFile.Free;
  end;

end;

end.

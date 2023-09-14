unit MemoryManagerForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, VCL.Controls, VCL.Forms,
  VCL.StdCtrls, MemTestClassUnit, Math, VCL.Buttons,
  VCL.ExtCtrls, VCL.ComCtrls, VCL.Clipbrd, VCL.Menus, System.Actions,
  VCL.ActnList, System.ImageList, VCL.ImgList, VCL.ToolWin;

type
  TMemoryManagerFrm = class(TForm)
    actCopyResultsToClipboard: TAction;
    actDeletelTestResults: TAction;
    actPopupCheckAllDefaultMemTests: TAction;
    actPopupCheckAllThreadedMemTests: TAction;
    actPopupClearAllCheckMarks: TAction;
    actPopupSelectAllCheckMarks: TAction;
    actRunAllCheckedMemTests: TAction;
    actRunUsageReplayMemTest: TAction;
    alActions: TActionList;
    btnCopyResultsToClipboard: TToolButton;
    btnDeleteTestResults: TToolButton;
    btnRunAllCheckedMemTests: TBitBtn;
    btnRunSelectedMemTest: TBitBtn;
    edtUsageReplay: TEdit;
    gbMemTests: TGroupBox;
    imlImages: TImageList;
    lblUsageReplay: TLabel;
    ListViewResults: TListView;
    lvMemTestList: TListView;
    mMemTestDescription: TMemo;
    MemoEnvironment: TMemo;
    mniPopupCheckAllDefaultMemTests: TMenuItem;
    mniPopupCheckAllThreadedMemTests: TMenuItem;
    mniPopupClearAllCheckMarks: TMenuItem;
    mniPopupSelectAllCheckMarks: TMenuItem;
    mniSep: TMenuItem;
    mnuMemTests: TPopupMenu;
    mResults: TMemo;
    pcMemTestResults: TPageControl;
    pnlUsage: TPanel;
    Splitter2: TSplitter;
    TabSheetMemTestResults: TTabSheet;
    TabSheetCPU: TTabSheet;
    TabSheetProgress: TTabSheet;
    tmrAutoRun: TTimer;
    ToolBar1: TToolBar;
    N1: TMenuItem;
    mniRunAllCheckedMemTests: TMenuItem;
    mniRunUsageReplayMemTest: TMenuItem;
    procedure actCopyResultsToClipboardExecute(Sender: TObject);
    procedure actDeletelTestResultsExecute(Sender: TObject);
    procedure actPopupCheckAllDefaultMemTestsExecute(Sender: TObject);
    procedure actPopupCheckAllThreadedMemTestsExecute(Sender: TObject);
    procedure actPopupClearAllCheckMarksExecute(Sender: TObject);
    procedure actPopupSelectAllCheckMarksExecute(Sender: TObject);
    procedure actRunAllCheckedMemTestsExecute(Sender: TObject);
    procedure actRunUsageReplayMemTestExecute(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure lvMemTestListSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
    procedure tmrAutoRunTimer(Sender: TObject);
  private
    FApplicationIniFileName: string;
    FMemTestHasBeenRun: Boolean;
    FFormActivated: Boolean;
    FRanMemTestCount: Integer;
    FTestDescriptionMaxSize: integer;
    FTestResultsFileName: string;
    procedure AddResultsToDisplay(
      const aBenchName, aMMName: string;
      const aCpuUsage: Int64;
      const aTicks, aPeak: NativeUInt);
    procedure DoActivateForm;
    procedure InitResultsDisplay;
    procedure LoadResultsToDisplay;
    procedure ReadIniFile;
    procedure RunMemTests(const aMemTestClass: TMemTestClass);
    procedure SaveResults;
    procedure WriteIniFile;
  end;

var
  MemoryManagerFrm: TMemoryManagerFrm;

const
  // Column indices for the ListView
  LVCOL_BENCH    = 0;
  LVCOL_MM       = 1;
  LVCOL_CPUUSAGE = 2;
  LVCOL_TICKS    = 3;
  LVCOL_MEM      = 4;

  // ListView Subitem Indices
  LVSI_MM       = 0;
  LVSI_CPUUSAGE = 1;
  LVSI_TICKS    = 2;
  LVSI_MEM      = 3;

  // Order of columns in the Results File
  RESULTS_BENCH    = 0;
  RESULTS_MM       = 1;
  RESULTS_CPUUSAGE = 2;
  RESULTS_TICKS    = 3;
  RESULTS_MEM      = 4;

implementation

uses
  MemTestUtilities, SystemInfoUnit, System.IniFiles, CPU_Usage_Unit, System.StrUtils,
  VCL.Dialogs, ReplayMemTestUnit, bvDataTypes;

{$R *.dfm}

procedure TMemoryManagerFrm.actCopyResultsToClipboardExecute(Sender: TObject);
var
  iRow: Integer;
  iCol: Integer;
  StringList: TStringList;
  s: string;
  Item: TListItem;
begin
  // The tab-delimited data dropped to the clipboard can be pasted into
  // Excel and will generally auto-separate itself into columns.
  StringList := TStringList.Create;
  try
    // Header
    s := '';
    for iCol := 0 to ListViewResults.Columns.Count - 1 do
      s := s + #9 + ListViewResults.Column[iCol].Caption;
    Delete(s, 1, 1); // delete initial #9 character
    StringList.Add(s);

    // Body
    for iRow := 0 to ListViewResults.Items.Count - 1 do begin
      Item := ListViewResults.Items[iRow];
      s := Item.Caption;
      for iCol := 0 to Item.SubItems.Count - 1 do
        s := s + #9 + Item.SubItems[iCol];
      StringList.Add(s);
    end;

    Clipboard.AsText := StringList.Text;
  finally
    StringList.Free;
  end;
end;

procedure TMemoryManagerFrm.actDeletelTestResultsExecute(Sender: TObject);
begin
  begin
    ListViewResults.Items.BeginUpdate;
    try
      ListViewResults.Items.Clear;
    finally
      ListViewResults.Items.EndUpdate;
    end;
    DeleteFile(FTestResultsFileName);
    FRanMemTestCount := 0;
  end;
end;

procedure TMemoryManagerFrm.actPopupCheckAllDefaultMemTestsExecute(Sender: TObject);
var
  i: Integer;
begin
  for i := 0 to lvMemTestList.Items.Count - 1 do
    lvMemTestList.Items[i].Checked := MemTests[i].RunByDefault;
end;

procedure TMemoryManagerFrm.actPopupCheckAllThreadedMemTestsExecute(Sender: TObject);
var
  i: Integer;
begin
  for i := 0 to lvMemTestList.Items.Count - 1 do
    lvMemTestList.Items[i].Checked := MemTests[i].IsThreadedSpecial;
end;

procedure TMemoryManagerFrm.actPopupClearAllCheckMarksExecute(Sender: TObject);
var
  i: Integer;
begin
  for i := 0 to lvMemTestList.Items.Count - 1 do
    lvMemTestList.Items[i].Checked := False;
end;

procedure TMemoryManagerFrm.actPopupSelectAllCheckMarksExecute(Sender: TObject);
var
  i: Integer;
begin
  for i := 0 to lvMemTestList.Items.Count - 1 do
    lvMemTestList.Items[i].Checked := True;
end;

procedure TMemoryManagerFrm.actRunAllCheckedMemTestsExecute(Sender: TObject);
var
  i: Integer;
begin
  Screen.Cursor := crHourglass;
  actRunAllCheckedMemTests.Caption := 'Running';
  Enabled := False;
  Application.ProcessMessages;
  Enabled := True;
  mResults.Lines.Add('***Running All Checked MemTests***');
  try

    for i := 0 to MemTests.Count - 1 do begin
      // Must this MemTest be run?
      if lvMemTestList.Items[i].Checked then
      begin
        // Show progress in checkboxlist
        lvMemTestList.Items[i].Selected := True;
        lvMemTestList.Items[i].Focused := True;
        lvMemTestList.Selected.MakeVisible(False);
        lvMemTestListSelectItem(nil, lvMemTestList.Selected, lvMemTestList.Selected <> nil);
        Enabled := False;
        Application.ProcessMessages;
        Enabled := True;
        // Run the MemTest
        RunMemTests(MemTests[i]);
        // Wait one second
        Sleep(1000);
      end;
    end;
    mResults.Lines.Add('***All Checked MemTests Done***');

  finally
    actRunAllCheckedMemTests.Caption := 'Run All Checked MemTests';
    Screen.Cursor := crDefault;
  end;
  if FRanMemTestCount > 0 then
    SaveResults;
end;

procedure TMemoryManagerFrm.actRunUsageReplayMemTestExecute(Sender: TObject);
begin
  Screen.Cursor := crHourglass;

  if lvMemTestList.Selected = nil then
    Exit;

  Enabled := False;
  Application.ProcessMessages;
  Enabled := True;
  try

    RunMemTests(TReplayMemTest);

    if FRanMemTestCount > 0 then
      SaveResults;

  finally
    Enabled := False;
    Application.ProcessMessages;
    Enabled := True;
    Screen.Cursor := crDefault;
  end;
end;

procedure TMemoryManagerFrm.AddResultsToDisplay(
  const aBenchName, aMMName: string;
  const aCpuUsage: Int64;
  const aTicks, aPeak: NativeUInt);
var
  Item: TListItem;
begin
  Inc(FRanMemTestCount);

  Item := ListViewResults.Items.Add;
  Item.Caption := aBenchName;
  Item.SubItems.Add(aMMName);
  Item.SubItems.Add(aCpuUsage.ToString);
  Item.SubItems.Add(aTicks.ToString);
  Item.SubItems.Add(aPeak.ToString);

  // if not InitialLoad then
  // ListViewResults.AlphaSort;
end;

procedure TMemoryManagerFrm.DoActivateForm;
var
  i: Integer;
  vItem: TListItem;
  vMemTest: TMemTestClass;
begin
  FFormActivated := True;

  MemoEnvironment.Lines.Clear;
  MemoEnvironment.Lines.Add(SystemInfoCPU);
  MemoEnvironment.Lines.Add('****************');
  MemoEnvironment.Lines.Add(SystemInfoWindows);

  FMemTestHasBeenRun := False;
  FTestDescriptionMaxSize := 0;

  lvMemTestList.SortType := stNone; // Do not perform extra sort - already sorted
  // List the MemTests
  for i := 0 to MemTests.Count - 1 do begin
    vMemTest := MemTests[i];
    vItem := lvMemTestList.Items.Add;
    vItem.Data := Pointer(i);
    if Assigned(vMemTest) then
    begin
      vItem.Checked := vMemTest.RunByDefault;
      vItem.Caption := vMemTest.GetMemTestName;
      FTestDescriptionMaxSize := Max(FTestDescriptionMaxSize, Length(vMemTest.GetMemTestName));
      vItem.SubItems.Add(MemTestCategoryNames[vMemTest.GetCategory]);
    end;
  end;

  if lvMemTestList.Items.Count > 0 then
  begin
    // Select the first MemTest
    lvMemTestList.Items[0].Selected := True;
    lvMemTestList.Items[0].Focused := True;
    // Set the MemTest description.
    lvMemTestListSelectItem(nil, lvMemTestList.Selected, lvMemTestList.Selected <> nil);
  end;

  InitResultsDisplay;

  pcMemTestResults.ActivePage := TabSheetMemTestResults;

  tmrAutoRun.Enabled := ParamCount > 0;

end;

procedure TMemoryManagerFrm.FormActivate(Sender: TObject);
begin
  if not FFormActivated then
    DoActivateForm;
end;

procedure TMemoryManagerFrm.FormCreate(Sender: TObject);
var
  vCustomExeName: string;
begin
  // make a copy of the application's Exe for later use
  // Skip copy if this is the MM specific exe.
  if not ContainsText(ExtractFileName(Application.ExeName), '_' + MemoryManager_Name + '_') then
  begin
    vCustomExeName := Format('%0:s%2:s\Win%3:s\%1:s_%2:s_%3:s.exe',
      [ExtractFilePath(Application.ExeName), ChangeFileExt(ExtractFileName(Application.ExeName), ''),
      MemoryManager_Name, {$IFDEF WIN32}'32'{$ELSE}'64'{$ENDIF}]);
    CopyFile(PChar(GetModuleName(HInstance)), PChar(vCustomExeName), False);
  end
  else
    vCustomExeName := Application.ExeName;

  FApplicationIniFileName :=
    ReplaceText(ExtractFilePath(vCustomExeName), '\' + MemoryManager_Name + '\Win' + {$IFDEF WIN32}'32'{$ELSE}'64'{$ENDIF}, '') +
    'MemoryManagerTest.ini';

  FTestResultsFileName := Format('%s.csv', [ChangeFileExt(vCustomExeName, '.Results')]);

end;

procedure TMemoryManagerFrm.FormDestroy(Sender: TObject);
begin

  WriteIniFile;

  if FRanMemTestCount > 0 then
    SaveResults;

end;

procedure TMemoryManagerFrm.FormShow(Sender: TObject);
begin
  if not FFormActivated then
  begin
    Caption := Format('%s %s %s for "%s" memory manager', [Caption, {$IFDEF WIN32}'32-bit'{$ELSE}'64-bit'{$ENDIF}, GetFormattedVersion, MemoryManager_Name]);
    Height := 900;
    Width := 1200;
    ReadIniFile;
  end;
end;

procedure TMemoryManagerFrm.InitResultsDisplay;
begin
  ListViewResults.Items.BeginUpdate;
  try
    ListViewResults.Items.Clear;
  finally
    ListViewResults.Items.EndUpdate;
  end;

  FRanMemTestCount := 0;
  LoadResultsToDisplay;

  ListViewResults.Column[LVCOL_BENCH].Width := 240;
  ListViewResults.Column[LVCOL_MM].Width := 100;
  ListViewResults.Column[LVCOL_CPUUSAGE].Width := 90;
  ListViewResults.Column[LVCOL_TICKS].Width := 90;
  ListViewResults.Column[LVCOL_MEM].Width := 120;

end;

procedure TMemoryManagerFrm.LoadResultsToDisplay;
var
  CSV, Bench: TStringList;
  l: Integer;
  BenchName, MMName: string;
  vCPUUsage: Int64;
  vTicks, vPeak: Cardinal;
begin
  if not FileExists(FTestResultsFileName) then
    Exit;

  CSV := TStringList.Create;
  Bench := TStringList.Create;
  try
    Bench.Delimiter := ';';

    CSV.LoadFromFile(FTestResultsFileName);

    ListViewResults.Items.BeginUpdate;
    try
      for l := 0 to CSV.Count - 1 do
      begin
        Bench.DelimitedText := CSV[l];
        if Bench.Count < 4 then
          Continue;

        BenchName := Bench[RESULTS_BENCH];
        if Trim(BenchName) = '' then
          Continue;

        MMName := Bench[RESULTS_MM];
        vCPUUsage := Max(StrToIntDef(Bench[RESULTS_CPUUSAGE], 0), 0);
        vTicks := bvIntToCardinal(Max(StrToIntDef(Bench[RESULTS_TICKS], 0), 0));
        vPeak := bvIntToCardinal(Max(StrToIntDef(Bench[RESULTS_MEM], 0), 0));

        AddResultsToDisplay(BenchName, MMName, vCPUUsage, vTicks, vPeak);
      end;
    finally
      ListViewResults.Items.EndUpdate;
    end;

    // ListViewResults.AlphaSort;

    if ListViewResults.Items.Count > 0 then
    begin
      ListViewResults.Items[0].Selected := True;
      ListViewResults.Items[0].Focused := True;
    end;
  finally
    Bench.Free;
    CSV.Free;
  end;
end;

procedure TMemoryManagerFrm.lvMemTestListSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
var
  LMemTestClass: TMemTestClass;
begin
  // Set the MemTest description
  if (Item <> nil) and Selected then
  begin
    LMemTestClass := MemTests[bvNativeIntToInt(NativeInt(Item.Data))];
    if Assigned(LMemTestClass) then
    begin
      mMemTestDescription.Text := LMemTestClass.GetMemTestDescription;
    end;
  end;
end;

procedure TMemoryManagerFrm.ReadIniFile;

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
  vIniFile := TIniFile.Create(FApplicationIniFileName);
  try

    Left := vIniFile.ReadInteger('FormSettings', 'Left', Left);
    Top := vIniFile.ReadInteger('FormSettings', 'Top', Top);
    Height := vIniFile.ReadInteger('FormSettings', 'Height', Height);
    Width := vIniFile.ReadInteger('FormSettings', 'Width', Width);
    edtUsageReplay.Text := vIniFile.ReadString('FormSettings', edtUsageReplay.Name, edtUsageReplay.Text);
    MemTestClassUnit.gUsageReplayFileName := edtUsageReplay.Text;

  finally
    vIniFile.Free;
  end;

  _RestoreFormBounds;

end;

procedure TMemoryManagerFrm.RunMemTests(const aMemTestClass: TMemTestClass);
var
  vMemTest: TMemTest;
  vStartCPUUsage, vCurrentCPUUsage: Int64;
  vStartTicks, vCurrentTicks: Cardinal;
  s: string;
begin
  try
    pcMemTestResults.ActivePage := TabSheetProgress;

    s := Trim(Trim(FormatDateTime('HH:nn:ss', time)) + ' Running : ' + aMemTestClass.GetMemTestName + '...');
    mResults.Lines.Add(s);
    // Create the MemTest
    vMemTest := aMemTestClass.CreateMemTest;
    try
      if vMemTest.CanRunMemTest then
      begin
        // performance data
        vMemTest.PrepareMemTestForRun(edtUsageReplay.Text);
        vStartCPUUsage := CPU_Usage_Unit.GetCpuUsage_Total;
        vStartTicks := GetTickCount;
        vMemTest.RunMemTest;
        vCurrentCPUUsage := CPU_Usage_Unit.GetCpuUsage_Total - vStartCPUUsage - vMemTest.FExcludeThisCPUUsage;
        vCurrentTicks := GetTickCount - vStartTicks - vMemTest.FExcludeThisTicks;

        // Add a line
        mResults.Lines[mResults.Lines.Count - 1] := // Trim(Trim(FormatDateTime('HH:nn:ss', time)) + ' '
          Format('%-' + FTestDescriptionMaxSize.ToString + 's | CPU Usage(ms) = %7d | Ticks(ms)=%7d | Peak Address Space Usage(Kb) = %7d',
          [aMemTestClass.GetMemTestName.Trim, vCurrentCPUUsage, vCurrentTicks, vMemTest.PeakAddressSpaceUsage]);
        Enabled := False;
        Application.ProcessMessages;
        Enabled := True;

        AddResultsToDisplay(aMemTestClass.GetMemTestName,
          MemoryManager_Name,
          vCurrentCPUUsage,
          vCurrentTicks,
          vMemTest.PeakAddressSpaceUsage);
        if not FMemTestHasBeenRun then
        begin
          FMemTestHasBeenRun := True;
        end;
      end
      else
      begin
        mResults.Lines[mResults.Lines.Count - 1] := Trim(aMemTestClass.GetMemTestName) + ': Skipped';
        Enabled := False;
        Application.ProcessMessages;
        Enabled := True;
      end;
    finally
      // Free the MemTest
      FreeAndNil(vMemTest);
    end;

  except
    on E: Exception do begin
      ShowMessage('Test for ' + aMemTestClass.GetMemTestName + ' failed with error:'#13 + E.Message);
      Abort;
    end;
  end;
end;

procedure TMemoryManagerFrm.SaveResults;
var
  CSV, Bench: TStringList;
  i: Integer;
begin
  CSV := TStringList.Create;

  Bench := TStringList.Create;
  try
    Bench.Delimiter := ';';

    for i := 0 to ListViewResults.Items.Count - 1 do
    begin
      Bench.Clear;

      Bench.Add(ListViewResults.Items[i].Caption);
      Bench.Add(ListViewResults.Items[i].SubItems[LVSI_MM]);
      Bench.Add(ListViewResults.Items[i].SubItems[LVSI_CPUUSAGE]);
      Bench.Add(ListViewResults.Items[i].SubItems[LVSI_TICKS]);
      Bench.Add(ListViewResults.Items[i].SubItems[LVSI_MEM]);

      CSV.Add(Bench.DelimitedText);
    end;

    CSV.SaveToFile(FTestResultsFileName);
  finally
    Bench.Free;
    CSV.Free;
  end;
end;

procedure TMemoryManagerFrm.tmrAutoRunTimer(Sender: TObject);
begin
  tmrAutoRun.Enabled := False;
  actDeletelTestResults.Execute;
  Application.ProcessMessages;
  actRunAllCheckedMemTests.Execute;
  Application.ProcessMessages;
  Close;
end;

procedure TMemoryManagerFrm.WriteIniFile;
var
  vIniFile: TIniFile;
begin
  vIniFile := TIniFile.Create(FApplicationIniFileName);
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

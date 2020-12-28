unit BenchmarkForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, VCL.Controls, VCL.Forms,
  VCL.StdCtrls, BenchmarkClassUnit, Math, VCL.Buttons,
  VCL.ExtCtrls, VCL.ComCtrls, VCL.Clipbrd, VCL.Menus, System.Actions,
  Vcl.ActnList, System.ImageList, Vcl.ImgList, Vcl.ToolWin;

type
  TBenchmarkFrm = class(TForm)
    actCopyResultsToClipboard: TAction;
    actDeletelTestResults: TAction;
    actPopupCheckAllDefaultBenchmarks: TAction;
    actPopupCheckAllThreadedBenchmarks: TAction;
    actPopupClearAllCheckMarks: TAction;
    actPopupSelectAllCheckMarks: TAction;
    actRunAllCheckedBenchmarks: TAction;
    actRunSelectedBenchmark: TAction;
    alActions: TActionList;
    btnClose: TBitBtn;
    btnCopyResultsToClipboard: TToolButton;
    btnDeleteTestResults: TToolButton;
    btnRunAllCheckedBenchmarks: TBitBtn;
    btnRunSelectedBenchmark: TBitBtn;
    gbBenchmarks: TGroupBox;
    imlImages: TImageList;
    ListViewResults: TListView;
    lvBenchmarkList: TListView;
    mBenchmarkDescription: TMemo;
    MemoEnvironment: TMemo;
    mniPopupCheckAllDefaultBenchmarks: TMenuItem;
    mniPopupCheckAllThreadedBenchmarks: TMenuItem;
    mniPopupClearAllCheckMarks: TMenuItem;
    mniPopupSelectAllCheckMarks: TMenuItem;
    mniSep: TMenuItem;
    mnuBenchmarks: TPopupMenu;
    mResults: TMemo;
    pcBenchmarkResults: TPageControl;
    pnlButtons: TPanel;
    Splitter2: TSplitter;
    TabSheetBenchmarkResults: TTabSheet;
    TabSheetCPU: TTabSheet;
    TabSheetProgress: TTabSheet;
    tmrAutoRun: TTimer;
    ToolBar1: TToolBar;
    procedure actCopyResultsToClipboardExecute(Sender: TObject);
    procedure actDeletelTestResultsExecute(Sender: TObject);
    procedure actPopupCheckAllDefaultBenchmarksExecute(Sender: TObject);
    procedure actPopupCheckAllThreadedBenchmarksExecute(Sender: TObject);
    procedure actPopupClearAllCheckMarksExecute(Sender: TObject);
    procedure actPopupSelectAllCheckMarksExecute(Sender: TObject);
    procedure actRunAllCheckedBenchmarksExecute(Sender: TObject);
    procedure actRunSelectedBenchmarkExecute(Sender: TObject);
    procedure FormClose(Sender: TObject; var AAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure lvBenchmarkListSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
    procedure tmrAutoRunTimer(Sender: TObject);
  private
    FBenchmarkHasBeenRun: Boolean;
    FRanBenchmarkCount: Integer;
    FTestResultsFileName: string;
    FApplicationIniFileName: string;
    procedure AddResultsToDisplay(
      const aBenchName, aMMName: String;
      const aCpuUsage: Int64;
      const aTicks, aPeak: Cardinal;
      const CurrentSession: string = 'T';
      const InitialLoad: Boolean = False);
    procedure InitResultsDisplay;
    procedure LoadResultsToDisplay;
    procedure ReadIniFile;
    procedure RunBenchmarks(ABenchmarkClass: TFastcodeMMBenchmarkClass);
    procedure SaveResults;
    procedure WriteIniFile;
  public
  end;

var
  BenchmarkFrm: TBenchmarkFrm;

Const
  //Column indices for the ListView
  LVCOL_BENCH     = 0;
  LVCOL_MM        = 1;
  LVCOL_CPUUSAGE  = 2;
  LVCOL_TICKS     = 3;
  LVCOL_MEM       = 4;

  //ListView Subitem Indices
  LVSI_MM        = 0;
  LVSI_CPUUSAGE  = 1;
  LVSI_TICKS     = 2;
  LVSI_MEM       = 3;

  //Order of columns in the Results File
  RESULTS_BENCH   = 0;
  RESULTS_MM      = 1;
  RESULTS_CPUUSAGE = 2;
  RESULTS_TICKS   = 3;
  RESULTS_MEM     = 4;

implementation

uses
  BenchmarkUtilities, GeneralFunctions, SystemInfoUnit, System.IniFiles, CPU_Usage_Unit, System.StrUtils;

{$R *.dfm}

procedure TBenchmarkFrm.actCopyResultsToClipboardExecute(Sender: TObject);
var
  iRow: Integer;
  iCol: Integer;
  StringList: TStringList;
  s: string;
  Item: TListItem;
begin
  //The tab-delimited data dropped to the clipboard can be pasted into
  // Excel and will generally auto-separate itself into columns.
  StringList := TStringList.Create;
  try
    //Header
    s := '';
    for iCol := 0 to ListViewResults.Columns.Count - 1 do
      s := s + #9 + ListViewResults.Column[iCol].Caption;
    Delete(s, 1, 1); // delete initial #9 character
    StringList.Add(s);

    //Body
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

procedure TBenchmarkFrm.actDeletelTestResultsExecute(Sender: TObject);
begin
  begin
    ListViewResults.Items.BeginUpdate;
    try
      ListViewResults.Items.Clear;
    finally
      ListViewResults.Items.EndUpdate;
    end;
    DeleteFile(FTestResultsFileName);
    FRanBenchmarkCount := 0;
  end;
end;

procedure TBenchmarkFrm.actPopupCheckAllDefaultBenchmarksExecute(Sender: TObject);
var
  i: Integer;
begin
  for i := 0 to lvBenchmarkList.Items.Count - 1 do
    lvBenchmarkList.Items[i].Checked := Benchmarks[i].RunByDefault;
end;

procedure TBenchmarkFrm.actPopupCheckAllThreadedBenchmarksExecute(Sender: TObject);
var
  i: Integer;
begin
  for i := 0 to lvBenchmarkList.Items.Count - 1 do
    lvBenchmarkList.Items[i].Checked := Benchmarks[i].IsThreadedSpecial;
end;

procedure TBenchmarkFrm.actPopupClearAllCheckMarksExecute(Sender: TObject);
var
  i: Integer;
begin
  for i := 0 to lvBenchmarkList.Items.Count - 1 do
    lvBenchmarkList.Items[i].Checked := False;
end;

procedure TBenchmarkFrm.actPopupSelectAllCheckMarksExecute(Sender: TObject);
var
  i: Integer;
begin
  for i := 0 to lvBenchmarkList.Items.Count - 1 do
    lvBenchmarkList.Items[i].Checked := True;
end;

procedure TBenchmarkFrm.actRunAllCheckedBenchmarksExecute(Sender: TObject);
var
  i: integer;
begin
  Screen.Cursor := crHourglass;
  actRunAllCheckedBenchmarks.Caption := 'Running';
  Enabled := False;
  Application.ProcessMessages;
  Enabled := True;
  mResults.Lines.Add('***Running All Checked Benchmarks***');
  for i := 0 to Benchmarks.Count - 1 do begin
    {Must this benchmark be run?}
    if lvBenchmarkList.Items[i].Checked then
    begin
      {Show progress in checkboxlist}
      lvBenchmarkList.Items[i].Selected := True;
      lvBenchmarkList.Items[i].Focused  := True;
      lvBenchmarkList.Selected.MakeVisible(False);
      lvBenchmarkListSelectItem(nil, lvBenchmarkList.Selected, lvBenchmarkList.Selected <> nil);
      Enabled := False;
      Application.ProcessMessages;
      Enabled := True;
      {Run the benchmark}
      RunBenchmarks(Benchmarks[i]);
      {Wait one second}
      Sleep(1000);
    end;
  end;
  mResults.Lines.Add('***All Checked Benchmarks Done***');
  actRunAllCheckedBenchmarks.Caption := 'Run All Checked Benchmarks';
  if FRanBenchmarkCount > 0 then
    SaveResults;
  Screen.Cursor := crDefault;
end;

procedure TBenchmarkFrm.actRunSelectedBenchmarkExecute(Sender: TObject);
begin
  Screen.Cursor := crHourglass;

  if lvBenchmarkList.Selected = nil then
    Exit;

  actRunSelectedBenchmark.Caption := 'Running';
  Enabled := False;
  Application.ProcessMessages;
  Enabled := True;

  RunBenchmarks(Benchmarks[NativeInt(lvBenchmarkList.Selected.Data)]);
  if FRanBenchmarkCount > 0 then
    SaveResults;

  actRunSelectedBenchmark.Caption := 'Run Selected Benchmark';
  Enabled := False;
  Application.ProcessMessages;
  Enabled := True;

  Screen.Cursor := crDefault;
end;

procedure TBenchmarkFrm.AddResultsToDisplay(
  const aBenchName, aMMName: String;
  const aCpuUsage: Int64;
  const aTicks, aPeak: Cardinal;
  const CurrentSession: string = 'T';
  const InitialLoad: Boolean = False);
var
  Item: TListItem;
begin
  Inc(FRanBenchmarkCount);

  Item := ListViewResults.Items.Add;
  Item.Caption := aBenchName;
  Item.SubItems.Add(aMMName);
  Item.SubItems.Add(aCpuUsage.ToString);
  Item.SubItems.Add(aTicks.ToString);
  Item.SubItems.Add(aPeak.ToString);
  Item.SubItems.Add(CurrentSession);

//  if not InitialLoad then
//    ListViewResults.AlphaSort;
end;

procedure TBenchmarkFrm.FormClose(Sender: TObject; var AAction: TCloseAction);
begin

  WriteIniFile;

  if FRanBenchmarkCount > 0 then
    SaveResults;
end;

procedure TBenchmarkFrm.FormCreate(Sender: TObject);
var
  i: integer;
  vItem: TListItem;
  vCustomExeName: string;
  vBenchmark: TFastcodeMMBenchmarkClass;
begin
  Caption := Format('%s %s %s for "%s" memory manager', [Caption, {$IFDEF WIN32}'32-bit'{$ELSE}'64-bit'{$ENDIF}, GetFormattedVersion, MemoryManager_Name]);
  Height := 900;
  Width := 1200;

  MemoEnvironment.Lines.Clear;
  MemoEnvironment.Lines.Add(SystemInfoCPU);
  MemoEnvironment.Lines.Add('****************');
  MemoEnvironment.Lines.Add(SystemInfoWindows);

  // make a copy of the application's Exe for later use
  //Skip copy if this is the MM specific exe.
  if not ContainsText(ExtractFileName(Application.ExeName), '_' + MemoryManager_Name + '_') then
  begin
    vCustomExeName := Format('%0:s%2:s\Win%3:s\%1:s_%2:s_%3:s.exe',
      [ExtractFilePath(Application.ExeName), ChangeFileExt(ExtractFileName(Application.ExeName),''),
       MemoryManager_Name, {$IFDEF WIN32}'32'{$ELSE}'64'{$ENDIF}]);
    CopyFile(PChar(GetModuleName(HInstance)), PChar(vCustomExeName), False);
  end else
    vCustomExeName := Application.ExeName;

  FApplicationIniFileName :=
    ReplaceText(ExtractFilePath(vCustomExeName), '\' +MemoryManager_Name + '\Win' + {$IFDEF WIN32}'32'{$ELSE}'64'{$ENDIF}, '') +
    'MemoryManagerTest.ini';

  FTestResultsFileName := Format('%s.csv', [ChangeFileExt(vCustomExeName, '.Results')]);

  FBenchmarkHasBeenRun := False;

  lvBenchmarkList.SortType := stNone; // Do not perform extra sort - already sorted
  {List the benchmarks}
  for i := 0 to Benchmarks.Count - 1 do begin
    vBenchmark := Benchmarks[i];
    vItem := lvBenchmarkList.Items.Add;
    vItem.Data := Pointer(i);
    if Assigned(vBenchmark) then
    begin
      vItem.Checked := vBenchmark.RunByDefault;
      vItem.Caption := vBenchmark.GetBenchmarkName;
      vItem.SubItems.Add(BenchmarkCategoryNames[vBenchmark.GetCategory]);
    end;
  end;

  if lvBenchmarkList.Items.Count > 0 then
  begin
    //Select the first benchmark
    lvBenchmarkList.Items[0].Selected := True;
    lvBenchmarkList.Items[0].Focused  := True;
    //Set the benchmark description.
    lvBenchmarkListSelectItem(nil, lvBenchmarkList.Selected, lvBenchmarkList.Selected <> nil);
  end;

  InitResultsDisplay;

  pcBenchmarkResults.ActivePage := TabSheetBenchmarkResults;

  ReadIniFile;

  tmrAutoRun.Enabled := ParamCount > 0;

end;

procedure TBenchmarkFrm.InitResultsDisplay;
begin
  ListViewResults.Items.BeginUpdate;
  try
    ListViewResults.Items.Clear;
  finally
    ListViewResults.Items.EndUpdate;
  end;

  FRanBenchmarkCount := 0;
  LoadResultsToDisplay;

  ListViewResults.Column[LVCOL_BENCH].Width := 240;
  ListViewResults.Column[LVCOL_MM].Width    := 100;
  ListViewResults.Column[LVCOL_CPUUSAGE].Width := 90;
  ListViewResults.Column[LVCOL_TICKS].Width := 90;
  ListViewResults.Column[LVCOL_MEM].Width   := 120;

end;

procedure TBenchmarkFrm.LoadResultsToDisplay;
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
        Bench.DelimitedText   := CSV[l];
        if Bench.Count < 4 then
          Continue;

        BenchName := Bench[RESULTS_BENCH];
        if Trim(BenchName) = '' then
          Continue;

        MMName    := Bench[RESULTS_MM];
        vCPUUsage := Max(StrToIntDef(Bench[RESULTS_CPUUSAGE], 0), 0);
        vTicks    := Max(StrToIntDef(Bench[RESULTS_TICKS], 0), 0);
        vPeak     := Max(StrToIntDef(Bench[RESULTS_MEM], 0), 0);

        AddResultsToDisplay(BenchName, MMName, vCPUUsage, vTicks, vPeak, 'F');
      end;
    finally
      ListViewResults.Items.EndUpdate;
    end;

    // ListViewResults.AlphaSort;

    if ListViewResults.Items.Count > 0 then
    begin
      ListViewResults.Items[0].Selected := True;
      ListViewResults.Items[0].Focused  := True;
    end;
  finally
    Bench.Free;
    CSV.Free;
  end;
end;

procedure TBenchmarkFrm.lvBenchmarkListSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
var
  LBenchmarkClass: TFastcodeMMBenchmarkClass;

begin
  //Set the benchmark description
  if (Item <> nil) and Selected then
  begin
    LBenchmarkClass := Benchmarks[NativeInt(Item.Data)];
    if Assigned(LBenchmarkClass) then
    begin
      mBenchmarkDescription.Text := LBenchmarkClass.GetBenchmarkDescription;
    end;
  end;
end;

procedure TBenchmarkFrm.ReadIniFile;
var
  vIniFile: TIniFile;
begin
  vIniFile := TIniFile.Create(FApplicationIniFileName);
  try

    Left := vIniFile.ReadInteger('FormSettings', 'Left', Left);
    Top := vIniFile.ReadInteger('FormSettings', 'Top', Top);
    Height := vIniFile.ReadInteger('FormSettings', 'Height', Height);
    Width := vIniFile.ReadInteger('FormSettings', 'Width', Width);

  finally
    vIniFile.Free;
  end;
end;

procedure TBenchmarkFrm.RunBenchmarks(ABenchmarkClass: TFastcodeMMBenchmarkClass);
var
  LBenchmark: TFastcodeMMBenchmark;
  vStartCPUUsage, vCurrentCPUUsage: Int64;
  vStartTicks, vCurrentTicks: Cardinal;
  s: string;
begin
  pcBenchmarkResults.ActivePage := TabSheetProgress;

  s := Trim(Trim(FormatDateTime('HH:nn:ss', time)) + ' Running : ' + ABenchmarkClass.GetBenchmarkName + '...');
  mResults.Lines.Add(s);
  {Create the benchmark}
  LBenchmark := ABenchmarkClass.CreateBenchmark;
  try
    if LBenchmark.CanRunBenchmark then
    begin
      {Do the getmem test}
      vStartCPUUsage := CPU_Usage_Unit.GetCpuUsage_Total;
      vStartTicks := GetTickCount;
      LBenchmark.RunBenchmark;
      vCurrentCPUUsage := CPU_Usage_Unit.GetCpuUsage_Total - vStartCPUUsage;
      vCurrentTicks := GetTickCount - vStartTicks;
      {Add a line}

      mResults.Lines[mResults.Lines.Count - 1] := //Trim(Trim(FormatDateTime('HH:nn:ss', time)) + ' '
        Format('%-45s | CPU Usage(ms) = %6d | Ticks(ms)=%6d | Peak Address Space Usage(Kb) = %7d',
        [ABenchmarkClass.GetBenchmarkName.Trim, vCurrentCPUUsage, vCurrentTicks, LBenchmark.PeakAddressSpaceUsage]);
      Enabled := False;
      Application.ProcessMessages;
      Enabled := True;

      AddResultsToDisplay(ABenchmarkClass.GetBenchmarkName,
                          MemoryManager_Name,
                          vCurrentCPUUsage,
                          vCurrentTicks,
                          LBenchmark.PeakAddressSpaceUsage);
      if not FBenchmarkHasBeenRun then
      begin
        FBenchmarkHasBeenRun := True;
      end;
    end
    else
      begin
        mResults.Lines[mResults.Lines.Count - 1] := Trim(ABenchmarkClass.GetBenchmarkName) + ': Skipped';
        Enabled := False;
        Application.ProcessMessages;
        Enabled := True;
      end;
  finally
    {Free the benchmark}
    LBenchmark.Free;
  end;
end;

procedure TBenchmarkFrm.SaveResults;
var
  CSV, Bench: TStringList;
  i:          Integer;
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

procedure TBenchmarkFrm.tmrAutoRunTimer(Sender: TObject);
begin
  tmrAutoRun.Enabled := False;
  actDeletelTestResults.Execute;
  Application.ProcessMessages;
  actRunAllCheckedBenchmarks.Execute;
  Application.ProcessMessages;
  btnClose.Click;
end;

procedure TBenchmarkFrm.WriteIniFile;
var
  vIniFile: TIniFile;
begin
  vIniFile := TIniFile.Create(FApplicationIniFileName);
  try

    vIniFile.WriteInteger('FormSettings', 'Left', Left);
    vIniFile.WriteInteger('FormSettings', 'Top', Top);
    vIniFile.WriteInteger('FormSettings', 'Height', Height);
    vIniFile.WriteInteger('FormSettings', 'Width', Width);

  finally
    vIniFile.Free;
  end;

end;

end.

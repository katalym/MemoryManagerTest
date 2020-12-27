unit BenchmarkForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, VCL.Graphics, VCL.Controls, VCL.Forms,
  VCL.Dialogs, VCL.StdCtrls, BenchmarkClassUnit, Math, VCL.Buttons,
  VCL.ExtCtrls, VCL.ComCtrls, VCL.Clipbrd, VCL.ToolWin, VCL.ImgList, VCL.Menus, System.ImageList;

type
  TBenchmarkFrm = class(TForm)
    btnClose: TBitBtn;
    btnCopyResultsToClipboard: TToolButton;
    btnDeleteAllTestResults: TToolButton;
    btnDeleteMMTestResults: TToolButton;
    btnRenameMM: TToolButton;
    btnRunAllCheckedBenchmarks: TBitBtn;
    btnRunSelectedBenchmark: TBitBtn;
    gbBenchmarks: TGroupBox;
    ListViewResults: TListView;
    lvBenchmarkList: TListView;
    mBenchmarkDescription: TMemo;
    MemoCPU: TMemo;
    mResults: TMemo;
    mniSep: TMenuItem;
    pcBenchmarkResults: TPageControl;
    pnlButtons: TPanel;
    mniPopupCheckAllDefaultBenchmarks: TMenuItem;
    mniPopupCheckAllThreadedBenchmarks: TMenuItem;
    mniPopupClearAllCheckMarks: TMenuItem;
    mnuBenchmarks: TPopupMenu;
    mniPopupSelectAllCheckMarks: TMenuItem;
    Splitter2: TSplitter;
    TabSheetBenchmarkResults: TTabSheet;
    TabSheetCPU: TTabSheet;
    TabSheetProgress: TTabSheet;
    tmrAutoRun: TTimer;
    ToolBar1: TToolBar;
    imlImages: TImageList;
    procedure btnCopyResultsToClipboardClick(Sender: TObject);
    procedure btnDeleteAllTestResultsClick(Sender: TObject);
    procedure btnDeleteMMTestResultsClick(Sender: TObject);
    procedure btnRenameMMClick(Sender: TObject);
    procedure btnRunAllCheckedBenchmarksClick(Sender: TObject);
    procedure btnRunSelectedBenchmarkClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var AAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure lvBenchmarkListSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
    procedure mniPopupCheckAllDefaultBenchmarksClick(Sender: TObject);
    procedure mniPopupCheckAllThreadedBenchmarksClick(Sender: TObject);
    procedure mniPopupClearAllCheckMarksClick(Sender: TObject);
    procedure mniPopupSelectAllCheckMarksClick(Sender: TObject);
    procedure tmrAutoRunTimer(Sender: TObject);
  private
    FBenchmarkHasBeenRun: Boolean;
    FExtraValidationFailures: string;
    FExtraValidationHasBeenRun: Boolean;
    FRanBenchmarkCount: Integer;
    FValidationFailures: string;
    FValidationHasBeenRun: Boolean;
    FXMLResultList: TStringList;
    procedure AddBenchmark;
    procedure AddResultsToDisplay(
      const aBenchName, aMMName: String;
      const aCpuUsage: Int64;
      const aTicks, aPeak: Cardinal;
      const CurrentSession: string = 'T';
      const InitialLoad: Boolean = False);
    procedure InitResultsDisplay;
    procedure LoadResultsToDisplay;
    procedure LoadXMLResults;
    procedure ReadIniFile;
    {Runs a benchmark and returns its relative speed}
    procedure RunBenchmark(ABenchmarkClass: TFastcodeMMBenchmarkClass);
    procedure SaveResults;
    procedure SaveSummary;
    procedure SaveXMLResults;
    procedure UpdateBenchmark;
    procedure WriteIniFile;
  public
    CSVResultsFileName: string;
  end;

var
  BenchmarkFrm: TBenchmarkFrm;

const
  CSV_RESULT_PREFIX = 'MMTestResults';
  SUMMARY_FILE_PREFIX = 'BVSummary';
  XML_RESULT_BACKUP_FILENAME = 'MMTest_Backup.xml';
  XML_RESULT_FILENAME = 'MMTest.xml';

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

{
PassValidations indicates whether the MM passes all normal validations
FastCodeQualityLabel indicates whether the MM passes the normal AND the extra validations
If you execute a validation run and the results do not match the hardcoded values,
you'll get a message that you should change the source code.
}

implementation

uses
  RenameMMForm, BenchmarkUtilities, GeneralFunctions, SystemInfoUnit, System.IniFiles, Winapi.PsAPI, CPU_Usage_Unit;

{$R *.dfm}

{Disables the window ghosting feature for the calling graphical user interface
 (GUI) process. Window ghosting is a Windows Manager feature that lets the user
 minimize, move, or close the main window of an application that is not
 responding. (This "feature" causes problems with form z-order and also
 modal forms not showing as modal after long periods of non-responsiveness)}
procedure DisableProcessWindowsGhosting;
type
  TDisableProcessWindowsGhostingProc = procedure;
var
  PDisableProcessWindowsGhostingProc: TDisableProcessWindowsGhostingProc;
begin
  PDisableProcessWindowsGhostingProc := GetProcAddress(
    GetModuleHandle('user32.dll'),
    'DisableProcessWindowsGhosting');
  if Assigned(PDisableProcessWindowsGhostingProc) then
    PDisableProcessWindowsGhostingProc;
end;

procedure TBenchmarkFrm.AddBenchmark;
var
  InsertionPoint: Integer;
begin
  InsertionPoint := FXMLResultList.IndexOf('</benchmarks>');
  if InsertionPoint = -1 then
  begin
    InsertionPoint := FXMLResultList.Count - 1;
    FXMLResultList.Insert(InsertionPoint-1, '<benchmarks>');
    FXMLResultList.Insert(InsertionPoint, '</benchmarks>');
  end;

  FXMLResultList.Insert(InsertionPoint,
    Format('<benchmark version="%s" compiler="%s" MM="%s">', [GetFormattedVersion, GetCompilerAbbr, MemoryManager_Name]));
  // FXMLResultList.Insert(InsertionPoint, '<benchmark compiler="' + GetCompilerName + '" MM="' + MemoryManager_Name + '" >');

  // FXMLResultList.Insert(InsertionPoint+1, Format('<cpu>%s</cpu>', [SystemInfoCPU]));
  FXMLResultList.Insert(InsertionPoint+1, {$IFDEF WIN32__}SystemInfoCPUAsXML{$ELSE}''{$ENDIF});
  FXMLResultList.Insert(InsertionPoint+2, Format('<os>%s</os>', [SystemInfoWindows]));
  FXMLResultList.Insert(InsertionPoint+3, '<result> </result>');
  FXMLResultList.Insert(InsertionPoint+4, '</benchmark>');
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

procedure TBenchmarkFrm.btnCopyResultsToClipboardClick(Sender: TObject);
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

procedure TBenchmarkFrm.btnDeleteAllTestResultsClick(Sender: TObject);
begin
//  if (Application.MessageBox('Are you sure you want to delete all results?',
//    'Confirm Results Clear', MB_ICONQUESTION or MB_YesNo or MB_DefButton2) = mrYes) then
  begin
    ListViewResults.Items.BeginUpdate;
    try
      ListViewResults.Items.Clear;
    finally
      ListViewResults.Items.EndUpdate;
    end;
    DeleteFile(CSVResultsFileName);
    FRanBenchmarkCount := 0;
  end;
end;

procedure TBenchmarkFrm.btnDeleteMMTestResultsClick(Sender: TObject);
var
  LMMName: string;
  LInd: integer;
begin
  if ListViewResults.ItemIndex < 0 then
    exit;
  LMMName := ListViewResults.Items[ListViewResults.ItemIndex].SubItems[0];
//  if (Application.MessageBox(PChar('Are you sure you want to delete results for ' + LMMName + '?'),
//    'Confirm Results Delete', MB_ICONQUESTION or MB_YesNo or MB_DefButton2) = mrYes) then
  begin
    for LInd := ListViewResults.Items.Count - 1 downto 0 do
    begin
      if ListViewResults.Items[LInd].SubItems[0] = LMMName then
      begin
        ListViewResults.Items[LInd].Delete;
        Dec(FRanBenchmarkCount);
      end;
    end;
    SaveResults;
  end;
end;

procedure TBenchmarkFrm.btnRenameMMClick(Sender: TObject);
var
  LInd: integer;
  LOldName, LNewName: String;
begin
  if ListViewResults.ItemIndex >= 0 then
  begin
    Application.CreateForm(TRenameFrm, RenameFrm);
    try
      LOldName := ListViewResults.Items[ListViewResults.ItemIndex].SubItems[0];
      RenameFrm.eMMName.Text := LOldName;
      if (RenameFrm.ShowModal = mrOK) and (RenameFrm.eMMName.Text <> '') then
      begin
        LNewName := RenameFrm.eMMName.Text;
        for LInd := 0 to ListViewResults.Items.Count - 1 do
        begin
          if ListViewResults.Items[LInd].SubItems[0] = LOldName then
            ListViewResults.Items[LInd].SubItems[0] := LNewName;
        end;
        SaveResults;
      end;
    finally
      FreeAndNil(RenameFrm);
    end;
  end;
end;

procedure TBenchmarkFrm.btnRunAllCheckedBenchmarksClick(Sender: TObject);
var
  i: integer;
begin
  Screen.Cursor := crHourglass;
  btnRunAllCheckedBenchmarks.Caption := 'Running';
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
      RunBenchmark(Benchmarks[i]);
      {Wait one second}
      Sleep(1000);
    end;
  end;
  mResults.Lines.Add('***All Checked Benchmarks Done***');
  btnRunAllCheckedBenchmarks.Caption := 'Run All Checked Benchmarks';
  if FRanBenchmarkCount > 0 then
    SaveResults;
  SaveSummary;
  Screen.Cursor := crDefault;
end;

procedure TBenchmarkFrm.btnRunSelectedBenchmarkClick(Sender: TObject);
begin
  Screen.Cursor := crHourglass;

  if lvBenchmarkList.Selected = nil then
    Exit;

  btnRunSelectedBenchmark.Caption := 'Running';
  Enabled := False;
  Application.ProcessMessages;
  Enabled := True;

  RunBenchmark(Benchmarks[NativeInt(lvBenchmarkList.Selected.Data)]);
  if FRanBenchmarkCount > 0 then
    SaveResults;

  SaveSummary;

  btnRunSelectedBenchmark.Caption := 'Run Selected Benchmark';
  Enabled := False;
  Application.ProcessMessages;
  Enabled := True;

  Screen.Cursor := crDefault;
end;

procedure TBenchmarkFrm.FormClose(Sender: TObject; var AAction: TCloseAction);
begin

  WriteIniFile;

  if FRanBenchmarkCount > 0 then
    SaveResults;
  FreeAndNil(FXMLResultList);
end;

procedure TBenchmarkFrm.FormCreate(Sender: TObject);

  {$IFDEF WIN32}
  //From FastcodeBenchmarkTool091 - Per Dennis C. Suggestion
  procedure ShowCPUInfo;
  var
   CPUID : TCPUID;
   I : Integer;
  begin
    MemoCPU.Lines.Clear;
    for I := Low(CPUID) to High(CPUID) do CPUID[I] := -1;
      if IsCPUID_Available then
        begin
          CPUID  := GetCPUID;
          MemoCPU.Lines.Add('Processor Type: ' + IntToStr(CPUID[1] shr 12 and 3));
          MemoCPU.Lines.Add('Family:         ' + IntToStr(CPUID[1] shr 8 and $f));
          MemoCPU.Lines.Add('Model:          ' + IntToStr(CPUID[1] shr 4 and $f));
          MemoCPU.Lines.Add('Stepping:       ' + IntToStr(CPUID[1] and $f));
          MemoCPU.Lines.Add('Name:           ' + DetectCPUType(Integer(CPUID[1] shr 8 and $f), Integer(CPUID[1] shr 4 and $f)));
          MemoCPU.Lines.Add('Frequency:      ' + IntToStr(GetCPUFrequencyMHz) + ' MHz');
          MemoCPU.Lines.Add('Vendor:         ' + GetCPUVendor);
        end;
  end;
  {$ENDIF}

var
  i: integer;
  Item: TListItem;
  CopiedExeFileName: string;
  LBenchmark: TFastcodeMMBenchmarkClass;
begin
  Caption := Format('%s %s %s for "%s" memory manager', [Caption, {$IFDEF WIN32}'32-bit'{$ELSE}'64-bit'{$ENDIF}, GetFormattedVersion, MemoryManager_Name]);
  {$IFDEF WIN32}
  ShowCPUInfo;
  {$ENDIF}
  MemoCPU.Lines.Clear;
  MemoCPU.Lines.Add(SystemInfoCPU);
  MemoCPU.Lines.Add('');
  MemoCPU.Lines.Add(SystemInfoWindows);

  //fGraphs := TfGraphs.Create(Self);

//  CSVResultsFileName := Format('%s%s_%s_%s.csv',
//    [ExtractFilePath(GetModuleName(HInstance)), CSV_RESULT_PREFIX, GetCompilerAbbr, MemoryManager_Name]);
  CSVResultsFileName := Format('%s%s_%s.csv',
    [ExtractFilePath(GetModuleName(HInstance)), CSV_RESULT_PREFIX, MemoryManager_Name]);

  FValidationHasBeenRun := False;
  FValidationFailures := '';
  FExtraValidationHasBeenRun := False;
  FExtraValidationFailures := '';
  FBenchmarkHasBeenRun := False;
  FXMLResultList := TStringList.Create;
  LoadXMLResults;

  // make a copy of the application's Exe for later use
  //Skip copy if this is the MM specific exe.
  if Pos('_' + MemoryManager_Name, GetModuleName(HInstance)) = 0 then
  begin
//    CopiedExeFileName := Format('%s_%s_%s.exe',
//      [ChangeFileExt(Application.ExeName, ''), GetCompilerAbbr, MemoryManager_Name]);
    CopiedExeFileName := Format('%s_%s.exe',
      [ChangeFileExt(Application.ExeName, ''), MemoryManager_Name]);
    CopyFile(PChar(GetModuleName(HInstance)), PChar(CopiedExeFileName), False);
  end;

  lvBenchmarkList.SortType := stNone; // already sorted
  {List the benchmarks}
  for i := 0 to Benchmarks.Count - 1 do begin
    LBenchmark := Benchmarks[i];
    Item := lvBenchmarkList.Items.Add;
    Item.Data := Pointer(i);
    if Assigned(LBenchmark) then
    begin
      Item.Checked := LBenchmark.RunByDefault;
      Item.Caption := LBenchmark.GetBenchmarkName;
      Item.SubItems.Add(BenchmarkCategoryNames[LBenchmark.GetCategory]);
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
  if not FileExists(CSVResultsFileName) then
    Exit;

  CSV := TStringList.Create;
  Bench := TStringList.Create;
  try
    Bench.Delimiter := ';';

    CSV.LoadFromFile(CSVResultsFileName);

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

// ----------------------------------------------------------------------------
procedure TBenchmarkFrm.LoadXMLResults;
var
  InsertionPoint: Integer;
begin
  if FileExists(XML_RESULT_FILENAME) then
  begin
    FXMLResultList.LoadFromFile(XML_RESULT_FILENAME);

    InsertionPoint := FXMLResultList.IndexOf('</mmbench>');
    if InsertionPoint = -1 then
    begin
      InsertionPoint := FXMLResultList.Count - 1;
      FXMLResultList.Insert(InsertionPoint, '<mmbench>');
      FXMLResultList.Insert(InsertionPoint+1, '</mmbench>');
    end;
  end
  else
  begin
    FXMLResultList.Add('<mmchallenge>');
    FXMLResultList.Add('<mmbench>');
    FXMLResultList.Add('</mmbench>');
    FXMLResultList.Add('</mmchallenge>');
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

procedure TBenchmarkFrm.mniPopupCheckAllDefaultBenchmarksClick(Sender: TObject);
var
  i: Integer;
begin
  for i := 0 to lvBenchmarkList.Items.Count - 1 do
    lvBenchmarkList.Items[i].Checked := Benchmarks[i].RunByDefault;
end;

procedure TBenchmarkFrm.mniPopupCheckAllThreadedBenchmarksClick(Sender: TObject);
var
  i: Integer;
begin
  for i := 0 to lvBenchmarkList.Items.Count - 1 do
    lvBenchmarkList.Items[i].Checked := Benchmarks[i].IsThreadedSpecial;
end;

procedure TBenchmarkFrm.mniPopupClearAllCheckMarksClick(Sender: TObject);
var
  i: Integer;
begin
  for i := 0 to lvBenchmarkList.Items.Count - 1 do
    lvBenchmarkList.Items[i].Checked := False;
end;

procedure TBenchmarkFrm.mniPopupSelectAllCheckMarksClick(Sender: TObject);
var
  i: Integer;
begin
  for i := 0 to lvBenchmarkList.Items.Count - 1 do
    lvBenchmarkList.Items[i].Checked := True;
end;

procedure TBenchmarkFrm.ReadIniFile;
var
  vIniFile: TIniFile;
begin
  vIniFile := TIniFile.Create(IncludeTrailingPathDelimiter(ExtractFileDir(Application.ExeName)) + 'MemoryManagerTest.ini');
  try

    Left := vIniFile.ReadInteger('FormSettings', 'Left', Left);
    Top := vIniFile.ReadInteger('FormSettings', 'Top', Top);
    Height := vIniFile.ReadInteger('FormSettings', 'Height', Height);
    Width := vIniFile.ReadInteger('FormSettings', 'Width', Width);

  finally
    vIniFile.Free;
  end;
end;

procedure TBenchmarkFrm.RunBenchmark(ABenchmarkClass: TFastcodeMMBenchmarkClass);

//  function _GetProcessMemory: longint;
//  var
//    pmc: PPROCESS_MEMORY_COUNTERS;
//    i: Integer;
//  begin
//    // Get the used memory for the current process
//    i := SizeOf(TProcessMemoryCounters);
//    GetMem(pmc, i);
//    try
//
//      pmc^.cb := i;
//      if GetProcessMemoryInfo(GetCurrentProcess(), pmc, i) then
//        Result:= Longint(pmc^.WorkingSetSize);
//
//    finally
//      FreeMem(pmc);
//    end;
//  end;

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
        AddBenchmark;
        FBenchmarkHasBeenRun := True;
      end;
      UpdateBenchmark;
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

    CSV.SaveToFile(CSVResultsFileName);
  finally
    Bench.Free;
    CSV.Free;
  end;
end;

procedure TBenchmarkFrm.SaveSummary;
var
  FileName: string;
  F: TextFile;
begin
  FileName := Format('%s%s_%s.txt',
    [ExtractFilePath(GetModuleName(HInstance)), SUMMARY_FILE_PREFIX, GetCompilerAbbr]);

  if FileExists(FileName) then
    DeleteFile(FileName);

  AssignFile(F, FileName);
  Rewrite(F);
  try
    Writeln(F, 'Summary report for Memory Manager challenge ' +
      GetFormattedVersion + FormatDateTime('  yyyy-mmm-dd hh:nn:ss', NOW));
    Writeln(F, '');
    Writeln(F, 'Compiler: ' + GetCompilerName);
    Writeln(F, SystemInfoCPU);
    Writeln(F, SystemInfoWindows);
    Writeln(F, '');
    Writeln(F, '');

    Flush(F);
  finally
    CloseFile(F);
  end;
end;

procedure TBenchmarkFrm.SaveXMLResults;
var
  F: TextFile;
  i: Integer;
begin
  if FileExists(XML_RESULT_FILENAME) then
    DeleteFile(XML_RESULT_FILENAME);

  AssignFile(F, XML_RESULT_FILENAME);
  Rewrite(F);
  try
    for i := 0 to FXMLResultList.Count - 1 do
      Writeln(F, FXMLResultList[i]);

    Flush(F);
  finally
    CloseFile(F);
  end;

  // Sometimes forcing an out of memory error causes you to lose the previous
  // results leaving you with an empty file.  This is kind of a backup plan.
  if FileExists(XML_RESULT_BACKUP_FILENAME) then
    DeleteFile(XML_RESULT_BACKUP_FILENAME);
  CopyFile(XML_RESULT_FILENAME, XML_RESULT_BACKUP_FILENAME, False);

//  FXMLResultList.SaveToFile(XML_RESULT_FILENAME);
//  Application.ProcessMessages;
end;

procedure TBenchmarkFrm.tmrAutoRunTimer(Sender: TObject);
begin
  tmrAutoRun.Enabled := False;
  btnDeleteMMTestResults.Click;
  Application.ProcessMessages;
  btnRunAllCheckedBenchmarks.Click;
  Application.ProcessMessages;
  btnClose.Click;
end;

procedure TBenchmarkFrm.UpdateBenchmark;
var
  i: Integer;
  s: string;
  Item: TListItem;
  ResultIndex: Integer;
begin
  ResultIndex := FXMLResultList.IndexOf('</benchmarks>')-1;

  while SameText(Copy(FXMLResultList[ResultIndex-1], 1, 7), '<result') do
  begin
    FXMLResultList.Delete(ResultIndex-1);
    Dec(ResultIndex);
  end;

  for i := ListViewResults.Items.Count -1 downto 0 do
  begin
    Item := ListViewResults.Items[i];
    if SameText('T', Item.SubItems[4]) then
    begin
      s := Format('<result name="%s" time="%s" cpuusage="%s" mem="%s" />',
        [Item.Caption, Item.SubItems[1], Item.SubItems[2], Item.SubItems[3]]);
      FXMLResultList.Insert(ResultIndex, s);
    end;
  end;
  SaveXMLResults;
end;

procedure TBenchmarkFrm.WriteIniFile;
var
  vIniFile: TIniFile;
begin
  vIniFile := TIniFile.Create(IncludeTrailingPathDelimiter(ExtractFileDir(Application.ExeName)) + 'MemoryManagerTest.ini');
  try

    vIniFile.WriteInteger('FormSettings', 'Left', Left);
    vIniFile.WriteInteger('FormSettings', 'Top', Top);
    vIniFile.WriteInteger('FormSettings', 'Height', Height);
    vIniFile.WriteInteger('FormSettings', 'Width', Width);

  finally
    vIniFile.Free;
  end;

end;

//initialization
//  {We want the main form repainted while it's busy running}
//  DisableProcessWindowsGhosting;

end.

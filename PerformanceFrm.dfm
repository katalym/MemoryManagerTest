object PerformanceForm: TPerformanceForm
  Left = 179
  Top = 89
  BorderWidth = 4
  Caption = 'Compare performace for Memory Managers'#39' tests'
  ClientHeight = 574
  ClientWidth = 1184
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnActivate = FormActivate
  OnDestroy = FormDestroy
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Splitter2: TSplitter
    Left = 0
    Top = 571
    Width = 1184
    Height = 3
    Cursor = crVSplit
    Align = alBottom
  end
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 1184
    Height = 571
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 0
    object pnlUsage: TPanel
      Left = 0
      Top = 540
      Width = 1184
      Height = 31
      Align = alBottom
      BevelOuter = bvNone
      Color = clBtnShadow
      ParentBackground = False
      TabOrder = 1
      object lblUsageReplay: TLabel
        AlignWithMargins = True
        Left = 374
        Top = 9
        Width = 119
        Height = 13
        Margins.Top = 9
        Margins.Bottom = 9
        Align = alLeft
        Caption = 'Usage Log file to Replay:'
      end
      object btnReloadResults: TBitBtn
        AlignWithMargins = True
        Left = 3
        Top = 3
        Width = 134
        Height = 25
        Action = actReloadResults
        Align = alLeft
        Caption = 'Reload Results'
        TabOrder = 0
      end
      object btnRunSelectedBenchmark: TBitBtn
        AlignWithMargins = True
        Left = 148
        Top = 3
        Width = 220
        Height = 25
        Margins.Left = 8
        Action = actCompareToThisResult
        Align = alLeft
        Caption = 'Compare To ->'
        TabOrder = 1
      end
      object edtUsageReplay: TEdit
        AlignWithMargins = True
        Left = 499
        Top = 6
        Width = 681
        Height = 21
        Margins.Top = 6
        Margins.Right = 4
        Margins.Bottom = 4
        Align = alClient
        TabOrder = 2
        Text = 'C:\MemoryManagerUsageLogs\MMUsage.Log'
      end
    end
    object pnlResults: TGridPanel
      Left = 0
      Top = 0
      Width = 1184
      Height = 161
      Align = alTop
      BevelOuter = bvNone
      ColumnCollection = <
        item
          Value = 50.000000000000000000
        end
        item
          SizeStyle = ssAuto
        end
        item
          Value = 50.000000000000000000
        end>
      ControlCollection = <
        item
          Column = 0
          Control = lstAvailableResults
          Row = 0
        end
        item
          Column = 1
          Control = pnlListActions
          Row = 0
        end
        item
          Column = 2
          Control = lstCompareResults
          Row = 0
        end>
      RowCollection = <
        item
          Value = 100.000000000000000000
        end>
      TabOrder = 0
      object lstAvailableResults: TListBox
        Left = 0
        Top = 0
        Width = 544
        Height = 161
        Align = alClient
        ItemHeight = 13
        Sorted = True
        TabOrder = 0
      end
      object pnlListActions: TPanel
        Left = 544
        Top = 0
        Width = 95
        Height = 161
        Align = alLeft
        BevelOuter = bvNone
        TabOrder = 1
        object btnMoveToRight: TBitBtn
          AlignWithMargins = True
          Left = 3
          Top = 8
          Width = 89
          Height = 25
          Margins.Top = 8
          Margins.Bottom = 8
          Action = actIncludeIntoComparison
          Align = alTop
          Caption = '>> Include >>'
          TabOrder = 0
        end
        object BitBtn1: TBitBtn
          AlignWithMargins = True
          Left = 3
          Top = 49
          Width = 89
          Height = 25
          Margins.Top = 8
          Margins.Bottom = 8
          Action = actExcludeFromComparison
          Align = alTop
          Caption = '<< Exclude <<'
          TabOrder = 1
        end
        object BitBtn2: TBitBtn
          AlignWithMargins = True
          Left = 3
          Top = 128
          Width = 89
          Height = 25
          Margins.Top = 8
          Margins.Bottom = 8
          Action = actCompareToThisResult
          Align = alBottom
          Caption = 'Compare To ->'
          TabOrder = 2
        end
      end
      object lstCompareResults: TListBox
        Left = 639
        Top = 0
        Width = 545
        Height = 161
        Align = alClient
        ItemHeight = 13
        Sorted = True
        TabOrder = 2
      end
    end
    object Panel1: TPanel
      Left = 0
      Top = 161
      Width = 1184
      Height = 379
      Align = alClient
      BevelOuter = bvNone
      TabOrder = 2
      object pnlCompareToThisResult: TPanel
        Left = 0
        Top = 0
        Width = 1184
        Height = 21
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 0
        object lblCompareToThisResult: TLabel
          AlignWithMargins = True
          Left = 3
          Top = 4
          Width = 1178
          Height = 13
          Margins.Top = 4
          Margins.Bottom = 4
          Align = alClient
          Alignment = taCenter
          Caption = ' is used as for comparison'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'MS Sans Serif'
          Font.Style = []
          ParentFont = False
        end
      end
      object lstBenchmarks: TListBox
        Left = 0
        Top = 21
        Width = 449
        Height = 358
        Align = alLeft
        ItemHeight = 13
        Sorted = True
        TabOrder = 1
      end
    end
  end
  object mnuBenchmarks: TPopupMenu
    Left = 100
    Top = 76
    object mniPopupClearAllCheckMarks: TMenuItem
      Caption = 'Clear All Check Marks'
      Hint = 'Clear All Check Marks'
      ImageIndex = 6
    end
    object mniPopupSelectAllCheckMarks: TMenuItem
      Caption = 'Check All Benchmarks'
      Hint = 'Check All Benchmarks'
      ImageIndex = 4
    end
    object mniSep: TMenuItem
      Caption = '-'
    end
    object mniPopupCheckAllDefaultBenchmarks: TMenuItem
      Caption = 'Check All Default Benchmarks'
      Hint = 'Check All Default Benchmarks'
      ImageIndex = 4
    end
    object mniPopupCheckAllThreadedBenchmarks: TMenuItem
      Caption = 'Check Special Thread Benchmarks'
      Hint = 'Check Special Thread Benchmarks'
    end
  end
  object alActions: TActionList
    Left = 240
    Top = 80
    object actReloadResults: TAction
      Category = 'Actions'
      Caption = 'Reload Results'
      Hint = 'Reload Results'
      ImageIndex = 4
      OnExecute = actReloadResultsExecute
    end
    object actCompareToThisResult: TAction
      Category = 'Actions'
      Caption = 'Compare To ->'
      Hint = 'Compare To This Result'
      ImageIndex = 5
      OnExecute = actCompareToThisResultExecute
      OnUpdate = actCompareToThisResultUpdate
    end
    object actIncludeIntoComparison: TAction
      Category = 'Actions'
      Caption = '>> Include >>'
      Hint = 'Include into Comparison List'
      OnExecute = actIncludeIntoComparisonExecute
      OnUpdate = actIncludeIntoComparisonUpdate
    end
    object actExcludeFromComparison: TAction
      Category = 'Actions'
      Caption = '<< Exclude <<'
      Hint = 'Exclude from Comparison List'
      OnExecute = actExcludeFromComparisonExecute
      OnUpdate = actExcludeFromComparisonUpdate
    end
  end
end

object PerformanceForm: TPerformanceForm
  Left = 179
  Top = 89
  BorderWidth = 4
  Caption = 'Compare Performance for Memory Managers'#39' tests'
  ClientHeight = 573
  ClientWidth = 1180
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  Position = poScreenCenter
  OnActivate = FormActivate
  OnDestroy = FormDestroy
  OnShow = FormShow
  TextHeight = 13
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 1180
    Height = 573
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 0
    object pnlUsage: TPanel
      Left = 0
      Top = 542
      Width = 1180
      Height = 31
      Align = alBottom
      BevelOuter = bvNone
      Color = clBtnShadow
      ParentBackground = False
      TabOrder = 1
      object lblComparisonFileName: TLabel
        AlignWithMargins = True
        Left = 295
        Top = 9
        Width = 95
        Height = 13
        Margins.Top = 9
        Margins.Bottom = 9
        Align = alLeft
        Caption = 'to file in CSV format:'
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
      object btnSaveComparionResults: TBitBtn
        AlignWithMargins = True
        Left = 148
        Top = 3
        Width = 141
        Height = 25
        Margins.Left = 8
        Action = actSaveComparionResults
        Align = alLeft
        Caption = 'Save Comparion Results'
        TabOrder = 1
      end
      object edtComparisonFileName: TEdit
        AlignWithMargins = True
        Left = 396
        Top = 6
        Width = 780
        Height = 21
        Margins.Top = 6
        Margins.Right = 4
        Margins.Bottom = 4
        Align = alClient
        TabOrder = 2
        Text = 'comparison.csv'
      end
    end
    object pnlResults: TGridPanel
      Left = 0
      Top = 0
      Width = 1180
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
        Width = 542
        Height = 161
        Align = alClient
        ItemHeight = 13
        Sorted = True
        TabOrder = 0
      end
      object pnlListActions: TPanel
        Left = 542
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
        Left = 637
        Top = 0
        Width = 543
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
      Width = 1180
      Height = 381
      Align = alClient
      BevelOuter = bvNone
      TabOrder = 2
      object pnlCompareToThisResult: TPanel
        Left = 0
        Top = 0
        Width = 1180
        Height = 21
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 0
        object lblCompareToThisResult: TLabel
          AlignWithMargins = True
          Left = 3
          Top = 4
          Width = 1174
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
      object lstMemTests: TDBGrid
        Left = 0
        Top = 21
        Width = 1180
        Height = 360
        Align = alClient
        DataSource = dscCompareTo
        TabOrder = 1
        TitleFont.Charset = DEFAULT_CHARSET
        TitleFont.Color = clWindowText
        TitleFont.Height = -11
        TitleFont.Name = 'MS Sans Serif'
        TitleFont.Style = []
      end
    end
  end
  object mnuMemTests: TPopupMenu
    Left = 100
    Top = 76
    object mniPopupClearAllCheckMarks: TMenuItem
      Caption = 'Clear All Check Marks'
      Hint = 'Clear All Check Marks'
      ImageIndex = 6
    end
    object mniPopupSelectAllCheckMarks: TMenuItem
      Caption = 'Check All MemTests'
      Hint = 'Check All MemTests'
      ImageIndex = 4
    end
    object mniSep: TMenuItem
      Caption = '-'
    end
    object mniPopupCheckAllDefaultMemTests: TMenuItem
      Caption = 'Check All Default MemTests'
      Hint = 'Check All Default MemTests'
      ImageIndex = 4
    end
    object mniPopupCheckAllThreadedMemTests: TMenuItem
      Caption = 'Check Special Thread MemTests'
      Hint = 'Check Special Thread MemTests'
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
    object actSaveComparionResults: TAction
      Category = 'Actions'
      Caption = 'Save Comparion Results'
      OnExecute = actSaveComparionResultsExecute
      OnUpdate = actSaveComparionResultsUpdate
    end
  end
  object cdsCompareTo: TClientDataSet
    Aggregates = <>
    Params = <>
    Left = 592
    Top = 296
  end
  object dscCompareTo: TDataSource
    DataSet = cdsCompareTo
    Left = 592
    Top = 360
  end
end

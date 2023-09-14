object MemoryStatusExForm: TMemoryStatusExForm
  Left = 0
  Top = 0
  Caption = 'Form8'
  ClientHeight = 714
  ClientWidth = 1108
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  TextHeight = 17
  object Memo1: TMemo
    Left = 0
    Top = 41
    Width = 1108
    Height = 673
    Align = alClient
    TabOrder = 0
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 1108
    Height = 41
    Align = alTop
    TabOrder = 1
    object btnRefreshStatus: TBitBtn
      Left = 16
      Top = 10
      Width = 145
      Height = 25
      Caption = 'Refresh Status'
      TabOrder = 0
      OnClick = btnRefreshStatusClick
    end
  end
end

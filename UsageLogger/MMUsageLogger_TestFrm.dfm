object MMUsageLogger_TestForm: TMMUsageLogger_TestForm
  Left = 0
  Top = 0
  Caption = 'FastMM5 Test Form'
  ClientHeight = 142
  ClientWidth = 420
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OnCreate = FormCreate
  DesignSize = (
    420
    142)
  TextHeight = 13
  object Label1: TLabel
    Left = 16
    Top = 56
    Width = 183
    Height = 13
    Caption = 'Memory Manager Operation stored in:'
  end
  object Button2: TButton
    Left = 16
    Top = 16
    Width = 281
    Height = 25
    Caption = 'Run memory operations to create usage file'
    TabOrder = 0
    OnClick = Button2Click
  end
  object Edit1: TEdit
    Left = 16
    Top = 75
    Width = 381
    Height = 21
    Anchors = [akLeft, akTop, akRight]
    ReadOnly = True
    TabOrder = 1
    Text = 'Edit1'
  end
end

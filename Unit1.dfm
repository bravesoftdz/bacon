object FmMain: TFmMain
  Left = 206
  Top = 158
  Width = 401
  Height = 293
  Caption = 'Bacon QA '
  Color = clBtnFace
  Font.Charset = ANSI_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  Menu = MainMenu
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object Splitter1: TSplitter
    Left = 0
    Top = 81
    Width = 393
    Height = 3
    Cursor = crVSplit
    Align = alTop
  end
  object MemTest: TMemo
    Left = 0
    Top = 84
    Width = 393
    Height = 163
    Align = alClient
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Courier New'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
  end
  object BtnRun: TButton
    Left = 280
    Top = 200
    Width = 75
    Height = 25
    Caption = 'Run'
    TabOrder = 1
    OnClick = BtnRunClick
  end
  object LstExamples: TRxCheckListBox
    Left = 0
    Top = 0
    Width = 393
    Height = 81
    Align = alTop
    ItemHeight = 13
    TabOrder = 2
    InternalVersion = 202
  end
  object MainMenu: TMainMenu
    Left = 280
    Top = 64
    object File1: TMenuItem
      Caption = '&File'
    end
    object Bacon1: TMenuItem
      Caption = '&Bacon'
      object Run1: TMenuItem
        Caption = '&Run'
        ShortCut = 119
        OnClick = Run1Click
      end
    end
  end
end

object FmMain: TFmMain
  Left = 206
  Top = 158
  Width = 401
  Height = 293
  ActiveControl = LstExamples
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
  object LstExamples: TRxCheckListBox
    Left = 0
    Top = 0
    Width = 393
    Height = 81
    Align = alTop
    ItemHeight = 13
    PopupMenu = MnuLstExamples
    Sorted = True
    TabOrder = 0
    OnDblClick = LstExamplesDblClick
    InternalVersion = 202
  end
  object LstResults: TListView
    Left = 0
    Top = 84
    Width = 393
    Height = 163
    Align = alClient
    Columns = <
      item
        AutoSize = True
        Caption = 'Programma'
      end
      item
        Caption = 'Esito'
      end>
    ReadOnly = True
    TabOrder = 1
    ViewStyle = vsReport
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
        OnClick = AcRunTestExecute
      end
    end
  end
  object MnuLstExamples: TPopupMenu
    Left = 184
    Top = 40
    object mniSelectall: TMenuItem
      Action = AcSelectAll
    end
    object mniDeselectall: TMenuItem
      Action = AcDeselectAll
    end
  end
  object ActionList: TActionList
    Left = 48
    Top = 32
    object AcRunTest: TAction
      Caption = '&Run test'
      ShortCut = 119
      OnExecute = AcRunTestExecute
    end
    object AcSelectAll: TAction
      Category = 'Examples list'
      Caption = '&Select all'
      ShortCut = 16449
      OnExecute = AcSelectAllExecute
    end
    object Action2: TAction
      Caption = 'Action2'
    end
    object AcDeselectAll: TAction
      Category = 'Examples list'
      Caption = '&Deselect all'
      ShortCut = 16452
      OnExecute = AcDeselectAllExecute
    end
  end
end

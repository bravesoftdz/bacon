object FmMain: TFmMain
  Left = 206
  Top = 161
  Width = 696
  Height = 480
  Caption = 'Bacon Runner'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  Menu = MainMenu
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object MemProgram: TRichEdit
    Left = 0
    Top = 0
    Width = 688
    Height = 434
    Align = alClient
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Courier New'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
    OnChange = MemProgramChange
  end
  object MainMenu: TMainMenu
    Left = 112
    Top = 32
    object File1: TMenuItem
      Caption = '&File'
    end
    object Bacon1: TMenuItem
      Caption = '&Bacon'
      object Run1: TMenuItem
        Action = AcRun
      end
    end
    object N1: TMenuItem
      Caption = '&?'
      object About1: TMenuItem
        Action = AcAbout
      end
    end
  end
  object ActionList: TActionList
    Left = 48
    Top = 32
    object AcRun: TAction
      Caption = '&Run'
      ShortCut = 119
      OnExecute = AcRunExecute
    end
    object AcSelectAll: TAction
      Category = 'Examples list'
      Caption = '&Select all'
      ShortCut = 16449
    end
    object AcAbout: TAction
      Caption = '&About'
      OnExecute = AcAboutExecute
    end
    object AcDeselectAll: TAction
      Category = 'Examples list'
      Caption = '&Deselect all'
      ShortCut = 16452
    end
  end
end

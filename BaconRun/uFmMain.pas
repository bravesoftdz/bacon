unit uFmMain;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ActnList, Menus, StdCtrls, ComCtrls;

type
  TFmMain = class(TForm)
    MainMenu: TMainMenu;
    File1: TMenuItem;
    Bacon1: TMenuItem;
    Run1: TMenuItem;
    ActionList: TActionList;
    AcRun: TAction;
    AcSelectAll: TAction;
    AcAbout: TAction;
    AcDeselectAll: TAction;
    MemProgram: TRichEdit;
    N1: TMenuItem;
    About1: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure AcAboutExecute(Sender: TObject);
    procedure AcRunExecute(Sender: TObject);
    procedure MemProgramChange(Sender: TObject);
  private
    procedure RegisterAssociation;
    procedure LoadProgram(const ProgramFile : string);
  public
    { Public declarations }
  end;

var
  FmMain: TFmMain;

implementation

uses
  RegAppApi, uBacon, uBStandardTypes,
  uFmAbout, uBaconGL;

var
  Test : TBacon;
  
{$R *.DFM}

procedure TFmMain.FormCreate(Sender: TObject);
begin
  RegisterAssociation;
  Test := TBacon.Create(Self);
  Test.RegisterType(TBVoid);
  Test.RegisterType(TBNumber);
  Test.RegisterType(TBString);
  Test.RegisterType(TBDate);
  Test.RegisterType(TBGLFrame);  
end;

procedure TFmMain.RegisterAssociation;
var
  ProgAssoc : string;
begin
  ProgAssoc := GetProgramAssociation(_BACON_EXT);
  if (ProgAssoc = '') or (ProgAssoc <> Application.ExeName) then
    SetProgramAssociation('.'+_BACON_EXT, Application.ExeName);
end;

procedure TFmMain.FormDestroy(Sender: TObject);
begin
  Test.Free;
end;

procedure TFmMain.LoadProgram(const ProgramFile: string);
begin
  MemProgram.Lines.LoadFromFile(ProgramFile);
  Caption := Application.Title + ' - ' + ProgramFile;
end;

procedure TFmMain.FormShow(Sender: TObject);
begin
  if ParamCount > 0 then
    LoadProgram(ParamStr(1));
end;

procedure TFmMain.AcAboutExecute(Sender: TObject);
begin
  with TFmAbout.Create(Self) do
  try
    ShowModal;
  finally
    Free;
  end;
end;

procedure TFmMain.AcRunExecute(Sender: TObject);
begin
  Test.Code.Assign(MemProgram.Lines);
  Test.Run;
end;

procedure TFmMain.MemProgramChange(Sender: TObject);
begin
  Test.Parsed := False;
end;

end.

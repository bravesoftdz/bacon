unit uFmMain;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  uBacon, StdCtrls, Menus, RXCtrls, ExtCtrls, ActnList, ComCtrls,
  ShellApi;

type                                            
  TTestPath = class
  public
    TestPath : string;
  end;

  TFmMain = class(TForm)
    MainMenu: TMainMenu;
    File1: TMenuItem;
    Bacon1: TMenuItem;
    Run1: TMenuItem;
    LstExamples: TRxCheckListBox;
    Splitter1: TSplitter;
    MnuLstExamples: TPopupMenu;
    mniSelectall: TMenuItem;
    mniDeselectall: TMenuItem;
    ActionList: TActionList;
    AcRunTest: TAction;
    AcSelectAll: TAction;
    Action2: TAction;
    AcDeselectAll: TAction;
    LstResults: TListView;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure AcRunTestExecute(Sender: TObject);
    procedure AcDeselectAllExecute(Sender: TObject);
    procedure AcSelectAllExecute(Sender: TObject);
    procedure LstExamplesDblClick(Sender: TObject);
  private
    procedure LoadExamples(const Path : string);
    procedure DoSelectAll(const Select : boolean);
    procedure RunTest;
  public
    { Public declarations }
  end;

var
  FmMain: TFmMain;
  Test : TBacon;

implementation

uses
  uBStandardTypes;

const
  cTestDir = 'test\';
    
{$R *.DFM}

procedure TFmMain.FormCreate(Sender: TObject);
begin
  Test := TBacon.Create(Self);
  Test.RegisterType(TBVoid);
  Test.RegisterType(TBNumber);
  Test.RegisterType(TBString);
  Test.RegisterType(TBDate);
  LoadExamples(cTestDir);
end;

procedure TFmMain.FormDestroy(Sender: TObject);
begin
  Test.Free;
end;

procedure TFmMain.LoadExamples(const Path: string);
var
  Sr : TSearchRec;
  FileAttrs : integer;
  TestPath : TTestPath;
begin
  FileAttrs := 0;
  if FindFirst(Path+'*.'+_BACON_EXT, FileAttrs, Sr) = 0 then
  begin
    Test.LoadProgramFile(Path+Sr.Name);
    TestPath := TTestPath.Create;
    TestPath.TestPath := Sr.Name;
    LstExamples.Items.AddObject(Test.Title + '-'+ Test.Comment, TestPath);
    while FindNext(Sr) = 0 do
    begin
      Test.LoadProgramFile(Path+Sr.Name);
      TestPath := TTestPath.Create;
      TestPath.TestPath := Sr.Name;
      LstExamples.Items.AddObject(Test.Title + '-'+ Test.Comment, TestPath);
    end;
    FindClose(Sr);
  end;
end;

procedure TFmMain.AcRunTestExecute(Sender: TObject);
begin
  RunTest;
end;

procedure TFmMain.RunTest;
var
  i : integer;
  Temp : string;
  CurrTest : TListItem;
begin
  LstResults.Items.Clear;
  for i:=0 to LstExamples.Items.Count-1 do
  begin
    with LstExamples do
      if Checked[i] then
      begin
        CurrTest := LstResults.Items.Add;
        CurrTest.Caption := Items[i];
        Temp := TTestPath(LstExamples.Items.Objects[i]).TestPath;
        Test.LoadProgramFile('test\'+Temp);
        Test.Run;
        if Test.EvalTestCondition then
        begin
          CurrTest.SubItems.Add('Ok');
        end
        else
        begin
          CurrTest.SubItems.Add('Failed');
        end;
      end;
  end;
end;

procedure TFmMain.AcDeselectAllExecute(Sender: TObject);
begin
  DoSelectAll(False);
end;

procedure TFmMain.DoSelectAll(const Select: boolean);
var
  i : integer;
begin
  for i:=0 to LstExamples.Items.Count-1 do
    LstExamples.Checked[i] := Select;
end;

procedure TFmMain.AcSelectAllExecute(Sender: TObject);
begin
  DoSelectAll(True);
end;

procedure TFmMain.LstExamplesDblClick(Sender: TObject);
var
  Temp : integer;
  TempString : string;
begin
  Temp := LstExamples.ItemIndex;
  TempString := TTestPath(LstExamples.Items.Objects[Temp]).TestPath;
  ShellExecute(Handle,
    'open',
    PChar(cTestDir+TempString),
    nil,
    PChar(ExtractFilePath(ParamStr(0))),
    SW_SHOWNORMAL);
end;

end.

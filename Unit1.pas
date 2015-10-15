unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  uBacon, StdCtrls, Menus, RXCtrls, ExtCtrls;

type
  TFmMain = class(TForm)
    MemTest: TMemo;
    BtnRun: TButton;
    MainMenu: TMainMenu;
    File1: TMenuItem;
    Bacon1: TMenuItem;
    Run1: TMenuItem;
    LstExamples: TRxCheckListBox;
    Splitter1: TSplitter;
    procedure FormCreate(Sender: TObject);
    procedure BtnRunClick(Sender: TObject);
    procedure Run1Click(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FSlTest : TStringList;
    procedure LoadExamples(const Path : string);
    procedure DoTest1;
    procedure DoTest2;
    procedure DoTest3;
  public
    { Public declarations }
  end;

var
  FmMain: TFmMain;
  Test : TBacon;

implementation

uses
  uBStandardTypes;

{$R *.DFM}

procedure TFmMain.FormCreate(Sender: TObject);
begin
  Test := TBacon.Create(Self);
  Test.RegisterType(TBVoid);
  Test.RegisterType(TBNumber);
  Test.RegisterType(TBString);
  Test.RegisterType(TBDate);
  FSlTest := TStringList.Create;
  LoadExamples('test\');
end;

procedure TFmMain.FormDestroy(Sender: TObject);
begin
  FSlTest.Free;
  Test.Free;
end;


procedure TFmMain.BtnRunClick(Sender: TObject);
begin
  MemTest.Clear;
  DoTest1;
//  DoTest2;
//  DoTest3;
end;

procedure TFmMain.Run1Click(Sender: TObject);
begin
  BtnRunClick(Sender);
end;

procedure TFmMain.DoTest1;
var
  A, A1 : double;
  TestOk : boolean;
begin
// Test #1
  Test.LoadProgramFile('test\test1.bac');
  Test.Run;
  A := Test.GetValue('A');
  A1 := Test.GetValue('A1');
  TestOk := (A = 2.5) and (A = A1);
  if TestOk then
    MemTest.Lines.Add('Test #1 : ok')
  else
    MemTest.Lines.Add('Test #1 : failed')
end;

procedure TFmMain.DoTest2;
var
  A, A1 : double;
  TestOk : boolean;
begin
  Test.LoadProgramFile('test\test2.bac');
  Test.Run;
  A := Test.GetValue('A');
  A1 := Test.GetValue('A1');
  TestOk := (A1 = 2.5) and (A = 2 + 3.5);
  if TestOk then
    MemTest.Lines.Add('Test #2 : ok')
  else
    MemTest.Lines.Add('Test #2 : failed')
end;

procedure TFmMain.DoTest3;
var
  A, A1 : double;
  TestOk : boolean;
begin
  Test.LoadProgramFile('test\test3.bac');
  Test.Run;
  A := Test.GetValue('A');
  A1 := Test.GetValue('A1');
  TestOk := (A1 = 15) and (A = 15 + 3.5);
  if TestOk then
    MemTest.Lines.Add('Test #3 : ok')
  else
    MemTest.Lines.Add('Test #3 : failed')
end;

procedure TFmMain.LoadExamples(const Path: string);
var
  Sr : TSearchRec;
  FileAttrs : integer;
begin
  FileAttrs := 0;
  if FindFirst(Path+'*.'+_BACON_EXT, FileAttrs, Sr) = 0 then
  begin
    Test.LoadProgramFile(Path+Sr.Name);
    LstExamples.Items.AddObject(Test.Comment, TObject(Sr.Name));
    while FindNext(Sr) = 0 do
    begin
      Test.LoadProgramFile(Path+Sr.Name);
      LstExamples.Items.AddObject(Test.Comment, TObject(Sr.Name));
    end;
    FindClose(Sr);
  end;
end;

end.

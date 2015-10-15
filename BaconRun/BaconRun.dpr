program BaconRun;

uses
  Forms,
  uFmMain in 'uFmMain.pas' {FmMain},
  uFmAbout in 'uFmAbout.pas' {FmAbout},
  uFmSplash in 'uFmSplash.pas' {FmSplash};

{$R *.RES}

var
  i : longint;
begin
  Application.Initialize;
  Application.Title := 'Bacon Runner';
  FmSplash := TFmSplash.Create(Application);
  FmSplash.Show;
  FmSplash.Update;
  Application.CreateForm(TFmMain, FmMain);
  for i:=0 to 100000000 do ;
  FmSplash.Hide;
  FmSplash.Free;
  Application.Run;
end.

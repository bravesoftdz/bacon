program BaconQA;

uses
  Forms,
  uFmMain in 'uFmMain.pas' {FmMain};

{$R *.RES}

begin
  Application.Initialize;
  Application.Title := 'Bacon QA';
  Application.CreateForm(TFmMain, FmMain);
  Application.Run;
end.
